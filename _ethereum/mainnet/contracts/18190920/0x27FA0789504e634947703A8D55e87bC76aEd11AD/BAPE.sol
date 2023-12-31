/**
Make Great Again ETH bot that will make your life easier.

Website:https://www.bananapepesniper.com/
Telegram: https://t.me/banana_sniper
Twitter: https://twitter.com/bana_sniper
Sniper Bot: https://t.me/BananaPepeSniper_bot
Sell Bot: https://t.me/BananaPepeSell_bot
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

interface IUniswapFactoryV2 {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouterV2 {
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

contract BAPE is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "BananPepeBot";
    string private constant _symbol = "BAPE";

    IUniswapRouterV2 private uniRouter;
    address private pairAddr;
    bool private tradingEnabled;

    bool private swapping = false;
    bool private swapEnabled = false;
    address payable private taxWallet = payable(0x2BDf92FA6b03AdbA6Fb53827854aAC014e6fdb01);
    uint256 startBlock;

    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 10 ** 9 * 10**_decimals;

    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _preventSwapBefore=17;
    uint256 private _initialBuyTax=17;
    uint256 private _initialSellTax=17;
    uint256 private _reduceBuyTaxAt=17;
    uint256 private _reduceSellTaxAt=17;
    uint256 private buyCount=0;

    uint256 public swapThreshold = 0 * 10**_decimals;
    uint256 public swapLimit = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTxSize = 20 * 10 ** 6 * 10**_decimals;
    uint256 public maxWallet = 20 * 10 ** 6 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcluded;

    event MaxTxAmountUpdated(uint maxTxSize);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _supply;
        isExcluded[owner()] = true;
        isExcluded[taxWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _supply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public pure override returns (uint256) {
        return _supply;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = isExcluded[to] ? 1 : amount.mul((buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (from == pairAddr && to != address(uniRouter) && ! isExcluded[to] ) {
                require(amount <= maxTxSize, "Exceeds the maxTxSize.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");

                if (startBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                buyCount++;
            }

            if (to != pairAddr && ! isExcluded[to]) {
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");
            }

            if(to == pairAddr && from!= address(this) ){
                taxAmount = amount.mul((buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to   == pairAddr && swapEnabled && contractTokenBalance>swapThreshold && buyCount>_preventSwapBefore && !isExcluded[from]) {
                swapTokensForEth(min(amount,min(contractTokenBalance,swapLimit)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function sendETHToFee(uint256 amount) private {
        taxWallet.transfer(amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    receive() external payable {}

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function openTrading() external onlyOwner() {
        require(!tradingEnabled,"trading is already open");
        uniRouter = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniRouter), _supply);
        pairAddr = IUniswapFactoryV2(uniRouter.factory()).createPair(address(this), uniRouter.WETH());
        uniRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(pairAddr).approve(address(uniRouter), type(uint).max);
        swapEnabled = true;
        tradingEnabled = true;
        startBlock = block.number;
    }

    function removeLimits() external onlyOwner{
        maxTxSize = _supply;
        maxWallet=_supply;
        emit MaxTxAmountUpdated(_supply);
    }
}