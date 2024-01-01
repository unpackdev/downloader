
// TG: https://t.me/thenewroadportal
// Twitter: https://twitter.com/TheNewRoad_

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract TNR is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _buyerMap;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) internal _isAdmin;
    mapping(address => bool) private _isBot;

    address payable private _taxWallet;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _initialBuyTax = 50;
    uint256 private _initialSellTax = 99;
    uint256 public _finalTax = 5;

    uint256 private _blockAtLaunch;
    uint256 private _blockRemoveLimits = 10;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 50_000_000 * 10 ** _decimals;
    string private constant _name = unicode"The New Road";
    string private constant _symbol = unicode"TNR";
    uint256 public _maxWalletSize = (_tTotal * 50) / 10000; // 0.5% of total supply
    uint256 public _maxLittleWalletSize = (_tTotal * 20) / 10000; // 0.2% of total supply
    uint256 private swapThreshold = (_tTotal * 100) / 10000; // 1% of total supply

    IUniswapV2Router02 private router;
    address public pair;
    bool public tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address[] memory addresses) {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _isAdmin[addresses[i]] = true;
        }
        _isAdmin[owner()] = true;

        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Launch limits functions

    /** @dev Remove wallet cap.
     * @notice Can only be called by the current owner.
     */
    function removeLimits() external onlyOwner {
        _maxWalletSize = _tTotal;
    }

    /** @dev Enable trading.
     * @notice Can only be called by the current owner.
     * @notice Can only be called once.
     */
    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        swapEnabled = true;
        tradingOpen = true;
        _blockAtLaunch = block.number;
    }

    function manageBot(address account, bool a) external onlyOwner {
        _isBot[account] = a;
    }

    // Transfer functions

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(!_isBot[msg.sender], "You are a bot");
        if (msg.sender == pair) {
            return _transferFrom(msg.sender, recipient, amount);
        } else {
            return _basicTransfer(msg.sender, recipient, amount);
        }
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(!_isBot[msg.sender], "You are a bot");
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _transferFrom(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            _isExcludedFromFee[sender] ||
                _isExcludedFromFee[recipient] ||
                _isAdmin[sender] ||
                _isAdmin[recipient] ||
                tradingOpen,
            "Not authorized to trade yet"
        );

        uint256 blockSinceLaunch = block.number - _blockAtLaunch;
        uint256 _limit = _maxWalletSize;

        // Checks max transaction limit
        if (sender != owner() && recipient != owner() && recipient != DEAD) {
            if (recipient != pair) {
                if (blockSinceLaunch <= _blockRemoveLimits) {
                    _limit = _maxLittleWalletSize;
                } else if (
                    blockSinceLaunch > _blockRemoveLimits && _blockAtLaunch != 0
                ) {
                    _limit = _maxWalletSize;
                }
                require(
                    _isExcludedFromFee[recipient] ||
                        (_balances[recipient] + amount <= _limit),
                    "Transfer amount exceeds the MaxWallet size."
                );
            }
        }

        //shouldSwapBack
        if (shouldSwapBack() && recipient == pair) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - amount;

        //Check if should Take Fee
        uint256 amountReceived = (!shouldTakeFee(sender) ||
            !shouldTakeFee(recipient))
            ? amount
            : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !_isExcludedFromFee[sender];
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 blockSinceLaunch = block.number - _blockAtLaunch;
        uint256 tax;

        if (blockSinceLaunch >= _blockRemoveLimits) {
            tax = _finalTax;
        } else {
            if (sender == pair && recipient != pair) {
                tax = _initialBuyTax;
            } else if (sender != pair && recipient == pair) {
                tax = _initialSellTax;
            }
        }

        feeAmount = (amount * tax) / 100;

        if (feeAmount > 0) {
            _balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal lockTheSwap {
        uint256 amountToSwap = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), amountToSwap);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHDev = address(this).balance;

        if (amountETHDev > 0) {
            bool tmpSuccess;
            (tmpSuccess, ) = payable(_taxWallet).call{
                value: amountETHDev,
                gas: 30000
            }("");
        }
    }

    // Threshold management functions

    /** @dev Set a new threshold to trigger swapBack.
     * @notice Can only be called by the current owner.
     */
    function setSwapThreshold(uint256 newTax) external onlyOwner {
        swapThreshold = newTax;
    }

    // Internal functions

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    receive() external payable {}

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
