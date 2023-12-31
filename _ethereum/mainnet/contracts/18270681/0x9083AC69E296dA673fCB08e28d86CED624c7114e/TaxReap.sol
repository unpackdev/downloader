pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./Tracker.sol";

contract TaxReap is ERC20, Ownable {
    using SafeTransferLib for address;

    IUniswapRouter public router;
    address public pair;
    address public developmentFund;
    Tracker public tracker;

    bool private reapping;
    bool public tradingEnabled;

    uint256 public holdMinAmountToReap;

    struct Taxes {
        uint256 holder;
        uint256 developmentFund;
    }

    Taxes public taxes = Taxes(3, 2);

    uint256 public totalTax = taxes.holder + taxes.developmentFund;
    uint256 public reapIncentive = 10; // Reaper earn 10% of total tax

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => mapping(uint256 => bool)) public isTransferSpent;
    mapping(address => bool) public isBot;

    uint256 antiBotTime;
    uint256 antiBotDuration = 300; // Block bots in this duration

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    modifier reap() {
        reapping = true;
        _;
        reapping = false;
    }

    constructor(
        address _routerAddress,
        address _developmentFund
    ) ERC20("TaxReap", "TXR") {
        tracker = new Tracker();
        setDevelopmentFund(_developmentFund);

        IUniswapRouter _router = IUniswapRouter(_routerAddress);

        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;
        setMinAmountToReap(100_000);

        _setAutomatedMarketMakerPair(_pair, true);

        tracker.excludeFromDividends(address(tracker), true);
        tracker.excludeFromDividends(address(this), true);
        tracker.excludeFromDividends(owner(), true);
        tracker.excludeFromDividends(address(0xdead), true);
        tracker.excludeFromDividends(address(_router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(_developmentFund, true);
        excludeFromFees(address(this), true);

        _mint(owner(), 100_000_000 * (10 ** 18));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        Tracker newDividendTracker = Tracker(payable(newAddress));
        newDividendTracker.excludeFromDividends(
            address(newDividendTracker),
            true
        );
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(address(router), true);
        tracker = newDividendTracker;
    }

    /// @notice Manual claim the dividends
    function claim() external {
        tracker.processAccount(payable(msg.sender));
    }

    function setMinAmountToReap(uint256 amount) public onlyOwner {
        holdMinAmountToReap = amount * 10 ** 18;
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(developmentFund).call{value: ETHbalance}("");
        require(success);
    }

    function trackerRescueETH20Tokens(address tokenAddress) external onlyOwner {
        tracker.trackerRescueETH20Tokens(msg.sender, tokenAddress);
    }

    function trackerRescueStuckETH() external {
        require(msg.sender == developmentFund, "Not Admin");
        tracker.trackerRescueStuckETH(msg.sender);
    }

    function blockBot(address[] calldata _addresses) external onlyOwner {
        require(
            block.timestamp <= antiBotTime || !tradingEnabled,
            "Can only block bot in the first 5 minutes"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            isBot[_addresses[i]] = true;
        }
    }

    function unblockBot(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            isBot[_addresses[i]] = false;
        }
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IUniswapRouter(newRouter);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividends(
        address account,
        bool value
    ) public onlyOwner {
        tracker.excludeFromDividends(account, value);
    }

    function setDevelopmentFund(address newDevelopmentFund) public onlyOwner {
        developmentFund = newDevelopmentFund;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        antiBotTime = block.timestamp + antiBotDuration;
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
            tracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return tracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return tracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return tracker.balanceOf(account);
    }

    function getAccountInfo(
        address account
    ) external view returns (address, uint256, uint256, uint256, uint256) {
        return tracker.getAccount(account);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBot[from] && !isBot[to], "You are bot!");

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !reapping
        ) {
            require(tradingEnabled, "Trading is not active");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // prevent bot sandwich
        if (tx.origin == from || tx.origin == to) {
            require(!isTransferSpent[tx.origin][block.number], "You are bot!");
            isTransferSpent[tx.origin][block.number] = true;
        }

        bool takeFee = !reapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            feeAmt = (amount * totalTax) / 100;
            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }

        super._transfer(from, to, amount);

        try tracker.setBalance(from, balanceOf(from)) {} catch {}
        try tracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function reapNow() external reap {
        require(
            balanceOf(msg.sender) >= holdMinAmountToReap,
            "Not hold enough to reap"
        );
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForETH(contractBalance);

        uint256 currentbalance = address(this).balance;
        if (currentbalance > 0) {
            uint256 forReaper = (currentbalance * reapIncentive) / 100;
            currentbalance = currentbalance - forReaper;
            uint256 forHolder = (currentbalance * taxes.holder) / totalTax;
            uint256 forDevelopmentFund = currentbalance - forHolder;

            (msg.sender).safeTransferETH(forReaper);
            (developmentFund).safeTransferETH(forDevelopmentFund);
            address(tracker).safeTransferETH(forHolder);

            tracker.distributeRewardDividends(forHolder);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
