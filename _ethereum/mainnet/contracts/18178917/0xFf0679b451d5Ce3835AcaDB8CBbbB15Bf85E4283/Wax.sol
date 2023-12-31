// SPDX-License-Identifier: MIT

/*
@@@@@@@@@@@@@&&#55J?!77777777!?Y55#&&@@@@@@@@@@@@@
@@@@@@@@@@&B5?777?J5PB#&&&&#BP5J?777?5#&@@@@@@@@@@
@@@@@@@&#57!7YPB&@@@@@@&@@@@@@@@@&BPY?!75#&@@@@@@@
@@@@@@57!!?G&@@@@@@@@@&7?#@@@@@@@@@@@&GJ!!?P@@@@@@
@@@@BY!!?P&@@@@@@@@@@@@B:~&@@@@@@@@@@@@&G?!!Y#@@@@
@@@G7!JB&@@@@@@@@@@@@@@J:.?&@@@@@@@@@@@@@&BJ!7B@@@
@@5!!P@@@@@@@@@@@@@@@B!.:..~7&@@@@@@@@@@@@@@P77P@@
@G!!P@@@@@@@@@@@@@@&?7:^7!:.:#@@@@@@@@@@@@@@@P77G@
#7!?&@@@@@@@@@@@@@@&7!!??7~~7&@@@@@@@@@@@@@@@@J7?&
577B@@@@@@@@@@@@@&&&&G?GP!!P#&&&@@@@@@@@@@@@@@#??P
77P@@@@@@@@@@@@@&~~~77JGG~7!~^~!#@@@@@@@@@@@@@@G??
77&@@@@@@@@@@@@@#::^:::^~::^^^^?&@@@@@@@@@@@@@@&J?
77&@@@@@@@@@@@@@&~^^^^^^^^~~~~!?&@@@@@@@@@@@@@@&J?
77P@@@@@@@@@@@@@&~^^~^^^^^!7~!7?&@@@@@@@@@@@@@@G??
Y7?B@@@@@@@@@@@@&!~!!^^^~!!7!!7J&@@@@@@@@@@@@@#J?5
#?7J&@@@@@@@@@@@&7!77~~^~!77?7?J&@@@@@@@@@@@@@Y??#
@G77P@@@@@@@@@@@&7!!!!!^~!77?7?J&@@@@@@@@@@@@G??G@
@@5?7P@@@@@@@@@@&?77777~!!7??7?J&@@@@@@@@@@@G??5@@
@@@G?7YB&@@GP7777!!77??!777????75?????GG&@#Y??G@@@
@@@@#57?YP7^^~~^^~~~^~~!7!7??7~~~^~~~^^^?Y??5#@@@@
@@@@@@P??77!!!!~~!!~~~^~!!7??7^~!~~~~~!7???P&@@@@@
@@@@@@@&#PJ?777!!7!~~!!!7777!!^~!!!!77?JP#&@@@@@@@
@@@@@@@@@@&#PJJ????777777777!777???JJPB&@@@@@@@@@@
@@@@@@@@@@@@@&&#PPYJ??????????JYPP#&&@@@@@@@@@@@@@
*/

/*
The Burning Candle. 

A revolutionized deflationary token that rewards holders.

Telegram: https://t.me/theburningcandle

Website: https://www.candlewax.io

X: https://twitter.com/candlewax_eth

*/
pragma solidity =0.8.15;

import "./LPShare.sol";

