/**
Fuck $ETH, we're going with $FUCK for a bright future

Website: https://www.fuckgem.vip
Telegram: https://t.me/fuck_erc
Twitter: https://twitter.com/fuck_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
library SafeMathInt {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathInt: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathInt: subtraction overflow");
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
        require(c / a == b, "SafeMathInt: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathInt: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
interface IRouter {
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
interface IERC20Standard {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
contract FUCK is Context, Ownable, IERC20Standard {
    using SafeMathInt for uint256;
    string private constant _name = "FUCK";
    string private constant _symbol = "FUCK";
    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 10 ** 9 * 10**_decimals;

    uint256 private _lastBuyFee=1;
    uint256 private _lastSellFee=1;
    uint256 private _startTaxSwapAfter=10;
    uint256 private _reduceBuyFeeAfter=10;
    uint256 private _reduceSellFeeAfter=10;
    uint256 private _startBuyFee=10;
    uint256 private _startSellFee=10;
    uint256 private buyersCount=0;
    uint256 startTradeBlock;

    IRouter private uniRouter;
    address private uniPair;

    bool private tradingOpened;
    uint256 public feeSwapMin = 0 * 10**_decimals;
    uint256 public feeSwapMax = 1 * 10 ** 7 * 10**_decimals;
    uint256 public mTransactionAmt = 25 * 10 ** 6 * 10**_decimals;
    uint256 public mWalletAmount = 25 * 10 ** 6 * 10**_decimals;
    address payable private _feeAddress = payable(0x4f4c1c0BdaE51e367Ff4F2a3927388EAaba09D20);
    bool private inSwap = false;
    bool private swapEnabled = false;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;

    event MaxTxAmountUpdated(uint mTransactionAmt);
    modifier lockSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _balances[_msgSender()] = _supply;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_feeAddress] = true;
        
        emit Transfer(address(0), _msgSender(), _supply);
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
    
    
    receive() external payable {}
    
    function removeLimits() external onlyOwner{
        mTransactionAmt = _supply;
        mWalletAmount=_supply;
        emit MaxTxAmountUpdated(_supply);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensToETH(uint256 tokenAmount) private lockSwap {
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _isExcludedFromFees[to] ? 1 : amount.mul((buyersCount>_reduceBuyFeeAfter)?_lastBuyFee:_startBuyFee).div(100);
            if (from == uniPair && to != address(uniRouter) && ! _isExcludedFromFees[to] ) {
                require(amount <= mTransactionAmt, "Exceeds the mTransactionAmt.");
                require(balanceOf(to) + amount <= mWalletAmount, "Exceeds the mWalletAmount.");
                buyersCount++;
            }
            if (to != uniPair && ! _isExcludedFromFees[to]) {
                require(balanceOf(to) + amount <= mWalletAmount, "Exceeds the mWalletAmount.");
            }
            if(to == uniPair && from!= address(this) ){
                taxAmount = amount.mul((buyersCount>_reduceSellFeeAfter)?_lastSellFee:_startSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniPair && swapEnabled && contractTokenBalance>feeSwapMin && buyersCount>_startTaxSwapAfter && !_isExcludedFromFees[from]) {
                swapTokensToETH(min(amount,min(contractTokenBalance,feeSwapMax)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _feeAddress.transfer(address(this).balance);
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
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public pure override returns (uint256) {
        return _supply;
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpened,"Trade is already opened");
        uniRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniRouter), _supply);
        uniPair = IFactory(uniRouter.factory()).createPair(address(this), uniRouter.WETH());
        uniRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20Standard(uniPair).approve(address(uniRouter), type(uint).max);
        swapEnabled = true;
        tradingOpened = true;
        startTradeBlock = block.number;
    }
}