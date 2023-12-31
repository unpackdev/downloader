/**
    SellAll - It is time to embrace the burn.

    Website: https://sellall.lol 
    Twitter: https://twitter.com/SellAllToken
    Telegram: https://t.me/SellAllToken
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
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
    event Approval(address indexed owner,address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    string private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract SellAll is ERC20, Ownable {
    IUniswapV2Router02 private uniswapV2Router;

    // address data-sets
    address public projectWallet;
    address public uniswapV2Pair;

    // bool data-sets
    bool private isLimitActive;
    bool private isTradingOpen;
    bool public addLiquidityEnabled;
    bool private swapping;

    // int data-sets
    uint256 public liquidityFeeBuy = 5;
    uint256 public liquidityFeeSell = 5;

    uint256 public maxTxSize;
    uint256 public maxWalletSize;
    uint256 public addLiquidityThreshold;

    // mapping data-sets
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private isExcludedFromMaxTx;
    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event setAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20("SellAll", "SELL") {
        uint256 totalSupply = 100_000_000 * 1e2; // two decimals
        _mint(msg.sender, totalSupply);

        //TESTNET Router
        // uniswapV2Router = IUniswapV2Router02(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008);

        //DEX data-sets  //MAINNET
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _setPair(address(uniswapV2Pair), true);

        projectWallet = msg.sender;
        isLimitActive = true;
        isTradingOpen = false;
        addLiquidityEnabled = false;

        maxTxSize = 1_000_000 * 1e2;
        maxWalletSize = 1_000_000 * 1e2;
        addLiquidityThreshold = (totalSupply * 5) / 10000; // 50,000 tokens or 0.05%

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTxSize(owner(), true);
        excludeFromMaxTxSize(address(this), true);
        excludeFromMaxTxSize(address(0), true);
        excludeFromMaxTxSize(address(0xdead), true);
        excludeFromMaxTxSize(address(uniswapV2Router), true);
        excludeFromMaxTxSize(address(uniswapV2Pair), true);
    }

    function launchToken(uint256 txSize, uint256 walletSize) external onlyOwner {
        require(!isTradingOpen, "The token can only be launched once!");
        maxTxSize = txSize;
        maxWalletSize = walletSize;
        isTradingOpen = true;
        addLiquidityEnabled = true;
    }

    function removeWalletLimits() external onlyOwner returns (bool) {
        isLimitActive = false;
        maxTxSize = totalSupply();
        maxWalletSize = totalSupply();
        return true;
    }

    function setAddLiquidityThreshold(uint256 threshold) external onlyOwner returns (bool) {
        // Minimum number of tokens required to swap and add liquidity
        require(
            threshold >= (totalSupply() * 1) / 100000,
            "Threshold to add liquidity must be higher than 0.001% total supply."
        );
        require(
            threshold <= (totalSupply() * 5) / 1000,
            "Threshold to add liquidity cannot be higher than 0.5% total supply."
        );
        addLiquidityThreshold = threshold;
        return true;
    }

    function setAddLiquidityEnabled(bool action) external onlyOwner {
        addLiquidityEnabled = action;
    }

    function setBuyFee(uint256 liquidityFee) external onlyOwner {
        liquidityFeeBuy = liquidityFee;
        require(liquidityFeeBuy <= 10, "Total buy fee must be <= 10%");
    }

    function setSellFee(uint256 liquidityFee) external onlyOwner {
        liquidityFeeSell = liquidityFee;
        require(liquidityFeeSell <= 10, "Total sell fee must be <= 10%");
    }

    function excludeFromMaxTxSize(address account, bool excluded) private onlyOwner {
        isExcludedFromMaxTx[account] = excluded;
    }

    function excludeFromFees(address account, bool excluded) private onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setPair(address pair, bool value) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setPair(pair, value);
    }

    function _setPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit setAutomatedMarketMakerPair(pair, value);
    }

    function setProjectAddress(address newAdd) external onlyOwner {
        // Remove old wallet privileges
        excludeFromFees(projectWallet, false);
        excludeFromMaxTxSize(projectWallet, false);

        // Add new projectWallet
        projectWallet = newAdd;
        excludeFromFees(projectWallet, true);
        excludeFromMaxTxSize(projectWallet, true);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (isLimitActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!isTradingOpen) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                // buying
                if (automatedMarketMakerPairs[from] && !isExcludedFromMaxTx[to]) {
                    require(amount <= maxTxSize, "Buy transfer amount exceeds the max transaction size." );
                    require(amount + balanceOf(to) <= maxWalletSize, "Max wallet size exceeded.");
                }
                // selling
                else if (automatedMarketMakerPairs[to] && !isExcludedFromMaxTx[from]) {
                    require(amount <= maxTxSize, "Sell transfer amount exceeds the max transaction size.");
                }
                // transfering
                else if (!isExcludedFromMaxTx[to]) {
                    require(amount + balanceOf(to) <= maxWalletSize, "Max wallet size exceeded.");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= addLiquidityThreshold;

        if (
            canSwap &&
            addLiquidityEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            SwapNow();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && liquidityFeeSell > 0) {
                fees = amount * liquidityFeeSell / 100;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && liquidityFeeBuy > 0) {
                fees = amount * liquidityFeeBuy / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function SwapNow() private {
        uint256 contractBalance = balanceOf(address(this));

        if (contractBalance == 0) {
            return;
        }

        // Maximum to swap at any one time is 20x the liquidity threshold
        if (contractBalance > addLiquidityThreshold * 20) {
            contractBalance = addLiquidityThreshold * 20;
        }

        uint256 liquidityTokens = contractBalance / 2;

        // All tokens besides those on the LP side get swapped for eth
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethForLiquidity = address(this).balance - initialETHBalance;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                liquidityTokens
            );
        }
    }

    function withdrawEth(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {}
}