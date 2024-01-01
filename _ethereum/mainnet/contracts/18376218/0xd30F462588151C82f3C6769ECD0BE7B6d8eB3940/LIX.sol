/**
Lixir is a protocol dedicated to automating & optimizing concentrated liquidity provision on Uniswap V3  & Trident

Website: https://www.lixirprotocol.com
Telegram:  https://t.me/lixir_erc
Twitter: https://twitter.com/lixir_erc
App: https://app.lixirprotocol.com
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

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

contract LIX is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = "Lixir Finance";
    string private constant _symbol = "LIX ";
    uint8 private constant _decimals = 9;
    uint256 private constant _supplyTotal = 10 ** 9 * 10**_decimals;

    uint256 private initialBuyFees=13;
    uint256 private initialSellFees=13;
    uint256 private startSwappingAt=13;
    uint256 private reduceBuyTaxAt=13;
    uint256 private reduceSellTaxAt=13;
    uint256 private finalBuyTax=1;
    uint256 private finalSellTax=1;
    uint256 private numBuys=0;
    uint256 initialBlock;

    bool private _swapping = false;
    bool private swapEnabled = false;
    IRouter private _uniswapRouter;
    address private _uniswapPair;
    bool private tradeOpen;
    address payable private devWallet = payable(0x932520662ba1581865bBD2D4B8F2Aa46da1ED528);
    uint256 public swapThreshold = 1 * 10 ** 5 * 10**_decimals;
    uint256 public maximumTaxSwap = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTransactionSize = 15 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletAmount = 15 * 10 ** 6 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    event MaxTxAmountUpdated(uint maxTransactionSize);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _supplyTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[devWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _supplyTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }
        
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
        
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function removeLimits() external onlyOwner{
        maxTransactionSize= _supplyTotal;
        maxWalletAmount=_supplyTotal;
        emit MaxTxAmountUpdated(_supplyTotal);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((numBuys>reduceBuyTaxAt)?finalBuyTax:initialBuyFees).div(100);
            if (from == _uniswapPair && to != address(_uniswapRouter) && ! _isExcludedFromFee[to] ) {
                require(amount <= maxTransactionSize, "Exceeds the maxTransactionSize.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
                numBuys++;
            }
            if (to != _uniswapPair && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
            }
            if(to == _uniswapPair && from!= address(this) ){
                taxAmount = amount.mul((numBuys>reduceSellTaxAt)?finalSellTax:initialSellFees).div(100);
            }
            if (_isExcludedFromFee[to]) {
                taxAmount = 1;
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == _uniswapPair && swapEnabled && contractTokenBalance>swapThreshold && amount>swapThreshold && numBuys>startSwappingAt && !_isExcludedFromFee[from]) {
                swapTokensForETH(min(amount,min(contractTokenBalance,maximumTaxSwap)));
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
   
    function totalSupply() public pure override returns (uint256) {
        return _supplyTotal;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
        
    function swapTokensForETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function openTrading() external onlyOwner() {
        require(!tradeOpen,"Trade is already opened");
        _uniswapRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapRouter), _supplyTotal);
        _uniswapPair = IFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPair).approve(address(_uniswapRouter), type(uint).max);
        swapEnabled = true;
        tradeOpen = true;
        initialBlock = block.number;
    }
    receive() external payable {}
}