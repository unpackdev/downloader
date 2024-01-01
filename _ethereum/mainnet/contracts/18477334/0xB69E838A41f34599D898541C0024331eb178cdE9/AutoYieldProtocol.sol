pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./DividendTracker.sol";
import "./AutoYieldFarming.sol";
import "./IStaking.sol";

contract AutoYieldProtocol is ERC20, Ownable {
    IUniswapRouter public router;
    address public pair;
    address public projectDevelopmentWallet;
    DividendTracker public dividendTracker;
    AutoYieldFarming public autoYieldFarming;

    bool private swapping;
    bool public claimEnabled;
    bool public tradingEnabled;

    uint256 public swapTokensAtAmount;
    uint256 public antiBotAmount;
    uint256 public antiBotEndBlock;

    struct Taxes {
        uint256 projectDevelopment;
        uint256 holder;
        uint256 farming;
    }

    Taxes public buyTaxes = Taxes(1, 1, 0);
    Taxes public sellTaxes = Taxes(1, 1, 3);

    uint256 public totalBuyTax = 2;
    uint256 public totalSellTax = 5;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => mapping(uint256 => bool)) public isTransferred;

    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor(
        address _projectDevelopmentWallet,
        address _routerAddress
    ) ERC20("Auto Yield Protocol", "AYP") {
        dividendTracker = new DividendTracker();
        setProjectDevelopmentWallet(_projectDevelopmentWallet);

        IUniswapRouter _router = IUniswapRouter(_routerAddress);

        _approve(address(this), _routerAddress, type(uint256).max);

        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;
        setSwapTokensAtAmount(60_000);

        AutoYieldFarming _autoYieldFarming = new AutoYieldFarming(
            "AYP-ETH rLP",
            "AYP-ETH rLP",
            150 days,
            uint128(231481481481481000),
            _pair,
            address(this),
            _projectDevelopmentWallet
        );

        autoYieldFarming = _autoYieldFarming;

        antiBotAmount = 280_000 * (10 ** 18);

        IERC20(_pair).approve(address(_autoYieldFarming), type(uint256).max);

        _setAutomatedMarketMakerPair(_pair, true);

        dividendTracker.updateLP_Token(_pair);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(_autoYieldFarming), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0xdead), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(_projectDevelopmentWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(_autoYieldFarming), true);

        _mint(owner(), 7_000_000 * (10 ** 18)); // 70%
        _mint(address(_autoYieldFarming), 3_000_000 * (10 ** 18)); // 30%
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        DividendTracker newDividendTracker = DividendTracker(
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

    /// @notice Manual claim the dividends
    function claim() external {
        require(claimEnabled, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * 10 ** 18;
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueERC20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(projectDevelopmentWallet).call{
            value: ETHbalance
        }("");
        require(success);
    }

    function trackerRescueERC20Tokens(address tokenAddress) external {
        require(msg.sender == projectDevelopmentWallet, "Only Admin");
        dividendTracker.trackerRescueERC20Tokens(msg.sender, tokenAddress);
    }

    function trackerRescueETH() external {
        require(msg.sender == projectDevelopmentWallet, "Only Admin");
        dividendTracker.trackerRescueETH(msg.sender);
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IUniswapRouter(newRouter);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividends(
        address account,
        bool value
    ) public onlyOwner {
        dividendTracker.excludeFromDividends(account, value);
    }

    function setProjectDevelopmentWallet(address newWallet) public onlyOwner {
        projectDevelopmentWallet = newWallet;
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        claimEnabled = true;
        autoYieldFarming.startEpoch();
        antiBotEndBlock = block.number + 2;
    }

    function setClaimEnabled(bool state) external onlyOwner {
        claimEnabled = state;
    }

    function setLP_Token(address _lpToken) external onlyOwner {
        dividendTracker.updateLP_Token(_lpToken);
    }

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

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!isExcludedFromFees[from] && !isExcludedFromFees[to] && !swapping) {
            require(tradingEnabled, "Trading not active");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (tx.origin == from || tx.origin == to) {
            require(!isTransferred[tx.origin][block.number], "Bot!");
            isTransferred[tx.origin][block.number] = true;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;

            swapAndLiquify(swapTokensAtAmount);

            swapping = false;
        }

        bool takeFee = !swapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            uint256 farming;
            bool isSell;
            if (automatedMarketMakerPairs[to]) {
                feeAmt = (amount * totalSellTax) / 100;
                farming = (feeAmt * sellTaxes.farming) / totalSellTax;
                isSell = true;
            } else if (automatedMarketMakerPairs[from]) {
                feeAmt = (amount * totalBuyTax) / 100;
            }

            if (
                antiBotEndBlock > block.number &&
                amount > antiBotAmount &&
                to != address(this) &&
                automatedMarketMakerPairs[from]
            ) {
                feeAmt = (amount * 80) / 100;
            }

            amount = amount - feeAmt;

            super._transfer(from, address(this), feeAmt);

            if (isSell && !swapping) {
                swapping = true;
                swapAndFarm(farming, from);
                swapping = false;
            }
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 toSwapForHolder = (tokens * buyTaxes.holder) / totalBuyTax;

        uint256 toSwapForProjectDevelopment = tokens - toSwapForHolder;

        swapTokensForETH(toSwapForHolder / 2);

        uint256 currentbalance = address(this).balance;

        if (currentbalance > 0) {
            addLiquidity(toSwapForHolder / 2, currentbalance);
        }

        swapTokensForETH(toSwapForProjectDevelopment);

        uint256 projectDevelopmentAmt = address(this).balance;

        if (projectDevelopmentAmt > 0) {
            payable(projectDevelopmentWallet).transfer(projectDevelopmentAmt);
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

    function swapAndFarm(uint256 tokens, address swaper) private {
        swapTokensForETH(tokens / 2);
        uint256 currentbalance = address(this).balance;
        if (currentbalance > 0) {
            addLiquidity(tokens / 2, currentbalance);
        }

        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        autoYieldFarming.farm(lpBalance, swaper);
    }

    function manualLiquidityDistribution(uint256 amount) public onlyOwner {
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

        // Make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
}
