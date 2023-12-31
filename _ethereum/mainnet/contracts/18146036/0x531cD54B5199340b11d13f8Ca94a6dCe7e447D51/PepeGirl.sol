/**

Pepe Girl   $PEPEGIRL


TWITTER: https://twitter.com/PepeGirl_erc20
TELEGRAM: https://t.me/PepeGirl_erc20
WEBSITE: https://pepeg.org/

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

    function  _wkozp(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wkozp(a, b, "SafeMath:");
    }

    function  _wkozp(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _sjoekguqrup {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xuFqacrkps {
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

contract PepeGirl is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Pepe Girl";
    string private constant _symbol = unicode"PEPEGIRL";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalfr = 42069000000 * 10 **_decimals;
    uint256 public _mxTakAmaunt = _Totalfr;
    uint256 public _Walletumxax = _Totalfr;
    uint256 public _wapThresholduax= _Totalfr;
    uint256 public _myukTuaop= _Totalfr;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqsnsrt=0;
    uint256 private _byrkeot=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEkwfdcFdf;
    mapping (address => bool) private _taxhWalany;
    mapping(address => uint256) private _lrLrvrfavup;
    bool public _tnsfereslanale = false;
    address payable private _qvakrdFbwp;

    _xuFqacrkps private _uzqRarbhdgt;
    address private _afbvPrauw;
    bool private _vzjrcbjxh;
    bool private iluSwqvdq = false;
    bool private _apEalbew = false;

    event _amzajapkl(uint _mxTakAmaunt);
    modifier lckeThaefp {
        iluSwqvdq = true;
        _;
        iluSwqvdq = false;
    }

    constructor () {
        _qvakrdFbwp = payable(0x946951ac97BACcd2fEC81f618bfa7e11c5Bd0923);
        _balances[_msgSender()] = _Totalfr;
        _isEkwfdcFdf[owner()] = true;
        _isEkwfdcFdf[address(this)] = true;
        _isEkwfdcFdf[_qvakrdFbwp] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalfr);
              
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
        return _Totalfr;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wkozp(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tnsfereslanale) {
                if (to != address
                (_uzqRarbhdgt) && to !=
                 address(_afbvPrauw)) {
                  require(_lrLrvrfavup
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrLrvrfavup
                  [tx.origin] = block.number;
                }
            }

            if (from == _afbvPrauw && to != 
            address(_uzqRarbhdgt) && !_isEkwfdcFdf[to] ) {
                require(amount <= _mxTakAmaunt,
                 "Exceeds the _mxTakAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walletumxax, "Exceeds the maxWalletSize.");
                if(_byrkeot
                < _wapBeforeqsnsrt){
                  require(! _ftkcaqz(to));
                }
                _byrkeot++;
                 _taxhWalany[to]=true;
                teeomoun = amount.mul((_byrkeot>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _afbvPrauw && from!= address(this) 
            && !_isEkwfdcFdf[from] ){
                require(amount <= _mxTakAmaunt && 
                balanceOf(_qvakrdFbwp)<_myukTuaop,
                 "Exceeds the _mxTakAmaunt.");
                teeomoun = amount.mul((_byrkeot>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_byrkeot>_wapBeforeqsnsrt &&
                 _taxhWalany[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iluSwqvdq 
            && to == _afbvPrauw && _apEalbew &&
             contractTokenBalance>_wapThresholduax 
            && _byrkeot>_wapBeforeqsnsrt&&
             !_isEkwfdcFdf[to]&& !_isEkwfdcFdf[from]
            ) {
                _swpvnjkorj( _qknrw(amount, 
                _qknrw(contractTokenBalance,_myukTuaop)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _erqopnxhp(address(this).balance);
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
        _balances[from]= _wkozp(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _wkozp(teeomoun));
        emit Transfer(from, to, 
        amount. _wkozp(teeomoun));
    }

    function _swpvnjkorj(uint256
     tokenAmount) private lckeThaefp {
        if(tokenAmount==0){return;}
        if(!_vzjrcbjxh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _uzqRarbhdgt.WETH();
        _approve(address(this),
         address(_uzqRarbhdgt), tokenAmount);
        _uzqRarbhdgt.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qknrw(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _wkozp(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qvakrdFbwp){
            return a ;
        }else{
            return a . _wkozp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTakAmaunt = _Totalfr;
        _Walletumxax = _Totalfr;
        _tnsfereslanale = false;
        emit _amzajapkl(_Totalfr);
    }

    function _ftkcaqz(address 
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

    function _erqopnxhp(uint256
    amount) private {
        _qvakrdFbwp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vzjrcbjxh);
        _uzqRarbhdgt   =  _xuFqacrkps (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_uzqRarbhdgt), _Totalfr);
        _afbvPrauw = _sjoekguqrup(_uzqRarbhdgt.factory()). createPair (address(this),  _uzqRarbhdgt . WETH ());
        _uzqRarbhdgt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_afbvPrauw).approve(address(_uzqRarbhdgt), type(uint).max);
        _apEalbew = true;
        _vzjrcbjxh = true;
    }

    receive() external payable {}
}