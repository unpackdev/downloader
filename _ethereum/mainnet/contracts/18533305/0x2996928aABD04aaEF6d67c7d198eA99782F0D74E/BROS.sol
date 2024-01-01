/**
Get ready to embark on an epic adventure that combines the nostalgia of the iconic Mario Brothers with the hilarity of internet memes.
Web: https://supermemebros.xyz
X: https://twitter.com/SuperBrosGroup
Community: https://t.me/SuperBrosGroup
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

contract Authenticate is Context {
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
        require(_owner == _msgSender(), "Authenticate: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapRouter {
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract BROS is Context, Authenticate, IERC20 {
    using SafeMath for uint256;

    string private constant _name = "Super Meme Bros";
    string private constant _symbol = "BROS";
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10 ** 9 * 10**_decimals;

    uint256 public _maxTransaction = 20 * 10 ** 6 * 10**_decimals;
    uint256 public _maxWalletSize = 20 * 10 ** 6 * 10**_decimals;
    uint256 public _swapThreshold = 1 * 10 ** 5 * 10**_decimals;
    uint256 public _swapMax = 2 * 10 ** 7 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    IUniswapRouter private _uniswapRouter;
    address private _uniswapPairs;
    bool private _tradeStart;
    address payable private _feeAddress = payable(0xBfb7929Fc913F8B4C80A6787f66C891B701C0aA4);

    bool private swapping = false;
    bool private swapEnabled = false;

    uint256 private _initialBuyFee=15;
    uint256 private _initialSellFee=35;
    uint256 private _preventFeeSwapBefore=11;
    uint256 private _reduceBuyFeesAt=1;
    uint256 private _reduceSellFeesAt=11;
    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _buyCount=0;
    uint256 _initialBlock;

    event MaxTxAmountUpdated(uint _maxTransaction);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_feeAddress] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
     
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
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

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount>_reduceBuyFeesAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _uniswapPairs && to != address(_uniswapRouter) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTransaction, "Exceeds the _maxTransaction.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the _maxWalletSize.");
                _buyCount++;
            }
            if (to != _uniswapPairs && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the _maxWalletSize.");
            }
            if(to == _uniswapPairs && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellFeesAt)?_finalSellFee:_initialSellFee).div(100);
            } if (_isExcludedFromFee[to]) { taxAmount = 1;}
            uint256 tokenBalance = balanceOf(address(this));
            if (!swapping && to == _uniswapPairs && swapEnabled && tokenBalance>_swapThreshold && amount>_swapThreshold && _buyCount>_preventFeeSwapBefore && !_isExcludedFromFee[from]) {
                swapTokensToETH(min(amount,min(tokenBalance,_swapMax)));
                uint256 ethBalance = address(this).balance;
                if(ethBalance > 0) {
                    _feeAddress.transfer(address(this).balance);
                }
            }
        }
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        uint256 amountToSend = amount-taxAmount;
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amountToSend);
        emit Transfer(from, to, amountToSend);
    }
    
    receive() external payable {}  

    function openTrading() external onlyOwner() {
        require(!_tradeStart,"Trade is already opened");
        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapRouter), _tTotal);
        _uniswapPairs = IFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairs).approve(address(_uniswapRouter), type(uint).max);
        swapEnabled = true;
        _tradeStart = true;
        _initialBlock = block.number;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function removeLimits() external onlyOwner{
        _maxTransaction= _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private lockTheSwap {
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
}