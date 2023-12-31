/**
DFL will bring investors a completely new journey in the Memecoin world with bold plans and huge profits.
Join us in building a strong and positive community to welcome the upcoming boom of the market.

Website: http://dflcoin.vip
Telegram:  https://t.me/dfl_erc
Twitter: https://twitter.com/dfl_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

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
contract DFL is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "DFL";
    string private constant _symbol = "DFL";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 private _finalBuyFees=1;
    uint256 private _finalSellFees=1;
    uint256 private _preventSwapAfter=11;
    uint256 private _reduceBuyFeeAfter=11;
    uint256 private _reduceSellFeeAfter=11;
    uint256 private _firstBuyFee=11;
    uint256 private _firstSellFee=11;
    uint256 private buyersCount=0;
    uint256 _launchBlock;
    IDexRouter private uniswapRouter;
    address private uniswapPair;
    bool private tradingStarted;
    uint256 public swapTaxThreshold = 0 * 10**_decimals;
    uint256 public swapTaxLimit = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTransactionSize = 20 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletSize = 20 * 10 ** 6 * 10**_decimals;
    address payable private devAddress = payable(0xE6A8b06d4AE60dE8ba891D66E4aE33BEDcA9290c);
    bool private _swapping = false;
    bool private swapEnabled = false;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFees;

    event MaxTxAmountUpdated(uint maxTransactionSize);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        _excludedFees[owner()] = true;
        _excludedFees[devAddress] = true;
        
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
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _excludedFees[to] ? 1 : amount.mul((buyersCount>_reduceBuyFeeAfter)?_finalBuyFees:_firstBuyFee).div(100);
            if (from == uniswapPair && to != address(uniswapRouter) && ! _excludedFees[to] ) {
                require(amount <= maxTransactionSize, "Exceeds the maxTransactionSize.");
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
                buyersCount++;
            }
            if (to != uniswapPair && ! _excludedFees[to]) {
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
            }
            if(to == uniswapPair && from!= address(this) ){
                taxAmount = amount.mul((buyersCount>_reduceSellFeeAfter)?_finalSellFees:_firstSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == uniswapPair && swapEnabled && contractTokenBalance>swapTaxThreshold && buyersCount>_preventSwapAfter && !_excludedFees[from]) {
                swapTokens(min(amount,min(contractTokenBalance,swapTaxLimit)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    devAddress.transfer(address(this).balance);
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
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingStarted,"Trade is already opened");
        uniswapRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapRouter), _totalSupply);
        uniswapPair = IDexFactory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
        uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapPair).approve(address(uniswapRouter), type(uint).max);
        swapEnabled = true;
        tradingStarted = true;
        _launchBlock = block.number;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function swapTokens(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        maxTransactionSize = _totalSupply;
        maxWalletSize=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}