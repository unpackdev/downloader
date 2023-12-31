/**
Gyrowin is a cross-chain decentralized gaming, liquidity and assets management platform.

Website: https://www.gyrofinance.tech
App: https://app.gyrofinance.tech
Telegram: https://t.me/gyro_win
Twitter: https://twitter.com/gyro_win
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract GYROWIN is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Gyrowin Finance";
    string private constant _symbol = "GYROWIN";

    IUniswapRouter private routerInstance;
    address private pairAddress;
    bool private tradeStarted;

    bool private swapping = false;
    bool private swapEnabled = false;
    address payable private _feeWallet = payable(0xffbE9cB127b526ebD9060D66719E0ca321D93bC1);
    uint256 launchBlock;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcludedFromFees;

    uint8 private constant _decimals = 9;
    uint256 private constant _tSupply = 10 ** 9 * 10**_decimals;

    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _preventSwapBefore=16;
    uint256 private _reduceBuyTaxAt=16;
    uint256 private _reduceSellTaxAt=16;
    uint256 private _initialBuyTax=16;
    uint256 private _initialSellTax=16;
    uint256 private buyersCount=0;

    uint256 public swapThreshold = 0 * 10**_decimals;
    uint256 public maxTrxn = 25 * 10 ** 6 * 10**_decimals;
    uint256 public maxHolding = 25 * 10 ** 6 * 10**_decimals;
    uint256 public swapMax = 1 * 10 ** 7 * 10**_decimals;

    event MaxTxAmountUpdated(uint maxTrxn);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _tSupply;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[_feeWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _tSupply);
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
            taxAmount = isExcludedFromFees[to] ? 1 : amount.mul((buyersCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (from == pairAddress && to != address(routerInstance) && ! isExcludedFromFees[to] ) {
                require(amount <= maxTrxn, "Exceeds the maxTrxn.");
                require(balanceOf(to) + amount <= maxHolding, "Exceeds the maxHolding.");

                if (launchBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                buyersCount++;
            }

            if (to != pairAddress && ! isExcludedFromFees[to]) {
                require(balanceOf(to) + amount <= maxHolding, "Exceeds the maxHolding.");
            }

            if(to == pairAddress && from!= address(this) ){
                taxAmount = amount.mul((buyersCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to   == pairAddress && swapEnabled && contractTokenBalance>swapThreshold && buyersCount>_preventSwapBefore && !isExcludedFromFees[from]) {
                swapTokensForEth(min(amount,min(contractTokenBalance,swapMax)));
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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public pure override returns (uint256) {
        return _tSupply;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function sendETHToFee(uint256 amount) private {
        _feeWallet.transfer(amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradeStarted,"trading is already open");
        routerInstance = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(routerInstance), _tSupply);
        pairAddress = IUniswapFactory(routerInstance.factory()).createPair(address(this), routerInstance.WETH());
        routerInstance.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(pairAddress).approve(address(routerInstance), type(uint).max);
        swapEnabled = true;
        tradeStarted = true;
        launchBlock = block.number;
    }

    function removeLimits() external onlyOwner{
        maxTrxn = _tSupply;
        maxHolding=_tSupply;
        emit MaxTxAmountUpdated(_tSupply);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerInstance.WETH();
        _approve(address(this), address(routerInstance), tokenAmount);
        routerInstance.swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    receive() external payable {}

}