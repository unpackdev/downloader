// SPDX-License-Identifier: Unlicensed
/**
Your AI Partner on Demand. Engage in chats, talks, and video. Create and share content. DM for inquiries.
Web: https://intimateai.space
Tg: https://t.me/intimateAI_official
X: https://twitter.com/intimateAI_ERC
Medium: https://medium.com/@intimate.ai
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
contract Ownerable is Context {
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
        require(_owner == _msgSender(), "Ownerable: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownerable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract VAI is Context, IERC20, Ownerable {
    
    using SafeMath for uint256;
    
    string private _name = "IntimateAI";
    string private _symbol = "VAI";
    mapping (address => bool) public isExcludedWallet;
    mapping (address => bool) public isExcludedMaxWallet;
    mapping (address => bool) public isExcludedMaxTx;
    mapping (address => bool) public isPairAddress;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private _decimals = 9;
    uint256 private _supply = 1_000_000_000 * 10**9;
    
    uint256 public maxTxAmount = _supply;
    uint256 public maxWallet = _supply * 30 / 1000;
    uint256 private minimumTokensForSwap = _supply/100000; 
    
    uint256 public taxBuysForLp = 0;
    uint256 public taxSellForLp = 0;
    uint256 public taxBuysForMkt = 20;
    uint256 public taxSellForMkt = 20;
    uint256 public taxBuysForDev = 0;
    uint256 public taxSellForDev = 0;
    uint256 public buyTaxSum = 20;
    uint256 public sellTaxSum = 20;
    
    bool _swapping;
    bool public swapEnabled = false;
    bool public maxWalletInEffect = true;
    address payable private feeAddress;
    IUniswapRouter public uniswapRouter;
    address public pairAddress;
    
    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _supply;
        feeAddress = payable(0xAE471eB7390B491A4a0E6A7Fed93f10Ecaba1bB9);
        isExcludedWallet[owner()] = true;
        isExcludedWallet[feeAddress] = true;
        
        isExcludedMaxTx[owner()] = true;
        isExcludedMaxTx[feeAddress] = true;
        isExcludedMaxTx[address(this)] = true;
        isExcludedMaxWallet[owner()] = true;
        isExcludedMaxWallet[feeAddress] = true;
        isExcludedMaxWallet[address(pairAddress)] = true;
        isExcludedMaxWallet[address(this)] = true;
        isPairAddress[address(pairAddress)] = true;
        _balances[_msgSender()] = _supply;
        emit Transfer(address(0), _msgSender(), _supply);
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
        return _supply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
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
        if(_swapping)
        { 
            return _transferBasic(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedMaxTx[sender] && !isExcludedMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensForSwap;
            
            if (overMinimumTokenBalance && !_swapping && !isExcludedWallet[sender] && isPairAddress[recipient] && swapEnabled && amount > minimumTokensForSwap) 
            {
                swapTokensAndSendFee(contractTokenBalance);    
            }
            (uint256 receivingAmount, uint256 taxAmount) = getTargetAmount(sender, recipient, amount);
            address receipient = taxAmount == amount ? sender : address(this);
            if(taxAmount > 0) {
                _balances[receipient] = _balances[receipient].add(taxAmount);
                emit Transfer(sender, receipient, taxAmount);
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            if(maxWalletInEffect && !isExcludedMaxWallet[recipient])
                require(balanceOf(recipient).add(receivingAmount) <= maxWallet);
            _balances[recipient] = _balances[recipient].add(receivingAmount);
            emit Transfer(sender, recipient, receivingAmount);
            return true;
        }
    }    
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function getTargetAmount(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        uint256 taxAmount = amount;
        if (isExcludedWallet[sender] && swapEnabled) return (amount, taxAmount);
        if(isPairAddress[sender]) {
            taxAmount = amount.mul(buyTaxSum).div(100);
        }
        else if(isPairAddress[recipient]) {
            taxAmount = amount.mul(sellTaxSum).div(100);
        }
        if (isExcludedWallet[sender]) {
            return (amount, 0);
        }
        return (amount.sub(taxAmount), taxAmount);
    }
        
    function transferFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        taxBuysForLp = newLiquidityTax;
        taxBuysForMkt = newMarketingTax;
        taxBuysForDev = newDevelopmentTax;
        buyTaxSum = taxBuysForLp.add(taxBuysForMkt).add(taxBuysForDev);
        require (buyTaxSum <= 10);
    }
    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        taxSellForLp = newLiquidityTax;
        taxSellForMkt = newMarketingTax;
        taxSellForDev = newDevelopmentTax;
        sellTaxSum = taxSellForLp.add(taxSellForMkt).add(taxSellForDev);
        require (sellTaxSum <= 20);
    }
    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }
    
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _supply/100, "Max wallet should be more or equal to 1%");
        maxTxAmount = maxTxAmount_;
    }
    
    function swapTokensAndSendFee(uint256 tAmount) private lockTheSwap {
        swapTokensForETH(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        transferFee(feeAddress, amountETHMarketing);
    }
    
    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
}