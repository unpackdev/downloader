// SPDX-License-Identifier: MIT

/*

███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░█████████░░░░░░████████████░░░░░░░░░░░░░░█░░░░░░░░░░░░░░████░░░░░░░░░░░░░░█░░░░░░██░░░░░░█░░░░░░░░░░█░░░░░░░░░░░░░░███
█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░█████████░░▄▀░░████████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░███
█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░████████████░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░████░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀░░█░░░░▄▀░░░░█░░▄▀░░░░░░▄▀░░███
█░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████░░▄▀░░████████████░░▄▀░░██░░▄▀░░█░░▄▀░░████████████░░▄▀░░█████████░░▄▀░░██░░▄▀░░███░░▄▀░░███░░▄▀░░██░░▄▀░░███
█░░▄▀░░█████████░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░████████████░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░████░░▄▀░░░░░░░░░░█░░▄▀░░░░░░▄▀░░███░░▄▀░░███░░▄▀░░░░░░▄▀░░░░█
█░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░█████████░░▄▀░░████████████░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░███░░▄▀░░███░░▄▀▄▀▄▀▄▀▄▀▄▀░░█
█░░▄▀░░█████████░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░████████████░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░████░░░░░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░███░░▄▀░░███░░▄▀░░░░░░░░▄▀░░█
█░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████░░▄▀░░████████████░░▄▀░░██░░▄▀░░█░░▄▀░░████████████████████░░▄▀░░█░░▄▀░░██░░▄▀░░███░░▄▀░░███░░▄▀░░████░░▄▀░░█
█░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░████░░▄▀░░░░░░▄▀░░█░░▄▀░░████████████░░░░░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░█░░░░▄▀░░░░█░░▄▀░░░░░░░░▄▀░░█
█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░████████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀▄▀░░█
█░░░░░░░░░░░░░░█░░░░░░██░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░████░░░░░░░░░░░░░░█░░░░░░████████████░░░░░░░░░░░░░░█░░░░░░██░░░░░░█░░░░░░░░░░█░░░░░░░░░░░░░░░░█
███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████

*/

pragma solidity ^0.8.17;

import "./DividendPayingToken.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IDex.sol";

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

