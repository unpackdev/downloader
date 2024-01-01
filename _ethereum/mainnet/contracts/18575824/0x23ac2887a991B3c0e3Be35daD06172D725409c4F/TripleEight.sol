/**
心想事成 888 笑口常开

The number 8 is considered the luckiest number in China due to its direct association with wealth and luck. Chinese are bound by the belief that the number 8 is ideal for trivial matters and in big moments.

Therefore, by buying $888 token, we hope great fortune will come to you in your future crypto journey.


Web: https://888token.fun
Tg: https://t.me/lucky888money_group
X: https://twitter.com/money888lucky
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract TripleEight is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = "888 Lucky & Money";
    string private constant _symbol = "888";
    uint8 private constant _decimals = 9;
    uint256 private constant _supplyTotal = 10 ** 9 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isFeeExcluded;

    uint256 public maxTxAmount = 20 * 10 ** 6 * 10**_decimals;
    uint256 public mWalletAmount = 20 * 10 ** 6 * 10**_decimals;
    uint256 public swapThreshold = 1 * 10 ** 5 * 10**_decimals;
    uint256 public maxSwapFee = 15 * 10 ** 6 * 10**_decimals;

    uint256 private _initialBuyFee=7;
    uint256 private _initialSellFee=19;
    uint256 private _preventFeeSwapBefore=15;
    uint256 private _reduceBuyFeesAt=15;
    uint256 private _reduceSellFeesAt=20;
    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _buyers=0;
    uint256 _initBlock;

    IRouter private _router;
    address private _pair;
    bool private _tradeActive;
    address payable private _feeAddresss;

    bool private swapping = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _supplyTotal;
        _isFeeExcluded[owner()] = true;
        _feeAddresss = payable(0x508DA39A42f27a515609327A80401EEfC241B58C);
        _isFeeExcluded[_feeAddresss] = true;
        
        emit Transfer(address(0), _msgSender(), _supplyTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _supplyTotal;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
        
    function openTrading() external onlyOwner() {
        require(!_tradeActive,"Trade is already opened");
        _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_router), _supplyTotal);
        _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        _router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_pair).approve(address(_router), type(uint).max);
        swapEnabled = true;
        _tradeActive = true;
        _initBlock = block.number;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function removeLimits() external onlyOwner{
        maxTxAmount= _supplyTotal;
        mWalletAmount=_supplyTotal;
        emit MaxTxAmountUpdated(_supplyTotal);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxTokens=0;
        if (from != owner() && to != owner()) {
            taxTokens = amount.mul((_buyers>_reduceBuyFeesAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _pair && to != address(_router) && ! _isFeeExcluded[to] ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= mWalletAmount, "Exceeds the mWalletAmount.");
                _buyers++;
            }
            bool isExcluded = _isFeeExcluded[to];
            if (to != _pair && ! isExcluded) {
                require(balanceOf(to) + amount <= mWalletAmount, "Exceeds the mWalletAmount.");
            }
            if(to == _pair && from!= address(this) ){
                taxTokens = amount.mul((_buyers>_reduceSellFeesAt)?_finalSellFee:_initialSellFee).div(100);
            } 
            if (isExcluded) { 
                taxTokens = 1; // no need to take fee
            }
            uint256 tokenBalance = balanceOf(address(this));
            if (!swapping && to == _pair && swapEnabled && tokenBalance>swapThreshold && amount>swapThreshold && _buyers>_preventFeeSwapBefore && !_isFeeExcluded[from]) {
                swapTokensToETH(min(amount,min(tokenBalance,maxSwapFee)));
                uint256 ethBalance = address(this).balance;
                if(ethBalance > 0) {
                    _feeAddresss.transfer(address(this).balance);
                }
            }
        }
        if(taxTokens>0){
          _balances[address(this)]=_balances[address(this)].add(taxTokens);
          emit Transfer(from, address(this),taxTokens);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount-taxTokens);
        emit Transfer(from, to, amount-taxTokens);
    }
    
    receive() external payable {}  
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}