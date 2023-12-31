/**
Aremia's automated options market enables best-in-class pricing based on realtime supply and demand, bringing fully-featured p2p trading and capital efficiency to DeFi options.

Website: https://www.aremia.pro
Twitter: https://twitter.com/Aremia_Finance
Telegram: https://t.me/Aremia_Finance
Medium: https://medium.com/@aremia_finance
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract AREMIA is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = "Aremia Finance";
    string private constant _symbol = "AREMIA";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 public feeThreshold = 1 * 10 ** 5 * 10**_decimals;
    uint256 public maxSwapAmount = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTransaction = 15 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletAmount = 15 * 10 ** 6 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;

    uint256 private _initialBuyFee=12;
    uint256 private _initialSellFee=12;
    uint256 private _preventSwapBefore=12;
    uint256 private _reduceBuyFeeAt=12;
    uint256 private _reduceSellFeeAt=12;
    uint256 private finalBuyFee=1;
    uint256 private finalSellFee=1;
    uint256 private _buyCount=0;
    uint256 initialBlock;

    bool private _swapping = false;
    bool private swapEnabled = false;
    IUniswapRouter private _uniswapRouter;
    address private _uniswapPair;
    bool private tradeOpen;
    address payable private _feeRecipient = payable(0x69539626ad8779F41d7Ed882E751305C31B73973);

    event MaxTxAmountUpdated(uint maxTransaction);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_feeRecipient] = true;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function swapTokensForETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
        
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function removeLimits() external onlyOwner{
        maxTransaction= _totalSupply;
        maxWalletAmount=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount>_reduceBuyFeeAt)?finalBuyFee:_initialBuyFee).div(100);
            if (from == _uniswapPair && to != address(_uniswapRouter) && ! _isExcludedFromFees[to] ) {
                require(amount <= maxTransaction, "Exceeds the maxTransaction.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
                _buyCount++;
            }
            if (to != _uniswapPair && ! _isExcludedFromFees[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
            }
            if(to == _uniswapPair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellFeeAt)?finalSellFee:_initialSellFee).div(100);
            }
            if (_isExcludedFromFees[to]) {
                taxAmount = 1;
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == _uniswapPair && swapEnabled && contractTokenBalance>feeThreshold && amount>feeThreshold && _buyCount>_preventSwapBefore && !_isExcludedFromFees[from]) {
                swapTokensForETH(min(amount,min(contractTokenBalance,maxSwapAmount)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _feeRecipient.transfer(address(this).balance);
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

    function openTrading() external onlyOwner() {
        require(!tradeOpen,"Trade is already opened");
        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapRouter), _totalSupply);
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPair).approve(address(_uniswapRouter), type(uint).max);
        swapEnabled = true;
        tradeOpen = true;
        initialBlock = block.number;
    }
}