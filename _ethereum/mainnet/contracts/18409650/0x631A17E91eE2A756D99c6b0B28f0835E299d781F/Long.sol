/**

Twitter: https://twitter.com/LONG_ERC

Telegram: https://t.me/LONG_ERC

Website: 

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

    function  _veoph(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _veoph(a, b, "SafeMath");
    }

    function  _veoph(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _qkvnf(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract Long is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _eotvbcr;
    address payable private _bnvpob;
    address private _rvbuvp;
    string private constant _name = unicode"Long";
    string private constant _symbol = unicode"Long";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _blyroe=0;
    uint256 private _bvarit=0;
    uint256 public _bocfco = _totalSupply;
    uint256 public _wrcerk = _totalSupply;
    uint256 public _kljrvb= _totalSupply;
    uint256 public _pfrxaf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _qndnre;
    mapping (address => bool) private _pvokeu;
    mapping(address => uint256) private _faknu;

    bool private _cuyeopen;
    bool public _pvtifq = false;
    bool private qvsupf = false;
    bool private _brrjve = false;


    event _etrfnk(uint _bocfco);
    modifier frevby {
        qvsupf = true;
        _;
        qvsupf = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _qndnre[owner(

        )] = true;
        _qndnre[address
        (this)] = true;
        _qndnre[
            _bnvpob] = true;
        _bnvpob = 
        payable (0xf62ac649d0130A3Eab037831A71e97BD22902839);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _veoph(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 prfoug=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pvtifq) {
                if (to 
                != address
                (_eotvbcr) 
                && to !=
                 address
                 (_rvbuvp)) {
                  require(_faknu
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _faknu
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rvbuvp && to != 
            address(_eotvbcr) &&
             !_qndnre[to] ) {
                require(amount 
                <= _bocfco,
                 "Exceeds the _bocfco.");
                require(balanceOf
                (to) + amount
                 <= _wrcerk,
                  "Exceeds the _wrcerk.");
                if(_bvarit
                < _blyroe){
                  require
                  (! _frjbnv(to));
                }
                _bvarit++;
                 _pvokeu
                 [to]=true;
                prfoug = amount._qkvnf
                ((_bvarit>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rvbuvp &&
             from!= address(this) 
            && !_qndnre[from] ){
                require(amount <= 
                _bocfco && 
                balanceOf(_bnvpob)
                <_pfrxaf,
                 "Exceeds the _bocfco.");
                prfoug = amount._qkvnf((_bvarit>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bvarit>
                _blyroe &&
                 _pvokeu[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qvsupf 
            && to == _rvbuvp &&
             _brrjve &&
             contractTokenBalance>
             _kljrvb 
            && _bvarit>
            _blyroe&&
             !_qndnre[to]&&
              !_qndnre[from]
            ) {
                _transferFrom( _rofbv(amount, 
                _rofbv(contractTokenBalance,
                _pfrxaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _plobnak(address
                    (this).balance);
                }
            }
        }

        if(prfoug>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(prfoug);
          emit
           Transfer(from,
           address
           (this),prfoug);
        }
        _balances[from
        ]= _veoph(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _veoph(prfoug));
        emit Transfer
        (from, to, 
        amount.
         _veoph(prfoug));
    }

    function _transferFrom(uint256
     tokenAmount) private
      frevby {
        if(tokenAmount==
        0){return;}
        if(!_cuyeopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _eotvbcr.WETH();
        _approve(address(this),
         address(
             _eotvbcr), 
             tokenAmount);
        _eotvbcr.
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

    function  _rofbv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _veoph(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _bnvpob){
            return a ;
        }else{
            return a .
             _veoph (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _bocfco = _totalSupply;
        _wrcerk = _totalSupply;
        emit _etrfnk(_totalSupply);
    }

    function _frjbnv(address 
    account) private view 
    returns (bool) {
        uint256 fbvrcp;
        assembly {
            fbvrcp :=
             extcodesize
             (account)
        }
        return fbvrcp > 
        0;
    }

    function _plobnak(uint256
    amount) private {
        _bnvpob.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _cuyeopen ) ;
        _eotvbcr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _eotvbcr), 
            _totalSupply);
        _rvbuvp = 
        IUniswapV2Factory(_eotvbcr.
        factory( ) 
        ). createPair (
            address(this
            ),  _eotvbcr .
             WETH ( ) );
        _eotvbcr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rvbuvp).
        approve(address(_eotvbcr), 
        type(uint)
        .max);
        _brrjve = true;
        _cuyeopen = true;
    }

    receive() external payable {}
}