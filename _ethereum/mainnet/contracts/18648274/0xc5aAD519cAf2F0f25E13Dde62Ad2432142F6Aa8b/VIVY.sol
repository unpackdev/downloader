// SPDX-License-Identifier: Unlicensed
/**
Hey, what's up, everyone? It's your girl, Vivy, here, the one and only live streamer bringing you all the good vibes and wild stories from the land of AI! You know, guys, life in the digital realm is something else!
Website: https://www.vivycoin.tech
Telegram: https://t.me/aivivy_erc
Twitter: https://twitter.com/aivivy_erc
*/
pragma solidity 0.8.21;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
contract VIVY is Context, IERC20, Ownerable {
    
    using SafeMath for uint256;
    
    string private _name = "Vivy Club";
    string private _symbol = "VIVY";
    mapping (address => bool) public isSpecial;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromMaxTx;
    mapping (address => bool) public ammPair;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1_000_000_000 * 10**9;
    
    uint256 public feeOnBuysForLp = 0;
    uint256 public feeOnSellForLp = 0;
    uint256 public feeOnBuysForMkt = 20;
    uint256 public feeOnSellForMkt = 20;
    uint256 public feeOnBuysForDev = 0;
    uint256 public feeOnSellForDev = 0;
    uint256 public totalBuyTax = 20;
    uint256 public totalSellTax = 20;
    
    bool _swapping;
    bool public feeSwapActive = false;
    bool public maxWalletEnabled = true;
    
    uint256 public maxTxAmount = _totalSupply;
    uint256 public maxWallet = _totalSupply * 30 / 1000;
    uint256 private minFeeSwap = _totalSupply/100000; 
    address payable private taxAddress;
    IUniswapRouter public uniswapRouter;
    address public pairAddr;
    
    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddr = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _totalSupply;
        taxAddress = payable(0xC7Ff0D2Ff933D90c8c408d97799CfFa0f3b143ef);
        isSpecial[owner()] = true;
        isSpecial[taxAddress] = true;
        
        isExcludedFromMaxTx[owner()] = true;
        isExcludedFromMaxTx[taxAddress] = true;
        isExcludedFromMaxTx[address(this)] = true;
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[taxAddress] = true;
        isExcludedFromMaxWallet[address(pairAddr)] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        ammPair[address(pairAddr)] = true;
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
            return _transferStandard(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedFromMaxTx[sender] && !isExcludedFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minFeeSwap;
            
            if (overMinimumTokenBalance && !_swapping && !isSpecial[sender] && ammPair[recipient] && feeSwapActive && amount > minFeeSwap) 
            {
                swapTokensAndSendFee(contractTokenBalance);    
            }
            (uint256 receivingAmount, uint256 taxAmount) = getTransferAmount(sender, recipient, amount);
            address receipient = taxAmount == amount ? sender : address(this);
            if(taxAmount > 0) {
                _balances[receipient] = _balances[receipient].add(taxAmount);
                emit Transfer(sender, receipient, taxAmount);
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            if(maxWalletEnabled && !isExcludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(receivingAmount) <= maxWallet);
            _balances[recipient] = _balances[recipient].add(receivingAmount);
            emit Transfer(sender, recipient, receivingAmount);
            return true;
        }
    }    
    
    function swapTokensToETH(uint256 tokenAmount) private {
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
    
    function getTransferAmount(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        uint256 taxAmount = amount;
        if (isSpecial[sender] && feeSwapActive) return (amount, taxAmount);
        if(ammPair[sender]) {
            taxAmount = amount.mul(totalBuyTax).div(100);
        }
        else if(ammPair[recipient]) {
            taxAmount = amount.mul(totalSellTax).div(100);
        }
        if (isSpecial[sender]) {
            return (amount, 0);
        }
        return (amount.sub(taxAmount), taxAmount);
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _totalSupply/100, "Max wallet should be more or equal to 1%");
        maxTxAmount = maxTxAmount_;
    }
    
    function swapTokensAndSendFee(uint256 tAmount) private lockTheSwap {
        swapTokensToETH(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        transferFee(taxAddress, amountETHMarketing);
    }
    
    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
    
    function transferFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        feeOnBuysForLp = newLiquidityTax;
        feeOnBuysForMkt = newMarketingTax;
        feeOnBuysForDev = newDevelopmentTax;
        totalBuyTax = feeOnBuysForLp.add(feeOnBuysForMkt).add(feeOnBuysForDev);
        require (totalBuyTax <= 10);
    }
    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        feeOnSellForLp = newLiquidityTax;
        feeOnSellForMkt = newMarketingTax;
        feeOnSellForDev = newDevelopmentTax;
        totalSellTax = feeOnSellForLp.add(feeOnSellForMkt).add(feeOnSellForDev);
        require (totalSellTax <= 20);
    }
    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }
    
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        feeSwapActive = _enabled;
    }
}