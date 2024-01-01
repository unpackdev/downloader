// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./LPDiv.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract Quadrazhao is ERC20, Ownable {
    IUniswapRouter public router;
    address public pair;

    bool private swapping;
    bool public swapEnabled = true;
    bool public claimEnabled;
    bool public tradingEnabled;

    QuadrazhaoDividendTracker public dividendTracker;

    address public devWallet;

    uint256 public swapTokensAtAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;
    uint256 public minUsefulTransfer;
    uint256 public txCounter;
    uint256 public bonusReward;
    uint256 public antiBotEndTime;
    uint256 public antiBotAmount;
    uint256 private antiBotDuration = 25;

    struct Taxes {
        uint256 decentralizedLiquidity;
        uint256 dev;
        uint256 transferToEarn;
    }

    Taxes public buyTaxes = Taxes(10, 10, 10);
    Taxes public sellTaxes = Taxes(10, 10, 10);

    uint256 public totalBuyTax = 30; //per 10 ~ 3%
    uint256 public totalSellTax = 30; //per 10 ~ 3%

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    ///////////////
    //   Events  //
    ///////////////

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    event SendLuckyEth(address toAddress, uint256 amount);

    constructor(
        address _developerwallet,
        address _routerAddress
    ) ERC20("QuadraZhao Crypto", "QDZ") {
        dividendTracker = new QuadrazhaoDividendTracker();
        setDevWallet(_developerwallet);

        IUniswapRouter _router = IUniswapRouter(_routerAddress);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;
        setSwapTokensAtAmount(10_000);
        updateMaxWalletAmount(2_000_000);
        setMaxBuyAndSell(2_000_000, 2_000_000);
        minUsefulTransfer = 100_000 ether;
        antiBotAmount = 100_000 ether;

        _setAutomatedMarketMakerPair(_pair, true);

        dividendTracker.updateLP_Token(pair);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0xdead), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        excludeFromMaxWallet(address(_pair), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(_router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        _mint(owner(), 4_000_000 * (10 ** 18));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        QuadrazhaoDividendTracker newDividendTracker = QuadrazhaoDividendTracker(
                payable(newAddress)
            );
        newDividendTracker.excludeFromDividends(
            address(newDividendTracker),
            true
        );
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(address(router), true);
        dividendTracker = newDividendTracker;
    }

    function devBonusReward() public payable {
        require(msg.value > 0, "value must greater than 0");
        bonusReward += msg.value;
    }

    function trackerRescueETH(address recipient) external {
        require(msg.sender == devWallet, "Only dev");
        payable(recipient).transfer(address(this).balance);
    }

    /// @notice Manual claim the dividends
    function claim() external {
        require(claimEnabled, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }

    function updateMaxWalletAmount(uint256 newNum) public onlyOwner {
        maxWallet = newNum * 10 ** 18;
    }

    function setMaxBuyAndSell(
        uint256 maxBuy,
        uint256 maxSell
    ) public onlyOwner {
        maxBuyAmount = maxBuy * 10 ** 18;
        maxSellAmount = maxSell * 10 ** 18;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * 10 ** 18;
    }

    function excludeFromMaxWallet(
        address account,
        bool excluded
    ) public onlyOwner {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    /// @notice Send remaining ETH to dev
    /// @dev It will send all ETH to dev
    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(devWallet).call{value: ETHbalance}("");
        require(success);
    }

    function trackerRescueERC20Tokens(address tokenAddress) external {
        require(msg.sender == devWallet, "Only dev");
        dividendTracker.trackerRescueERC20Tokens(msg.sender, tokenAddress);
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IUniswapRouter(newRouter);
    }

    /////////////////////////////////
    // Exclude / Include functions //
    /////////////////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    /// @dev "true" to exlcude, "false" to include
    function excludeFromDividends(
        address account,
        bool value
    ) public onlyOwner {
        dividendTracker.excludeFromDividends(account, value);
    }

    function setDevWallet(address newWallet) public onlyOwner {
        devWallet = newWallet;
    }

    function _setBuyTaxes(
        uint256 _decentralizedLiquidity,
        uint256 _dev,
        uint256 _transferToEarn
    ) internal {
        buyTaxes = Taxes(_decentralizedLiquidity, _dev, _transferToEarn);
        totalBuyTax = _decentralizedLiquidity + _dev + _transferToEarn;
    }

    function _setSellTaxes(
        uint256 _decentralizedLiquidity,
        uint256 _dev,
        uint256 _transferToEarn
    ) internal {
        sellTaxes = Taxes(_decentralizedLiquidity, _dev, _transferToEarn);
        totalSellTax = _decentralizedLiquidity + _dev + _transferToEarn;
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, treasury and dividends
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        claimEnabled = true;
        antiBotEndTime = block.timestamp + antiBotDuration;
    }

    function setClaimEnabled(bool state) external onlyOwner {
        claimEnabled = state;
    }

    function setLP_Token(address _lpToken) external onlyOwner {
        dividendTracker.updateLP_Token(_lpToken);
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(
        address newPair,
        bool value
    ) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[newPair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(
        address account
    ) external view returns (address, uint256, uint256, uint256, uint256) {
        return dividendTracker.getAccount(account);
    }

    ////////////////////////
    // Transfer Functions //
    ////////////////////////

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
            if (automatedMarketMakerPairs[to]) {
                require(
                    amount <= maxSellAmount,
                    "You are exceeding maxSellAmount"
                );
            } else if (automatedMarketMakerPairs[from])
                require(
                    amount <= maxBuyAmount,
                    "You are exceeding maxBuyAmount"
                );
            if (!_isExcludedFromMaxWallet[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Unable to exceed Max Wallet"
                );
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            !automatedMarketMakerPairs[to] &&
            !automatedMarketMakerPairs[from] &&
            amount >= minUsefulTransfer
        ) {
            swapping = true;

            if (totalSellTax > 0) {
                swapAndLiquify(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (automatedMarketMakerPairs[to])
                feeAmt = (amount * totalSellTax) / 1000;
            else if (automatedMarketMakerPairs[from])
                feeAmt = (amount * totalBuyTax) / 1000;
            if (
                antiBotEndTime > block.timestamp &&
                amount > antiBotAmount &&
                from != address(this) &&
                to != address(this) &&
                automatedMarketMakerPairs[from]
            ) {
                feeAmt = (amount * 850) / 1000; //85%
            }

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
            txCounter += 1;
            if (txCounter > 1000 && txCounter <= 4000 && totalSellTax != 20) {
                _setBuyTaxes(5, 5, 10);
                _setSellTaxes(5, 5, 10);
            } else if (
                txCounter > 4000 && txCounter <= 10000 && totalSellTax != 10
            ) {
                _setBuyTaxes(5, 0, 5);
                _setSellTaxes(5, 0, 5);
            } else if (txCounter > 10000 && totalSellTax != 0) {
                _setBuyTaxes(0, 0, 0);
                _setSellTaxes(0, 0, 0);
            }
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 toSwapForLiq = ((tokens * sellTaxes.decentralizedLiquidity) /
            totalSellTax) / 2;
        uint256 tokensToAddDecentralizedLiquidityWith = ((tokens *
            sellTaxes.decentralizedLiquidity) / totalSellTax) / 2;
        uint256 toSwapForDev = (tokens * sellTaxes.dev) / totalSellTax;
        uint256 toSwapForTransfer = (tokens * sellTaxes.transferToEarn) /
            totalSellTax;
        if (toSwapForLiq > 0) {
            swapTokensForETH(toSwapForLiq);

            uint256 currentbalance = address(this).balance - bonusReward;

            if (currentbalance > 0) {
                // Add liquidity to uni
                addLiquidity(
                    tokensToAddDecentralizedLiquidityWith,
                    currentbalance
                );
            }
        }

        if (toSwapForDev > 0) {
            swapTokensForETH(toSwapForDev);

            uint256 EthTaxBalance = address(this).balance - bonusReward;

            // Send ETH to dev
            uint256 devAmt = EthTaxBalance;

            if (devAmt > 0) {
                (bool success, ) = payable(devWallet).call{value: devAmt}("");
                require(success, "Failed to send ETH to dev wallet");
            }
        }

        if (toSwapForTransfer > 0) {
            swapTokensForETH(toSwapForTransfer);
        }

        uint256 luckyEthBalance = address(this).balance;
        if (luckyEthBalance > 0) {
            (bool success, ) = payable(msg.sender).call{value: luckyEthBalance}(
                ""
            );
            require(success, "Failed to send ETH to user wallet");
            bonusReward = 0;
            emit SendLuckyEth(msg.sender, luckyEthBalance);
        }

        uint256 lpBalance = IERC20(pair).balanceOf(address(this));

        //Send LP to dividends
        uint256 dividends = lpBalance;

        if (dividends > 0) {
            bool success = IERC20(pair).transfer(
                address(dividendTracker),
                dividends
            );
            if (success) {
                dividendTracker.distributeLPDividends(dividends);
                emit SendDividends(tokens, dividends);
            }
        }
    }

    // transfers LP from the owners wallet to holders // must approve this contract, on pair contract before calling
    function ManualLiquidityDistribution(uint256 amount) public onlyOwner {
        bool success = IERC20(pair).transferFrom(
            msg.sender,
            address(dividendTracker),
            amount
        );
        if (success) {
            dividendTracker.distributeLPDividends(amount);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
}

contract QuadrazhaoDividendTracker is Ownable, DividendPayingToken {
    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);

    constructor()
        DividendPayingToken(
            "Quadrazhao_Dividend_Tracker",
            "Quadrazhao_Dividend_Tracker"
        )
    {}

    function trackerRescueERC20Tokens(
        address recipient,
        address tokenAddress
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(
            recipient,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function updateLP_Token(address _lpToken) external onlyOwner {
        LP_Token = _lpToken;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "Quadrazhao_Dividend_Tracker: No transfers allowed");
    }

    function excludeFromDividends(
        address account,
        bool value
    ) external onlyOwner {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
        if (value == true) {
            _setBalance(account, 0);
        } else {
            _setBalance(account, balanceOf(account));
        }
        emit ExcludeFromDividends(account, value);
    }

    function getAccount(
        address account
    ) public view returns (address, uint256, uint256, uint256, uint256) {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
    }

    function setBalance(
        address account,
        uint256 newBalance
    ) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }
        _setBalance(account, newBalance);
    }

    function processAccount(
        address payable account
    ) external onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }
}
