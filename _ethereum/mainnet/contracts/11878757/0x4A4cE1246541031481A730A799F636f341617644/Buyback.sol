// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IBuyback.sol";
import "./IBuybackInitializer.sol";
import "./ITransferLimiter.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Context.sol";

contract Buyback is Context, IBuyback, IBuybackInitializer, ITransferLimiter {
    event BuybackInitialized(uint256 _totalAmount, uint256 _singleAmount, uint256 _minTokensToHold);
    event SingleBuybackExecuted(address _sender, uint256 _senderRewardAmount, uint256 _buybackAmount);

    using SafeMath for uint256;

    bool private isInitialized;
    address private token;
    address private uniswapRouter;
    address private initializer;
    address private treasury;
    address private weth;
    uint256 private totalBuyback;
    uint256 private singleBuyback;
    uint256 private alreadyBoughtBack;
    uint256 private lastBuybackTimestamp;
    uint256 private nextBuybackTimestamp;
    uint256 private lastBuybackBlockNumber;
    uint256 private lastBuybackAmount;
    uint256 private minTokensToHold;

    constructor(
        address _initializer,
        address _treasury,
        address _weth
    ) public {
        initializer = _initializer;
        treasury = _treasury;
        weth = _weth;
    }

    modifier onlyInitializer() {
        require(msg.sender == initializer, "Only initializer allowed.");
        _;
    }

    modifier initialized() {
        require(isInitialized, "Not initialized.");
        _;
    }

    modifier notInitialized() {
        require(!isInitialized, "Already initialized.");
        _;
    }

    modifier scheduled() {
        require(block.timestamp >= nextBuybackTimestamp, "Not scheduled yet.");
        _;
    }

    modifier available() {
        require(totalBuyback > alreadyBoughtBack, "No more funds available.");
        _;
    }

    modifier enoughTokens() {
        require(IERC20(token).balanceOf(msg.sender) >= minTokensToHold, "Insufficient token balance.");
        _;
    }

    function initializerAddress() external view override returns (address) {
        return initializer;
    }

    function tokenAddress() external view override returns (address) {
        return token;
    }

    function uniswapRouterAddress() external view override returns (address) {
        return uniswapRouter;
    }

    function treasuryAddress() external view override returns (address) {
        return treasury;
    }

    function wethAddress() external view override returns (address) {
        return weth;
    }

    function totalAmount() external view override returns (uint256) {
        return totalBuyback;
    }

    function singleAmount() external view override returns (uint256) {
        return singleBuyback;
    }

    function boughtBackAmount() external view override returns (uint256) {
        return alreadyBoughtBack;
    }

    function lastBuyback() external view override returns (uint256) {
        return lastBuybackTimestamp;
    }

    function nextBuyback() external view override returns (uint256) {
        return nextBuybackTimestamp;
    }

    function getTransferLimitPerETH() external view override returns (uint256) {
        if (block.number != lastBuybackBlockNumber || lastBuybackAmount == 0 || singleBuyback == 0) {
            return 0;
        }
        return lastBuybackAmount.mul(10**18).div(singleBuyback);
    }

    function init(
        address _token,
        address _uniswapRouter,
        uint256 _minTokensToHold
    ) external payable override notInitialized onlyInitializer {
        token = _token;
        uniswapRouter = _uniswapRouter;
        totalBuyback = msg.value;
        singleBuyback = totalBuyback.div(10);
        minTokensToHold = _minTokensToHold;
        updateBuybackTimestamps(true);

        isInitialized = true;
        emit BuybackInitialized(totalBuyback, singleBuyback, minTokensToHold);
    }

    function minTokensForBuybackCall() external view override returns (uint256) {
        return minTokensToHold;
    }

    function buyback() external override scheduled initialized available enoughTokens {
        uint256 fundsLeft = totalBuyback.sub(alreadyBoughtBack);
        uint256 actualBuyback = Math.min(fundsLeft, singleBuyback);

        // send 1% to the sender as a reward for triggering the function
        uint256 senderShare = actualBuyback.div(100);
        _msgSender().transfer(senderShare);

        // buy tokens with other 99% and send them to the treasury address
        uint256 buyShare = actualBuyback.sub(senderShare);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        uint256[] memory amounts =
            IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{ value: buyShare }(
                0,
                path,
                treasury,
                block.timestamp
            );

        alreadyBoughtBack = alreadyBoughtBack.add(actualBuyback);
        lastBuybackBlockNumber = block.number;
        lastBuybackAmount = amounts[amounts.length - 1];
        updateBuybackTimestamps(false);

        emit SingleBuybackExecuted(msg.sender, senderShare, buyShare);
    }

    function updateBuybackTimestamps(bool _isInit) private {
        lastBuybackTimestamp = _isInit ? 0 : block.timestamp;
        nextBuybackTimestamp = (_isInit ? block.timestamp : nextBuybackTimestamp) + 1 days;
    }
}
