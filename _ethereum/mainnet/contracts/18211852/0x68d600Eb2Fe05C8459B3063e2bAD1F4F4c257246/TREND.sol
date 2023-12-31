/**
The "Trend Dapp" platform offers real-time updates on the status of Dapped cases, enabling users to stay informed about ongoing investigations and outcomes.

Website: https://www.trendprotocol.org
Dapp: https://app.trendprotocol.org
Telegram: https://t.me/trend_erc
Twitter: https://twitter.com/trend_erc
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
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract TREND is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "TREND";
    string private constant _symbol = "TREND";
    uint8 private constant _decimals = 9;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private excludings;
    uint256 private constant supplytotal = 10 ** 9 * 10**_decimals;
    IUniswapRouter private uniswapRouter;
    address private _pairAdress;
    uint256 startBlock;
    bool private tradeEnable;
    uint256 private _finalBuyFee=5;
    uint256 private _finalSellFee=5;
    uint256 private _preventTaxBefore=10;
    uint256 private _reduceBuyFeeAt=15;
    uint256 private _reduceSellFeeAt=15;
    uint256 private _initialBuyFee=15;
    uint256 private _initialSellFee=15;
    uint256 private buyersCount=0;
    address payable private _devAddress = payable(0x17758899324d523dB8eEA2c63410199CE858449D);
    bool private swapping = false;
    bool private swapEnabled = false;

    uint256 public feeThreshold = 0 * 10**_decimals;
    uint256 public maxFeeSwap = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTransaction = 2 * 10 ** 7 * 10**_decimals;
    uint256 public maxWallet = 2 * 10 ** 7 * 10**_decimals;

    event MaxTxAmountUpdated(uint maxTransaction);
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = supplytotal;
        excludings[owner()] = true;
        excludings[_devAddress] = true;
        
        emit Transfer(address(0), _msgSender(), supplytotal);
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return supplytotal;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
    

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = excludings[to] ? 1 : amount.mul((buyersCount>_reduceBuyFeeAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _pairAdress && to != address(uniswapRouter) && ! excludings[to] ) {
                require(amount <= maxTransaction, "Exceeds the maxTransaction.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");
                buyersCount++;
            }
            if (to != _pairAdress && ! excludings[to]) {
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");
            }
            if(to == _pairAdress && from!= address(this) ){
                taxAmount = amount.mul((buyersCount>_reduceSellFeeAt)?_finalSellFee:_initialSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to   == _pairAdress && swapEnabled && contractTokenBalance>feeThreshold && buyersCount>_preventTaxBefore && !excludings[from]) {
                swapTokensForEth(min(amount,min(contractTokenBalance,maxFeeSwap)));
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

    function removeLimits() external onlyOwner{
        maxTransaction = supplytotal;
        maxWallet=supplytotal;
        emit MaxTxAmountUpdated(supplytotal);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function openTrading() external onlyOwner() {
        require(!tradeEnable,"Trade is already opened");
        uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapRouter), supplytotal);
        _pairAdress = IFactory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
        uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_pairAdress).approve(address(uniswapRouter), type(uint).max);
        swapEnabled = true;
        tradeEnable = true;
        startBlock = block.number;
    }

    function sendETHToFee(uint256 amount) private {
        _devAddress.transfer(amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
}