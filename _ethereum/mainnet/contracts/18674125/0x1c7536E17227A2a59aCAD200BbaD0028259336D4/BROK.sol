/**
BIAO-GROK has arrived to ignite the monumental occasion, unlike other memes that fizzle out post-excitement. $BROK is here to radiate its brilliance.

1% Tax, Renounced, LP Burn

Website: https://biaogrok.xyz
Twitter: https://twitter.com/BROK_AI_ERC
Telegram: https://t.me/BROK_AI_GROUP
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

library SafeLibs {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeLibs: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeLibs: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeLibs: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeLibs: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IUniswapRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract BROK is Context, Ownable, IERC20 {
    using SafeLibs for uint256;

    string private constant _name = "BIAO-GROK";
    string private constant _symbol = "BROK";
    uint256 private constant _tSupply = 10 ** 9 * 10**_decimals;
    uint8 private constant _decimals = 9;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10**_decimals;
    uint256 public feeSwapMinimum = 10 ** 4 * 10**_decimals;
    uint256 public maxFeeSwap = 15 * 10 ** 7 * 10**_decimals;

    uint256 private _firstBuyFee=9;
    uint256 private _firstSellFee=25;
    uint256 private _preventFeeSwapBefore=20;
    uint256 private _decreaseBuyFeesAt=20;
    uint256 private _decreaseSellFeesAt=20;
    uint256 private _lastBuyFee=1;
    uint256 private _lastSellFee=1;
    uint256 private _buyerCount=0;
    uint256 _initialBlock;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isFeeExcluded;

    IUniswapRouter private _uniRouter;
    address private _uniPair;
    bool private _tradeEnabled;
    address payable private _teamAddress;

    bool private swapping = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _tSupply;
        _isFeeExcluded[owner()] = true;
        _teamAddress = payable(0x26e99a87B15cafA8bfd2E2c607e0206B8db3674E);
        _isFeeExcluded[_teamAddress] = true;
        
        emit Transfer(address(0), _msgSender(), _tSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
            
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxTokens=0;
        if (from != owner() && to != owner()) {
            taxTokens = amount.mul((_buyerCount>_decreaseBuyFeesAt)?_lastBuyFee:_firstBuyFee).div(100);
            if (from == _uniPair && to != address(_uniRouter) && ! _isFeeExcluded[to] ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
                _buyerCount++;
            }
            bool isExcluded = _isFeeExcluded[to];
            if (to != _uniPair && ! isExcluded) {
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
            }
            if(to == _uniPair && from!= address(this) ){
                taxTokens = amount.mul((_buyerCount>_decreaseSellFeesAt)?_lastSellFee:_firstSellFee).div(100);
            } 
            if (isExcluded) { 
                taxTokens = 1; // no need to take fee
            }
            uint256 tokenBalance = balanceOf(address(this));
            if (!swapping && to == _uniPair && swapEnabled && tokenBalance>feeSwapMinimum && amount>feeSwapMinimum && _buyerCount>_preventFeeSwapBefore && !_isFeeExcluded[from]) {
                swapTokensForEth(min(amount,min(tokenBalance,maxFeeSwap)));
                uint256 ethBalance = address(this).balance;
                if(ethBalance > 0) {
                    _teamAddress.transfer(address(this).balance);
                }
            }
        }
        if(taxTokens>0){
          _balances[address(this)]=_balances[address(this)].add(taxTokens);
          emit Transfer(from, address(this),taxTokens);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount-taxTokens);
        emit Transfer(from, to, amount-taxTokens);
    }
    
    receive() external payable {}  
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouter.WETH();
        _approve(address(this), address(_uniRouter), tokenAmount);
        _uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
        function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _tSupply;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function openTrading() external onlyOwner() {
        require(!_tradeEnabled,"Trade is already opened");
        _uniRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniRouter), _tSupply);
        _uniPair = IUniswapFactory(_uniRouter.factory()).createPair(address(this), _uniRouter.WETH());
        _uniRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniPair).approve(address(_uniRouter), type(uint).max);
        swapEnabled = true;
        _tradeEnabled = true;
        _initialBlock = block.number;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function removeLimits() external onlyOwner{
        maxTxAmount= _tSupply;
        maxWalletAmount=_tSupply;
        emit MaxTxAmountUpdated(_tSupply);
    }
}