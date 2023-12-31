// SPDX-License-Identifier: MIT

/*

FUUUUUUUUUUUUUUUUUUUUUUUUUCK BANANA GUN BOT

Twitter: https://twitter.com/fuckbananabot
Telegram: https://t.me/fuckbananabot
Website: https://www.fuckbanana.xyz/

*/

pragma solidity ^0.8.9;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FuckBananaGunBot is ERC20, Ownable {
    string private _name = "Fuck Banana";
    string private _symbol = "FUCKBANANA";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1000000 * 10 ** _decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isWalletLimitExempt;

    uint256 public FeeBuy = 3;
    uint256 public FeeSell = 3;
    address public feesRecipient;

    IUniswapV2Router02 router;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply / 1000) * 1; // 0.1%
    uint256 public _maxWalletSize = (_totalSupply * 3) / 100; // 3%

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _feesRecipient) Ownable() {
        router = IUniswapV2Router02(routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;
        feesRecipient = _feesRecipient;
        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[feesRecipient] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[routerAddress] = true;

        _balances[feesRecipient] = (_totalSupply * 3) / 100;
        _balances[msg.sender] = (_totalSupply * 97) / 100;

        emit Transfer(address(0), msg.sender, (_totalSupply * 97) / 100);
        emit Transfer(address(0), feesRecipient, (_totalSupply * 3) / 100);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (sender != owner() && recipient != owner()) {
            if (recipient != pair) {
                require(
                    isWalletLimitExempt[recipient] ||
                        (_balances[recipient] + amount <= _maxWalletSize),
                    "wallet limit exceeded"
                );
            }
        }

        if (shouldSwapBack() && recipient == pair) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - amount;
        uint256 amountReceived = (isWalletLimitExempt[sender] &&
            isWalletLimitExempt[recipient])
            ? amount
            : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);
        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = 0;

        if (sender == pair && recipient != pair) {
            feeAmount = (amount * FeeBuy) / 100;
        }
        if (sender != pair && recipient == pair) {
            feeAmount = (amount * FeeSell) / 100;
        }

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }
        return amount - (feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function setFees(uint256 _FeeBuy, uint256 _FeeSell) external onlyOwner {
        require(_FeeBuy <= 30 && _FeeSell <= 30, "fee too high");
        FeeBuy = _FeeBuy;
        FeeSell = _FeeSell;
    }

    function removeLimits() external onlyOwner {
        _maxWalletSize = _totalSupply;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp + 5 minutes
        );

        uint256 amountETH = address(this).balance;

        if (amountETH > 0) {
            bool tmpSuccess;
            (tmpSuccess, ) = payable(feesRecipient).call{value: amountETH}("");
        }
    }

    function removeStuckETH() external {
        require(msg.sender == feesRecipient, "!feesRecipient");
        uint256 amountETH = address(this).balance;
        if (amountETH > 0) {
            bool tmpSuccess;
            (tmpSuccess, ) = payable(feesRecipient).call{value: amountETH}("");
            require(tmpSuccess, "transfer failed");
        }
    }
}