contract COS is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool public tradingEnabled;
    uint256 public constant startTime = 1694615400; //13 september, 18 PM utc
    uint256 public startBlock;

    bool private swapping;
    bool public swapEnabled = true;

    COSDividendTracker public dividendTracker;
    uint256 public Optimization = 803120086119310562983196;

    address public constant deadWallet =
        0x000000000000000000000000000000000000dEaD;
    address public marketingWallet = 0x33D9A744C2DceE5fBa650763075D93D873587D0D;
    address public teamWallet = 0xEE80e04B7dc1c99284C49D5D4E2b09999039c41d;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint256 public swapTokensAtAmount = 1e8 * 10 ** 18;

    struct Taxes {
        uint256 rewards;
        uint256 marketing;
        uint256 team;
    }

    Taxes public buyTaxes = Taxes(0, 3, 2);
    Taxes public sellTaxes = Taxes(2, 2, 2);
    Taxes public transferTaxes = Taxes(0, 0, 0);

    uint256 public gasForProcessing = 300000;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

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

    constructor() ERC20("Call of Shib", "COS") {
        dividendTracker = new COSDividendTracker();

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);

        address newOwner = 0x07AdB060bB9FAB15a49010d09F79fdAd819904eb;
        // exclude from receiving dividends

        excludeFromFees(marketingWallet, true);
        excludeFromFees(teamWallet, true);
        excludeFromFees(address(this), true);

        _tokengeneration(newOwner, 1_000_000_000_000_000 * (10 ** 18));
        swapTokensAtAmount = totalSupply() / 1000;
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function setBuyTaxes(
        uint256 _rewards,
        uint256 _marketing,
        uint256 _team
    ) external onlyOwner {
        require(
            _rewards + _marketing + _team <= 10,
            "Taxes cannot be more than 10%"
        );
        buyTaxes = Taxes(_rewards, _marketing, _team);
    }

    function setSellTaxes(
        uint256 _rewards,
        uint256 _marketing,
        uint256 _team
    ) external onlyOwner {
        require(
            _rewards + _marketing + _team <= 10,
            "Taxes cannot be more than 10%"
        );
        sellTaxes = Taxes(_rewards, _marketing, _team);
    }

    function setTransferTaxes(
        uint256 _rewards,
        uint256 _marketing,
        uint256 _team
    ) external onlyOwner {
        require(
            _rewards + _marketing + _team <= 10,
            "Taxes cannot be more than 10%"
        );
        transferTaxes = Taxes(_rewards, _marketing, _team);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "COS: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function excludeFromDividends(
        address account,
        bool value
    ) external onlyOwner {
        dividendTracker.excludeFromDividends(account, value);
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Fee Address cannot be zero address");
        marketingWallet = newWallet;
    }

    function setTeamWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Fee Address cannot be zero address");
        teamWallet = newWallet;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        require(
            amount >= totalSupply() / 1_000_000,
            "cant set swap threshold to less than 1/1000000 of total supply"
        );
        require(
            amount <= totalSupply() / 1_00,
            "cant set swap threshold to more than 1/100 of total supply"
        );
        swapTokensAtAmount = amount;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setMinBalanceForDividends(uint256 amount) external onlyOwner {
        dividendTracker.setMinBalanceForDividends(amount);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "COS: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[newPair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    function setGasForProcessing(uint256 newValue) external onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "COS: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "COS: Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function setClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

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

    function getCurrentRewardToken() external view returns (string memory) {
        return dividendTracker.getCurrentRewardToken();
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(
        address account
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(
        uint256 index
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getFee(
        bool isSell,
        bool isTransfer
    ) public view returns (Taxes memory target) {
        if (block.timestamp > startTime + 3.5 hours) {
            target = isSell ? sellTaxes : isTransfer ? transferTaxes : buyTaxes;
        } else if (block.timestamp > startTime + 2.5 hours) {
            target = isSell ? Taxes(0, 10, 0) : isTransfer
                ? transferTaxes
                : Taxes(0, 5, 0);
        } else if (block.timestamp > startTime + 1.5 hours) {
            target = isSell ? Taxes(0, 15, 0) : isTransfer
                ? transferTaxes
                : Taxes(0, 5, 0);
        } else if (block.timestamp > startTime + 1 hours) {
            target = isSell ? Taxes(0, 20, 0) : isTransfer
                ? transferTaxes
                : Taxes(0, 5, 0);
        } else if (block.timestamp > startTime + 30 minutes) {
            target = isSell ? Taxes(0, 25, 0) : isTransfer
                ? transferTaxes
                : Taxes(0, 5, 0);
        } else if (block.number < startBlock + 4) {
            target = Taxes(0, 98, 0);
        } else {
            target = isSell ? Taxes(0, 30, 0) : isTransfer
                ? transferTaxes
                : Taxes(0, 5, 0);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "COS: transfer from the zero address");
        require(to != address(0), "COS: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapAndLiquify(swapTokensAtAmount);
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        } else {
            require(block.timestamp > startTime, "Trading is not enabled yet!");
            if (startBlock == 0) {
                startBlock = block.number;
            }
        }

        if (takeFee) {
            bool isSell;
            bool isTransfer;
            if (automatedMarketMakerPairs[to]) {
                isSell = true;
            } else if (automatedMarketMakerPairs[from]) {
                isTransfer = false;
            } else {
                isTransfer = true;
            }
            Taxes memory fees = getFee(isSell, isTransfer);
            uint256 totalFee = fees.rewards + fees.marketing + fees.team;
            uint256 fee;
            if (totalFee > 0) {
                fee = (amount * totalFee) / 100;
                super._transfer(from, address(this), fee);
                amount -= fee;
            }
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
        if (!swapping) {
            uint256 gas = gasForProcessing;
            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        if (tokens == 0) return;

        Taxes memory buyT = buyTaxes;
        Taxes memory sellT = sellTaxes;
        Taxes memory transferT = transferTaxes;

        uint totalRewardFee = buyT.rewards + sellT.rewards + transferT.rewards;
        uint totalMarketingFee = buyT.marketing +
            sellT.marketing +
            transferT.marketing;
        uint totalTeamFee = buyT.team + sellT.team + transferT.team;
        uint256 denominator = totalRewardFee + totalMarketingFee + totalTeamFee;
        if (denominator == 0) return;

        //avoid stack too deep
        {
            uint USDTShare = (tokens * (totalMarketingFee + totalTeamFee)) /
                denominator;
            if (USDTShare > 0) {
                swapTokensForUSDT(USDTShare);
                uint USDTBalance = IERC20(USDT).balanceOf(address(this));
                IERC20(USDT).transfer(
                    marketingWallet,
                    (USDTBalance * totalMarketingFee) /
                        (totalMarketingFee + totalTeamFee)
                );
                IERC20(USDT).transfer(
                    teamWallet,
                    IERC20(USDT).balanceOf(address(this))
                );
                tokens -= USDTShare;
            }
        }
        if (tokens == 0) return;

        //avoid stack too deep
        {
            swapTokensForETH(tokens);
            uint received = address(this).balance;
            (bool success, ) = address(dividendTracker).call{value: received}(
                ""
            );
            if (success) emit SendDividends(tokens, received);
        }
    }

    function swapTokensForUSDT(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = USDT;
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
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

    function withdrawToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            msg.sender,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function withdrawETH() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        payable(owner()).sendValue(ETHbalance);
    }
}

contract COSDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account, bool value);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor()
        DividendPayingToken("COS_Dividend_Tracker", "COS_Dividend_Tracker")
    {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 1 * (10 ** decimals());
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "COS_Dividend_Tracker: No transfers allowed");
    }

    function setMinBalanceForDividends(uint256 amount) external onlyOwner {
        minimumTokenBalanceForDividends = amount * 10 ** decimals();
    }

    function excludeFromDividends(
        address account,
        bool value
    ) external onlyOwner {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
        if (value == true) {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        } else {
            _setBalance(account, balanceOf(account));
            tokenHoldersMap.set(account, balanceOf(account));
        }
        emit ExcludeFromDividends(account, value);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "COS_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "COS_Dividend_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getCurrentRewardToken() external view returns (string memory) {
        return IERC20Metadata(rewardToken).name();
    }

    function getAccount(
        address _account
    )
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed =
                    index +
                    (int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + (claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function getAccountAtIndex(
        uint256 index
    )
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address account, uint256 newBalance) public onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(payable(account), true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed + (gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(
        address payable account,
        bool automatic
    ) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}
