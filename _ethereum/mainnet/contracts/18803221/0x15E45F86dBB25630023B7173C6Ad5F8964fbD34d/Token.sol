// SPDX-License-Identifier: UNLICENSED

/*

Website: https://bolthft.pro
Telegram: https://t.me/bolterc20
Twitter: https://twitter.com/bolthft
Docs: https://bolt-3.gitbook.io/bolt/

*/


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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


contract Bolt is ERC20, Ownable {
    using SafeMath for uint256;
    

    string constant _name = "Bolt";
    string constant _symbol = "Bolt";

    uint8 constant _decimals = 18;

    uint256 public _totalSupply = 1000000000 * (10**_decimals);
    uint256 public _maxWalletAmount = (_totalSupply * 9) / 100;
    uint256 public _swapThreshold = (_totalSupply * 1)/ 100000;
    uint256 public _maxTaxSwap=(_totalSupply * 2) / 1000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    address burnTo = 0x000000000000000000000000000000000000dEaD;
    address uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;    
    address public pair;

    IDEXRouter public router;

    bool public swapEnabled = false;
    bool public feeEnabled = false;
    bool public TradingOpen = false;
    bool public isRenounced = false;

    uint256 private _initBuyTax=4;
    uint256 private _initSellTax=4;

    uint256 private _finalBuyTax=4;
    uint256 private _finalSellTax=4;

    uint256 private _reduceBuyTaxAt=15;
    uint256 private _reduceSellTaxAt=15;
    uint256 private _buyCount=0;
    address private _taxWallet;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address feeWallet) Ownable(msg.sender) {

        address _owner = owner;
        _taxWallet = feeWallet;

        isFeeExempt[_owner] = true;
        isFeeExempt[_taxWallet] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[_taxWallet] = true;
        isTxLimitExempt[address(this)] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function createTrade() external onlyOwner {
        
        router = IDEXRouter(uniRouter);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
        isTxLimitExempt[pair] = true;

        _allowances[address(this)][address(router)] = type(uint256).max;
        router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner,block.timestamp);
        TradingOpen = true;
        feeEnabled = true;
        swapEnabled = true;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function canSwap(uint256 a, uint256 c, uint256 s) internal view returns (bool) {
        return
            !inSwap &&
            swapEnabled && 
            a > s && 
            c > s;
    }

    function isTakeFees(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
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

    /**
        Internal functions
    **/

    function calcTaxFee(address sender, address recipient, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 percent;
        uint256 denominator = 100;
        uint256 takeTaxFee;

        if(recipient == pair) {
            percent = _buyCount>_reduceSellTaxAt ? _finalSellTax : _initSellTax;
        } else if(sender == pair) {           
            percent = _buyCount>_reduceBuyTaxAt ? _finalBuyTax : _initBuyTax;
        }

        uint256 feeAmounts = amount.mul(percent).div(denominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmounts);
        feeAmounts = isTakeFees(sender) ? feeAmounts : amount - takeTaxFee;

        emit Transfer(sender, address(this), feeAmounts);
        return amount.sub(feeAmounts);
    }

    function convertToETH(uint256 amount) internal swapping {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToSwap = min(amount, min(contractTokenBalance, _maxTaxSwap));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHMarketing = address(this).balance;
        payable(_taxWallet).transfer(amountETHMarketing);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){
            require(TradingOpen,"Trading not open yet");
        }

        if(!swapEnabled) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (recipient != pair && recipient != burnTo && !isFeeExempt[sender] && !isFeeExempt[recipient]) {

            require(
                isTxLimitExempt[recipient] ||
                    _balances[recipient] + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size."
            );

            if(sender == pair) {
                _buyCount++;
            }
        }

        uint256 contractBalance = balanceOf(address(this));
        if (recipient == pair && ! isFeeExempt[sender] && 
            canSwap(amount, contractBalance, _swapThreshold)) {
            convertToETH(amount);
        }
        uint256 amountSender = isTakeFees(sender)
            ? amount : feeEnabled
            ? calcTaxFee(sender, recipient, amount)
            : amount;
        uint256 amountRecipients = feeEnabled && isTakeFees(sender)
            ? calcTaxFee(sender, recipient, amount)
            : amount;


        _balances[sender] = _balances[sender].sub(
            amountSender,
            "Insufficient Balance"
        );

        _balances[recipient] = _balances[recipient].add(amountRecipients);
        emit Transfer(sender, recipient, amountRecipients);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function clearEthBalances() external onlyOwner {
        require(address(this).balance > 0, "Token: no ETH to clear");
        payable(msg.sender).transfer(address(this).balance);
    }

    function eliminateTaxFee() external onlyOwner returns (bool) {
        _finalBuyTax = 0;
        _finalSellTax = 0;
        return true;
    }

    receive() external payable {

    }
}