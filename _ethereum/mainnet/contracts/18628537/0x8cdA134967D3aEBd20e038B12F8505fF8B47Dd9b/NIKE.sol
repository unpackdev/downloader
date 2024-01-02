/*

    /$$    /$$   /$$ /$$$$$$ /$$   /$$ /$$$$$$$$
  /$$$$$$ | $$$ | $$|_  $$_/| $$  /$$/| $$_____/
 /$$__  $$| $$$$| $$  | $$  | $$ /$$/ | $$      
| $$  \__/| $$ $$ $$  | $$  | $$$$$/  | $$$$$   
|  $$$$$$ | $$  $$$$  | $$  | $$  $$  | $$__/   
 \____  $$| $$\  $$$  | $$  | $$\  $$ | $$      
 /$$  \ $$| $$ \  $$ /$$$$$$| $$ \  $$| $$$$$$$$
|  $$$$$$/|__/  \__/|______/|__/  \__/|________/
 \_  $$_/                                       
   \__/                                         
                                               
 Website: https://www.nikeeths.com/
 Twitter: https://twitter.com/nike_eths
 Telegram: https://t.me/nikeethsportal

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract NIKE is Context, IERC20, Ownable {
    string private constant _name = unicode"Air Max 90";
    string private constant _symbol = unicode"NIKE";

    using SafeMath for uint256;
	
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address payable private _marketingWallet;
    uint256 firstBlock;

    uint256 private _initialBuyTax = 20;
    uint256 private _initialSellTax = 20;
    uint256 private _finalBuyTax = 1;
    uint256 private _finalSellTax = 1;
    uint256 private _reduceBuyTaxAt = 50;
    uint256 private _reduceSellTaxAt = 50;
    uint256 private _preventSwapBefore = 50;
    uint256 public _buyCount = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000 * 10 ** _decimals;
    uint256 public _maxTxAmount = 500000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 500000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 10000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 250000 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private LPcreated;
    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private isFinalLimitsSet = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _marketingWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
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

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        bool isBuy = from == uniswapV2Pair;
        bool isSell = to == uniswapV2Pair;

         if (!tradingOpen) {
            // Allow transfers for creating LP even when trading is not open
            if ((isBuy || isSell) && (from != address(this) && to != address(this))) {
                require(from == owner() || to == owner(), "Trading is not active.");
            }
        }

        if (from != owner() && to != owner()) {
            if (isBuy && !_isExcludedFromFee[to]) {
                taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax).div(100);
            } else if (isSell && (!_isExcludedFromFee[from] || from != address(this))) {
                taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            if (isBuy && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;

                if (!isFinalLimitsSet && _buyCount > _preventSwapBefore) {
                    _setFinalMaxLimits();
                    isFinalLimitsSet = true;
                }
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!inSwap && isSell && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;

                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
          _balances[address(this)] = _balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a > b) ? b : a;
    }

    function setExcludedFromFee(address account, bool excluded) external onlyOwner {
        _isExcludedFromFee[account] = excluded;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }

    function _setFinalMaxLimits() private {
        // set final max trx and max wallet to 2,000,000 tokens (2% of supply)
        _maxTxAmount = 2000000 * 10 ** _decimals; 
        _maxWalletSize = 2000000 * 10 ** _decimals;
        emit MaxTxAmountUpdated(2000000 * 10 ** _decimals);
    }
	
    function createLP() external onlyOwner() {
        require(!LPcreated, "LP is already created");
        require(!tradingOpen, "Trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _isExcludedFromFee[uniswapV2Pair] = true;
        _approve(address(this), address(uniswapV2Router), _tTotal);                
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        LPcreated = true;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "Trading is already open");
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
    }

    receive() external payable {}
}