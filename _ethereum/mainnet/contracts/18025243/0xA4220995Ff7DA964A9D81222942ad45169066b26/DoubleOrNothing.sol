// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Double Or Nothing ($DON) - Innovative Smart Contract.
 * 
 * Welcome to Double Or Nothing, the blockchain game that tests your luck and decision-making skills.
 * 
 * How to Play:
 * - Acquire $DON tokens from Uniswap; you'll need at least 2000 to play.
 * - Use the `flip` function to bet a specific amount of your $DON tokens.
 * - Win the coin flip, and you'll DOUBLE your bet from the contract's reward pool in ETH.
 * - Lose, and the bet amount in $DON tokens will contribute to the reward pool for future players.
 * 
 * Reward Pool Mechanics:
 * - A 10% tax on both buying and selling $DON tokens contributes to the reward pool.
 * - The reward pool also accumulates the $DON tokens from losing bets, making each game more thrilling.
 * 
 * User Experience:
 * - You can interact with the contract directly through Etherscan or other Ethereum-compatible interfaces.
 * 
 * Telegram Community: https://t.me/thedongame
 */

contract DoubleOrNothing {
    string public name = "Double Or Nothing";
    string public symbol = "DON";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10 ** uint256(decimals);
    uint256 public buyTax = 10;
    uint256 public sellTax = 10;
    uint256 public minTokensToPlay = 2000 * 10 ** uint256(decimals);
    uint256 public maxTokensToFlip = totalSupply / 100;
    address public owner;
    uint256 public rewardPool;

    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FlipResult(address indexed player, uint256 betAmount, bool win);
    event UpdateTax(uint256 newBuyTax, uint256 newSellTax);
    event UpdateBettingLimits(uint256 newMinTokensToPlay, uint256 newMaxTokensToFlip);

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Owner can update the tax rates
    function updateTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
        emit UpdateTax(newBuyTax, newSellTax);
    }

    // Update betting limits
    function updateBettingLimits(uint256 newMinTokensToPlay, uint256 newMaxTokensToFlip) external onlyOwner {
        minTokensToPlay = newMinTokensToPlay;
        maxTokensToFlip = newMaxTokensToFlip;
        emit UpdateBettingLimits(newMinTokensToPlay, newMaxTokensToFlip);
    }

    // The flip game function
    function flip(uint256 tokenAmount) external {
        require(balances[msg.sender] >= minTokensToPlay, "Insufficient tokens to play");
        require(tokenAmount <= balances[msg.sender], "Bet exceeds your token balance");
        require(tokenAmount <= maxTokensToFlip, "Bet exceeds maximum tokens allowed per flip");

        bool coinIsHeads = block.timestamp % 2 == 0;

        if (coinIsHeads) {
            uint256 winAmount = (tokenAmount * 2 * rewardPool) / totalSupply;
            payable(msg.sender).transfer(winAmount);
            rewardPool -= winAmount;
            emit FlipResult(msg.sender, tokenAmount, true);
        } else {
            balances[msg.sender] -= tokenAmount;
            rewardPool += tokenAmount;
            emit FlipResult(msg.sender, tokenAmount, false);
        }
    }

    // Load the treasury manually if needed
    function loadTreasury(uint256 amount) external onlyOwner {
        require(amount <= balances[owner], "Amount exceeds owner's token balance");
        balances[owner] -= amount;
        rewardPool += amount;
    }

    // Emergency ETH withdrawal
    function emergencyWithdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Amount exceeds contract ETH balance");
        payable(owner).transfer(amount);
    }

    // Emergency Token withdrawal
    function emergencyWithdrawTokens(uint256 amount) external onlyOwner {
        require(amount <= balances[owner], "Amount exceeds contract token balance");
        balances[owner] -= amount;
        balances[msg.sender] += amount;
    }
}