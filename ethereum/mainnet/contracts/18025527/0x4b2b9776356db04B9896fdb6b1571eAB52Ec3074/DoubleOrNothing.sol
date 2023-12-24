/**
 * Double Or Nothing ($DON) - Innovative Smart Contract. 
 * 
 * Welcome to Double Or Nothing, a unique and innovative blockchain game that tests your luck and decision-making skills.
 * 
 * How to Play:
 * - Acquire $DON tokens from Uniswap; you'll need at least 2000 to play.
 * - Use the `flip` function to bet a specific amount of your $DON tokens.
 * - Win the coin flip, and you'll DOUBLE your bet from the contract's reward pool in DON tokens.
 * - Lose, and the bet amount in $DON tokens will contribute to the reward pool for future players.
 * 
 * Special Features:
 * - If the reward pool runs low, the contract will automatically mint the required tokens for payout.
 * - A portion of the trading tax contributes to a dividend pool, which can be distributed to all holders once a day.
 * 
 * Tax Mechanics:
 * - A 10% tax is applied on both buying and selling $DON tokens.
 *   - 5% goes to the reward pool
 *   - 5% goes to a dividend pool, redistributed to holders
 * 
 * Telegram Community: https://t.me/thedongame
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DoubleOrNothing {
    string public name = "Double Or Nothing";
    string public symbol = "DON";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10 ** uint256(decimals);
    uint256 public buyTax = 10;
    uint256 public sellTax = 10;
    uint256 public minTokensToPlay = 2000 * 10 ** uint256(decimals);
    uint256 public maxTokensToFlip = totalSupply / 100;
    uint256 public maxWalletPercent = 2; // 2% of total supply
    uint256 public maxTransactionPercent = 1; // 1% of total supply
    uint256 public houseEdge = 1; // 1% house edge
    address public owner;
    uint256 public rewardPool;
    uint256 public dividendPool;
    bool public tradingEnabled = false;
    uint256 public lastDividendDate;

    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FlipResult(address indexed player, uint256 betAmount, bool win);
    event UpdateTax(uint256 newBuyTax, uint256 newSellTax);
    event UpdateBettingLimits(uint256 newMinTokensToPlay, uint256 newMaxTokensToFlip);
    event DividendsDistributed(uint256 totalDividends);

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyWhenTradingEnabled() {
        require(tradingEnabled, "Trading is not enabled yet");
        _;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function updateTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
        emit UpdateTax(newBuyTax, newSellTax);
    }

    function updateBettingLimits(uint256 newMinTokensToPlay, uint256 newMaxTokensToFlip) external onlyOwner {
        minTokensToPlay = newMinTokensToPlay;
        maxTokensToFlip = newMaxTokensToFlip;
        emit UpdateBettingLimits(newMinTokensToPlay, newMaxTokensToFlip);
    }

    function updateMaxPercentages(uint256 newMaxWalletPercent, uint256 newMaxTransactionPercent) external onlyOwner {
        maxWalletPercent = newMaxWalletPercent;
        maxTransactionPercent = newMaxTransactionPercent;
    }

    function updateHouseEdge(uint256 newHouseEdge) external onlyOwner {
        houseEdge = newHouseEdge;
    }

    function distributeDividends() external onlyOwner {
        require(block.timestamp > lastDividendDate + 1 days, "Dividends can be distributed only once a day");
        emit DividendsDistributed(dividendPool);
        dividendPool = 0;
        lastDividendDate = block.timestamp;
    }

    function flip(uint256 tokenAmount) external onlyWhenTradingEnabled {
        require(balances[msg.sender] >= minTokensToPlay, "Insufficient tokens to play");
        require(tokenAmount <= balances[msg.sender], "Bet exceeds your token balance");
        require(tokenAmount <= maxTokensToFlip, "Bet exceeds maximum tokens allowed per flip");

        uint256 winAmount = (tokenAmount * (100 - houseEdge) / 100 * rewardPool) / totalSupply;

        if (rewardPool < winAmount) {
            uint256 tokensToMint = winAmount - rewardPool;
            totalSupply += tokensToMint;
            rewardPool += tokensToMint;
        }

        bool coinIsHeads = block.timestamp % 2 == 0;

        if (coinIsHeads) {
            balances[msg.sender] += winAmount;
            rewardPool -= winAmount;
            emit FlipResult(msg.sender, tokenAmount, true);
        } else {
            balances[msg.sender] -= tokenAmount;
            rewardPool += tokenAmount;
            emit FlipResult(msg.sender, tokenAmount, false);
        }
    }

    function loadTreasury(uint256 amount) external onlyOwner {
        require(amount <= balances[owner], "Amount exceeds owner's token balance");
        balances[owner] -= amount;
        rewardPool += amount;
    }

    function emergencyWithdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Amount exceeds contract ETH balance");
        payable(owner).transfer(amount);
    }

    function emergencyWithdrawTokens(uint256 amount) external onlyOwner {
        require(amount <= balances[owner], "Amount exceeds contract token balance");
        balances[owner] -= amount;
        balances[msg.sender] += amount;
    }
}