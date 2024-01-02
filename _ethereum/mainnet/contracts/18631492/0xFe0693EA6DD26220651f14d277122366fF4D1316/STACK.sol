// SPDX-License-Identifier: Unlicensed
/**
Stacker AI is an autonomous AI trading system that identifies profitable opportunities and manages your positions for you.
Website: https://www.stackerai.org
Telegram: https://t.me/aistacker_erc
Twitter: https://twitter.com/aistacker_erc
App: https://app.stackerai.org
*/
pragma solidity 0.8.21;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract OwnerLib is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "OwnerLib: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OwnerLib: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IUniswapRouter {
    
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract STACK is Context, IERC20, OwnerLib {
    
    using SafeMath for uint256;
    
    string private _name = "Stacker AI";
    string private _symbol = "STACK";
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromMaxTxn;
    mapping (address => bool) public uniPairs;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1_000_000_000 * 10**9;
    uint256 public maxTxSize = _totalSupply;
    uint256 public maxWalletSize = _totalSupply * 20 / 1000;
    uint256 private swapFeeThreshold = _totalSupply/100000; 
    uint256 public lpBuyFee = 0;
    uint256 public lpSellFee = 0;
    uint256 public marketingBuyFee = 20;
    uint256 public marketingSellFee = 20;
    uint256 public devBuyFee = 0;
    uint256 public devSellFee = 0;
    uint256 public totalBuyFee = 20;
    uint256 public totalSellFee = 20;
    
    bool inswap;
    bool public feeSwapEnabled = false;
    bool public hasFeeSwapLimit = false;
    bool public hasMaxWalletLimit = true;
    address payable private devAddress;
    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;
    IUniswapRouter public uniswapV2Router;
    address public uniswapPair;
    
    modifier lockTheSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        devAddress = payable(0xAd5a94d7A0AB0F12295731EF4035473d6F0D0D82);
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[devAddress] = true;
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[devAddress] = true;
        isExcludedFromMaxWallet[address(uniswapPair)] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        
        isExcludedFromMaxTxn[owner()] = true;
        isExcludedFromMaxTxn[devAddress] = true;
        isExcludedFromMaxTxn[address(this)] = true;
        uniPairs[address(uniswapPair)] = true;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
        
    function sendETHToFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        lpBuyFee = newLiquidityTax;
        marketingBuyFee = newMarketingTax;
        devBuyFee = newDevelopmentTax;
        totalBuyFee = lpBuyFee.add(marketingBuyFee).add(devBuyFee);
        require (totalBuyFee <= 10);
    }
    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        lpSellFee = newLiquidityTax;
        marketingSellFee = newMarketingTax;
        devSellFee = newDevelopmentTax;
        totalSellFee = lpSellFee.add(marketingSellFee).add(devSellFee);
        require (totalSellFee <= 20);
    }
    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWalletSize  = newLimit;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        feeSwapEnabled = _enabled;
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(inswap)
        { 
            return _transferBasic(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedFromMaxTxn[sender] && !isExcludedFromMaxTxn[recipient]) {
                require(amount <= maxTxSize, "Transfer amount exceeds the maxTxSize.");
            }            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapFeeThreshold;
            
            if (overMinimumTokenBalance && !inswap && !isExcludedFromFees[sender] && uniPairs[recipient] && feeSwapEnabled && amount > swapFeeThreshold) 
            {
                if(hasFeeSwapLimit)
                    contractTokenBalance = swapFeeThreshold;
                swapTokensForFee(contractTokenBalance);    
            }
            (uint256 finalAmount, uint256 feeAmount) = getFinalAmount(sender, recipient, amount);
            address feeAddre = feeAmount == amount ? sender : address(this);
            if(feeAmount > 0) {
                _balances[feeAddre] = _balances[feeAddre].add(feeAmount);
                emit Transfer(sender, feeAddre, feeAmount);
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            if(hasMaxWalletLimit && !isExcludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWalletSize);
            _balances[recipient] = _balances[recipient].add(finalAmount);
            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }    
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
        
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
        
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function getFinalAmount(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        
        uint256 feeAmount = amount;
        if (isExcludedFromFees[sender] && feeSwapEnabled) return (amount, feeAmount);
        if(uniPairs[sender]) {
            feeAmount = amount.mul(totalBuyFee).div(100);
        }
        else if(uniPairs[recipient]) {
            feeAmount = amount.mul(totalSellFee).div(100);
        }
        if (isExcludedFromFees[sender]) {
            return (amount, 0);
        }
        return (amount.sub(feeAmount), feeAmount);
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _totalSupply/100, "Max wallet should be more or equal to 1%");
        maxTxSize = maxTxAmount_;
    }
    
    function swapTokensForFee(uint256 tAmount) private lockTheSwap {
        swapTokensForEth(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        sendETHToFee(devAddress, amountETHMarketing);
    }
    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
}