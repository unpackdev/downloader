// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./DividendPayingToken.sol";
import "./IterableMapping.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./ITracker.sol";
import "./TokenTracker.sol";

/**
 * Social media :
 * Website: https://www.frogs4gaza.com/
 * Telegram: https://t.me/+SKBv_yfNj2kwZjBh
 * Twitter: https://twitter.com/ftrttstokeneth
 * Instagram: https://www.instagram.com/ftrttstokeneth/
 */

contract Token is TokenTracker {
    using SafeERC20 for ERC20;

    uint256 constant BASE = 1 ether;
    uint256 constant REWARDS_FEE = 75;
    uint256 constant DEV_FEE = 25;
    uint256 constant FUND_FEE = 50;
    uint256 constant MILLE = 1000;
    uint256 constant TOTAL_FEES = REWARDS_FEE + DEV_FEE + FUND_FEE;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Router02 constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint256 public constant maxSupply = 9_000_000_000 * BASE; // Initial supply

    uint256 buyLimitTimestamp; // buy limit for the first 5 minutes
    uint256 liquidateTokensAtAmount = 900_000 * BASE; // minimum held in token contract to process fees
    uint256 public yearlyUnlock;

    address uniswapV2Pair;
    address public devAddress;
    address public fundAddress;

    bool liquidating;
    bool isBuysTaxable;
    bool public tradingEnabled; // whether the token can already be traded

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event DevWalletUpdated(address indexed newDevWallet, address indexed oldDevWallet);

    event ExcludeFromFees(address indexed account, bool exclude);

    constructor(address _devAddress, address _fundAddress)
        DividendToken("From the River to the Sea", "FTRTTS")
        Ownable(msg.sender)
    {
        // exclude from paying fees or having max transaction amount
        _excludeFromFees(msg.sender, true);
        _excludeFromFees(_devAddress, true);
        _excludeFromFees(address(this), true);
        // excludeFromFees(_fundAddress, true);
        _excludeFromDividends(address(uniswapV2Router), true);
        _excludeFromDividends(msg.sender, true);
        _excludeFromDividends(address(this), true);
        // update the dev address
        devAddress = _devAddress;
        fundAddress = _fundAddress;
        // enable owner wallet to send tokens before presales are over.
        users[address(0)].canTransferBeforeTradingIsEnabled = true;
        users[msg.sender].canTransferBeforeTradingIsEnabled = true;

        uint256 _supply = maxSupply; // Initial supply
        _supply -= maxSupply * 10 / 100; // 10% burn
        _mint(msg.sender, _supply);

        //  Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH);
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        isBuysTaxable = true;
        yearlyUnlock = block.timestamp + 365 days;
    }

    /// @dev Distributes dividends whenever ether is paid to this contract.
    receive() external payable {
        if (msg.sender == address(uniswapV2Router)) {
            uint256 dividends = msg.value;
            uint256 devTokens = dividends * DEV_FEE / TOTAL_FEES;
            sendEth(devAddress, devTokens);
            uint256 fundTokens = dividends * FUND_FEE / TOTAL_FEES;
            sendEth(fundAddress, fundTokens);
            uint256 rewardTokens = dividends - (devTokens + fundTokens);
            _distributeDividends(rewardTokens);
        } else {
            sendEth(fundAddress, msg.value);
        }
    }

    // owner restricted
    function activate() public onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        buyLimitTimestamp = block.timestamp + 3600;
    }

    function addTransferBeforeTrading(address account) external onlyOwner {
        users[account].canTransferBeforeTradingIsEnabled = true;
    }

    function blackList(address _user, bool value) external onlyOwner {
        require(users[_user].isBlacklisted != value, "blacklist set");
        users[_user].isBlacklisted = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Immutbale Pair");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function updateDevWallet(address newDevWallet) external onlyOwner {
        require(newDevWallet != devAddress, "dev wallet set!");
        _excludeFromFees(newDevWallet, true);
        emit DevWalletUpdated(newDevWallet, devAddress);
        devAddress = newDevWallet;
    }

    function recoverERC20(address token) external onlyOwner {
        require(token != address(this), "invalid token");
        ERC20(token).safeTransfer(owner(), ERC20(token).balanceOf(address(this)));
    }

    // any unclaimed rewards will yearly be distributed 33% to dev wallet and 66% to relief fund
    function unlockUnclaimedYearly() external onlyOwner {
        require(block.timestamp > yearlyUnlock, "invalid unlock");
        yearlyUnlock = block.timestamp + 365 days;
        sendEth(devAddress, address(this).balance / 3);
        sendEth(fundAddress, address(this).balance);
    }

    function updateAmountToLiquidateAt(uint256 liquidateAmount) external onlyOwner {
        require(liquidateAmount != liquidateTokensAtAmount, "liquidate amount set!");
        liquidateTokensAtAmount = liquidateAmount;
    }

    function switchBuyTaxable(bool enabled) external onlyOwner {
        require(enabled != isBuysTaxable, "buys tax set!");
        isBuysTaxable = enabled;
    }

    function _excludeFromFees(address account, bool exclude) internal {
        require(users[account].isExcludedFromFees != exclude, "exclude fees set!");
        users[account].isExcludedFromFees = exclude;
        emit ExcludeFromFees(account, exclude);
    }

    function excludeFromFees(address account, bool enabled) external onlyOwner {
        _excludeFromFees(account, enabled);
    }

    // public functions
    function isExcludedFromFees(address account) public view returns (bool) {
        return users[account].isExcludedFromFees;
    }

    function hasDividends(address account) external view returns (bool) {
        (, int256 index,,,,,,) = _getAccount(account);
        return (index > -1);
    }

    function claimAccount(address user) public {
        uint256 amount = processAccount(payable(user));
        require(amount > 0, "0ETH");
    }

    function claim() external {
        claimAccount(msg.sender);
    }

    // private functions
    function sendEth(address account, uint256 amount) private {
        (bool success,) = account.call{value: amount}("");
        require(success, "failed ETH");
    }

    function swap(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of eth
            path,
            address(this),
            block.timestamp
        );
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(users[pair].automatedMarketMakerPairs != value, "AMM pair set!");
        users[pair].automatedMarketMakerPairs = value;
        if (value) _excludeFromDividends(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _update(address from, address to, uint256 amount) internal override {
        // blacklisting check
        require(!users[from].isBlacklisted && !users[to].isBlacklisted, "from or to is blacklisted");

        if (amount == 0) {
            super._update(from, to, 0);
            return;
        }

        bool tradingIsEnabled = tradingEnabled;
        bool areMeet = !liquidating && tradingIsEnabled;
        bool hasContracts = users[from].automatedMarketMakerPairs || users[to].automatedMarketMakerPairs;
        // only whitelisted addresses can make transfers before trading start.
        if (!tradingIsEnabled) {
            //turn transfer on to allow for whitelist form/mutlisend presale
            require(users[from].canTransferBeforeTradingIsEnabled, "Trading is not enabled");
        }

        if (hasContracts) {
            // excluded from fees
            bool exclusionConditions =
            (
                (users[from].isExcludedFromFees || users[to].isExcludedFromFees)
                // liquidity removing
                || (users[from].automatedMarketMakerPairs && to == address(uniswapV2Router))
                // buys
                || (!isBuysTaxable && users[from].automatedMarketMakerPairs)
            );

            bool takeFee = tradingIsEnabled && !liquidating && !exclusionConditions;
            if (takeFee) {
                uint256 fees = amount * TOTAL_FEES / MILLE;
                amount = amount - fees;

                super._update(from, address(this), fees);
            }

            if (areMeet) {
                uint256 contractTokenBalance = balanceOf(address(this));

                bool canSwap = contractTokenBalance >= liquidateTokensAtAmount;

                if (canSwap && !users[from].automatedMarketMakerPairs) {
                    liquidating = true;

                    swap(contractTokenBalance);

                    liquidating = false;
                }
            }
        }

        super._update(from, to, amount);

        uint256 fromBalance = balanceOf(from);
        uint256 toBalance = balanceOf(to);

        setBalance(from, fromBalance);
        setBalance(to, toBalance);
    }
}