contract Wax is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public router;
    address public pair;

    bool private swapping;
    bool public swapEnabled = true;
    bool public claimEnabled;
    bool public tradingEnabled;
    bool public burnEnabled;

    WaxDividendTracker public dividendTracker;

    address public devWallet;

    uint256 public swapTokensAtAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;

    uint256 firstBuyTax = 15;
    uint256 secondBuyTax = 10;
    uint256 finalBuyTax = 5;

    uint256 firstSellTax = 20;
    uint256 secondSellTax = 15;
    uint256 thirdSellTax = 10;
    uint256 finalSellTax = 5;

    uint256 public totalBurned = 0;
    uint256 public totalBurnRewards = 0;

    uint256 public burnCapDivisor = 10; // Divisor for burn reward cap per tx
    uint256 public burnSub1EthCap = 100000000000000000; // cap in gwei if rewards < 1 Eth

    struct Shares {
        uint256 liquidity;
        uint256 dev;
        uint256 burn;
        uint256 burnForEth;
    }

    Shares public shares = Shares(2, 1, 0, 2);
    uint256 public totalShares = 5;

    uint256 private _startTxTimestamp;

    mapping(address => bool) public _isBot;

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
    event BurnedTokensForEth(
        address account,
        uint256 burnAmount,
        uint256 ethRecievedAmount
    );

    constructor(address _developerwallet) ERC20("Candle", "WAX") {
        dividendTracker = new WaxDividendTracker();
        setDevWallet(_developerwallet);

        IUniswapV2Router02 _router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;
        setSwapTokensAtAmount(300000);
        updateMaxWalletAmount(2000000);
        setMaxBuyAndSell(2500000, 2500000);

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

        _mint(owner(), 100000000 * (10**18));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        WaxDividendTracker newDividendTracker = WaxDividendTracker(
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

    function claim() external {
        require(claimEnabled, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }

    function burnForEth(uint256 amount) public returns (bool) {
        require(burnEnabled, "Burn not enabled");
        require(balanceOf(_msgSender()) >= amount, "not enough funds to burn");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256[] memory a = router.getAmountsOut(amount, path);

        uint256 cap;
        if (address(this).balance <= 1 ether) {
            cap = burnSub1EthCap;
        } else {
            cap = address(this).balance / burnCapDivisor;
        }

        require(a[a.length - 1] <= cap, "amount greater than cap");
        require(
            address(this).balance >= a[a.length - 1],
            "not enough funds in contract"
        );

        transferToAddressETH(payable(msg.sender), a[a.length - 1]);
        super._burn(_msgSender(), amount);

        totalBurnRewards += a[a.length - 1];
        totalBurned += amount;

        emit BurnedTokensForEth(_msgSender(), amount, a[a.length - 1]);
        return true;
    }

    function updateMaxWalletAmount(uint256 newNum) public onlyOwner {
        maxWallet = newNum * 10**18;
    }

    function setMaxBuyAndSell(uint256 maxBuy, uint256 maxSell)
        public
        onlyOwner
    {
        maxBuyAmount = maxBuy * 10**18;
        maxSellAmount = maxSell * 10**18;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * 10**18;
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(devWallet).call{value: ETHbalance}("");
        require(success);
    }

    function trackerRescueETH20Tokens(address tokenAddress) external onlyOwner {
        dividendTracker.trackerRescueETH20Tokens(msg.sender, tokenAddress);
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IUniswapV2Router02(newRouter);
    }

    /////////////////////////////////
    // Exclude / Include functions //
    /////////////////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded);
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividends(address account, bool value)
        public
        onlyOwner
    {
        dividendTracker.excludeFromDividends(account, value);
    }

    function setDevWallet(address newWallet) public onlyOwner {
        devWallet = newWallet;
    }

    function setDistributionSettings(
        uint256 _liquidity,
        uint256 _dev,
        uint256 _burn,
        uint256 _burnForEth
    ) external onlyOwner {
        shares = Shares(_liquidity, _dev, _burn, _burnForEth);
        totalShares = _liquidity + _dev + _burn + _burnForEth;
    }

    function setFinalBuyAndSellTaxes(uint256 _buyTax, uint256 _sellTax)
        external
        onlyOwner
    {
        finalBuyTax = _buyTax;
        finalSellTax = _sellTax;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setBurnEnabled(bool _enabled) external onlyOwner {
        burnEnabled = _enabled;
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        _startTxTimestamp = block.timestamp;
    }

    function setClaimEnabled(bool state) external onlyOwner {
        claimEnabled = state;
    }

    function setBot(address bot, bool value) external onlyOwner {
        require(_isBot[bot] != value);
        _isBot[bot] = value;
    }

    function setLP_Token(address _lpToken) external onlyOwner {
        dividendTracker.updateLP_Token(_lpToken);
    }

    function setAutomatedMarketMakerPair(address newPair, bool value)
        external
        onlyOwner
    {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value);
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

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(address account)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
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
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
            if (automatedMarketMakerPairs[to]) {
                require(
                    amount <= maxSellAmount,
                    "You are exceeding maxSellAmount"
                );
            } else if (automatedMarketMakerPairs[from]) {
                require(
                    amount <= maxBuyAmount,
                    "You are exceeding maxBuyAmount"
                );
            }
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
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            if (totalShares > 0) {
                swapAndLiquify(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 diffTimestamp = block.timestamp - _startTxTimestamp;
            uint256 feeAmt;
            if (automatedMarketMakerPairs[to]) {
                // sell
                if (diffTimestamp <= 60) {
                    // first 1 minute
                    feeAmt = (amount * firstSellTax) / 100;
                } else if (diffTimestamp <= 120) {
                    // next 1 minute
                    feeAmt = (amount * secondSellTax) / 100;
                } else if (diffTimestamp <= 240) {
                    // next 2 minutes
                    feeAmt = (amount * thirdSellTax) / 100;
                } else {
                    // all the way
                    feeAmt = (amount * finalSellTax) / 100;
                }
            } else if (automatedMarketMakerPairs[from]) {
                if (diffTimestamp <= 60) {
                    // first 1 minute
                    feeAmt = (amount * firstBuyTax) / 100;
                } else if (diffTimestamp <= 120) {
                    // next 1 minute
                    feeAmt = (amount * secondBuyTax) / 100;
                } else {
                    feeAmt = (amount * finalBuyTax) / 100;
                }
            }

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 toLP = ((tokens * shares.liquidity) / totalShares) / 2;
        uint256 toBurn = (tokens * shares.burn) / totalShares;
        uint256 toSwap = tokens.sub(toLP).sub(toBurn);
        uint256 ethBalanceBeforeSwap = address(this).balance;

        swapTokensForETH(toSwap);
        uint256 amountReceived = address(this).balance.sub(
            ethBalanceBeforeSwap
        );
        uint256 totalETHFee = totalShares.sub(shares.liquidity.div(2)).sub(
            shares.burn
        );

        uint256 amountETHLiquidity = ((amountReceived * shares.liquidity) /
            totalETHFee) / 2;
        uint256 amountETHBurn = (amountReceived * shares.burnForEth) /
            totalETHFee;
        uint256 amountETHDev = amountReceived -
            amountETHLiquidity -
            amountETHBurn;

        if (amountETHLiquidity > 0 && toLP > 0) {
            addLiquidity(toLP, amountETHLiquidity);
        }

        // Send ETH to dev
        if (amountETHDev > 0) {
            (bool success, ) = payable(devWallet).call{value: amountETHDev}("");
            require(success); //Failed to send ETH to dev wallet
        }

        uint256 lpBalance = IERC20(pair).balanceOf(address(this));

        // Send LP to dividends
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
        // burn
        super._burn(address(this), toBurn);
    }

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

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
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

contract WaxDividendTracker is Ownable, SharePayingToken {
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
        SharePayingToken("Wax_Dividend_Tracker", "Wax_Dividend_Tracker")
    {}

    function trackerRescueETH20Tokens(address recipient, address tokenAddress)
        external
        onlyOwner
    {
        IERC20(tokenAddress).transfer(
            recipient,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function updateLP_Token(address _lpToken) external onlyOwner {
        LP_Token = _lpToken;
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "No transfers allowed");
    }

    function excludeFromDividends(address account, bool value)
        external
        onlyOwner
    {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
        if (value == true) {
            _setBalance(account, 0);
        } else {
            _setBalance(account, balanceOf(account));
        }
        emit ExcludeFromDividends(account, value);
    }

    function getAccount(address account)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
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

    function setBalance(address account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }
        _setBalance(account, newBalance);
    }

    function processAccount(address payable account)
        external
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }
}
