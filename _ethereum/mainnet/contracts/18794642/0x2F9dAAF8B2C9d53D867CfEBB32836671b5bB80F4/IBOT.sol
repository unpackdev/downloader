// SPDX-License-Identifier: Unlicensed

/**
The Minter you'll ever need.

Website: https://www.i-bot.pro
Telegram: https://t.me/ibot_erc
Twitter: https://twitter.com/ibot_erc
Bot: @Inscribe_Minter_Bot
 */

pragma solidity = 0.8.19;

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

interface IUniswapFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address pairAddress, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pairAddress);
    function createPair(address tokenA, address tokenB) external returns (address pairAddress);
}

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

contract IBOT is Context, Ownable, IERC20 {

    string constant private _name = "Inscribe Bot";
    string constant private _symbol = "IBOT";
    uint8 constant private _decimals = 9;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isAMMPair;
    mapping (address => uint256) private balance;

    uint256 constant public _totalSupply = 10 ** 9 * 10**9;
    uint256 constant public feeSwapMinimum = _totalSupply / 100_000;
    uint256 constant public taxOnTransfer = 0;
    uint256 constant public taxDenominator = 1_000;
    uint256 public taxOnBuy = 200;
    uint256 public taxOnSell = 200;
    uint256 private _maxTransaction = 25 * _totalSupply / 1000;
    bool private _feeSwapEnabled = true;
    address payable private _feeReceiver;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    address public pairAddress;
    IUniswapRouterV2 public uniswapRouter;
    bool public buyActive = false;
    bool private _swapping;
    bool private maxTxDeactivated = false;

        modifier inSwapFlag {
        _swapping = true;
        _;
        _swapping = false;
    }
    event SwapAndLiquify();


    constructor () {
        uniswapRouter = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _isExcludedFromFee[msg.sender] = true;
        _feeReceiver = payable(address(0xf62A57A396E519217c8431E7bE5DA9281e2365cd));
        _isExcludedFromFee[_feeReceiver] = true;
        _isExcluded[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        pairAddress = IUniswapFactoryV2(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        _isAMMPair[pairAddress] = true;
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
                    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }
    
    function golaunch() external onlyOwner {
        require(!buyActive, "Already Started");
        buyActive = true;
    }
    
    function removeAllLimtis() external onlyOwner {
        require(!maxTxDeactivated,"Already removed limit");
        _maxTransaction = _totalSupply;
        maxTxDeactivated = true;
        taxOnBuy = 10;
        taxOnSell = 10;
    }

    function isTakingFee(address ins, address out) internal view returns (bool) {
        bool isLimited = ins != owner()
            && out != owner()
            && msg.sender != owner()
            && !_isExcluded[ins]  && !_isExcluded[out] && out != address(0) && out != address(this);
            return isLimited;
    }
    
    function isBuy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !_isAMMPair[out] && _isAMMPair[ins];
        return _is_buy;
    }

    function isSell(address ins, address out) internal view returns (bool) { 
        bool _is_sell = _isAMMPair[out] && !_isAMMPair[ins];
        return _is_sell;
    }

    function isTransfer(address ins, address out) internal view returns (bool) { 
        bool _is_transfer = !_isAMMPair[out] && !_isAMMPair[ins];
        return _is_transfer;
    }
    
    function getReceiverAmount(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = taxOnBuy;  else if (issell)  fee = taxOnSell;  else  fee = taxOnTransfer; 
        if (fee == 0)  return amount; 
        uint256 feeAmount = amount * fee / taxDenominator;
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

        if(address(this).balance > 0) _feeReceiver.transfer(address(this).balance);
    } 
    
    function shouldSwapBack(address ins) internal view returns (bool) {
        bool canswap = _feeSwapEnabled && !_isExcludedFromFee[ins];
        return canswap;
    }
    
    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: can't transfer to the dead address");
        require(from != address(0), "ERC20: can't transfer from the dead address");
        require(amount > 0, "transfer amount must be greater than zero");

        if (isTakingFee(from,to)) {
            require(buyActive,"Trading is not enabled");
                    if(!_isAMMPair[to] && from != address(this) && to != address(this) || isTransfer(from,to) && !maxTxDeactivated)  { require(balanceOf(to) + amount <= _maxTransaction,"_maxTransaction exceed"); }}


        if(isSell(from, to) &&  !_swapping && shouldSwapBack(from)) {

            uint256 tokenAmount = balanceOf(address(this));
            if(tokenAmount >= feeSwapMinimum) { 
                if(amount > feeSwapMinimum) swapBack(tokenAmount);
             }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        uint256 amountAfterFee = (takeFee) ? getReceiverAmount(from, isBuy(from, to), isSell(from, to), amount) : amount;
        uint256 amountBeforeFee = (takeFee) ? amount : (!buyActive ? amount : 0);
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
        require(sender != address(0), "ERC20: Approveal on Zero Address");
        require(spender != address(0), "ERC20: Approveal on Zero Address");

        _allowances[sender][spender] = amount;
    }
}