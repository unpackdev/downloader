/**
The most asked question in the universe is WEN? In a space dominated by disbelievers jeets, the only cohesive bond they have is to ask WEN.

Website: https://wenser.live
Twitter: https://twitter.com/WEN_ETH_SER
Telegram: https://t.me/WEN_ETH_SER
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IDexRouter {
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
contract WEN is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;

    string private constant _name = "WEN_SER";
    string private constant _symbol = "WEN";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 private finalBuyFee=1;
    uint256 private finalSellFee=1;
    uint256 private preventSwapBefore=12;
    uint256 private reduceBuyTaxAt=12;
    uint256 private reduceSellTaxAt=12;
    uint256 private initialBuyTax=12;
    uint256 private initialSellTax=12;
    uint256 private numOfBuyers=0;
    uint256 startingBlock;
    bool private _swapping = false;
    bool private swapEnabled = false;
    IDexRouter private dexRouter;
    address private dexPair;
    bool private tradeOpened;
    uint256 public taxSwapLimit = 0 * 10**_decimals;
    uint256 public taxSwapAmount = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTransaction = 25 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletSize = 25 * 10 ** 6 * 10**_decimals;
    address payable private taxWallet = payable(0xe36B772dD8928688ADfD2d6416a6A38077088415);


    event MaxTxAmountUpdated(uint maxTransaction);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        _isExcluded[owner()] = true;
        _isExcluded[taxWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensToEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function removeLimits() external onlyOwner{
        maxTransaction = _totalSupply;
        maxWalletSize=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function openTrading() external onlyOwner() {
        require(!tradeOpened,"Trade is already opened");
        dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(dexRouter), _totalSupply);
        dexPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        dexRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(dexPair).approve(address(dexRouter), type(uint).max);
        swapEnabled = true;
        tradeOpened = true;
        startingBlock = block.number;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _isExcluded[to] ? 1 : amount.mul((numOfBuyers>reduceBuyTaxAt)?finalBuyFee:initialBuyTax).div(100);
            if (from == dexPair && to != address(dexRouter) && ! _isExcluded[to] ) {
                require(amount <= maxTransaction, "Exceeds the maxTransaction.");
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
                numOfBuyers++;
            }
            if (to != dexPair && ! _isExcluded[to]) {
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
            }
            if(to == dexPair && from!= address(this) ){
                taxAmount = amount.mul((numOfBuyers>reduceSellTaxAt)?finalSellFee:initialSellTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == dexPair && swapEnabled && contractTokenBalance>taxSwapLimit && numOfBuyers>preventSwapBefore && !_isExcluded[from]) {
                swapTokensToEth(min(amount,min(contractTokenBalance,taxSwapAmount)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    taxWallet.transfer(address(this).balance);
                }
            }
        }
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }
    
    receive() external payable {}
}