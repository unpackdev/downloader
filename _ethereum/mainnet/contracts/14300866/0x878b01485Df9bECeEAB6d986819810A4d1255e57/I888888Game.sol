// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface I888888Game {
    function gameDuration() external view returns (uint256);

    function startTime() external view returns (uint256);

    function ticketSize() external view returns (uint256);

    function percentagePrecision() external view returns (uint256);

    function linkFeePercent() external view returns (uint256);

    function houseFeePercent() external view returns (uint256);

    function feePercentage() external view returns (uint256);

    function revenueSplitPercentage() external view returns (uint256);

    function revenueSplitRollThreshold() external view returns (uint256);

    function revenue() external view returns (uint256);

    function totalRevenueSplitShares() external view returns (uint256);

    function feesCollected() external view returns (uint256);

    function bootstrapWinnings() external view returns (uint256);

    function isBootstrapped() external view returns (uint256);

    function currentWinner() external view returns (uint256);

    function winner() external view returns (DiceRoll memory);

    function winningNumber() external view returns (uint256);

    function rollCount() external view returns (uint256);

    function isSingleRollEnabled() external view returns (bool);

    struct DiceRoll {
        // Random number on roll
        uint256 roll;
        // Address of roller
        address roller;
    }

    event LogNewRollRequest(uint256 requestId, address indexed roller);
    event LogOnRollResult(
        uint256 requestId,
        uint256 rollId,
        uint256 roll,
        address indexed roller
    );
    event LogNewCurrentWinner(
        uint256 requestId,
        uint256 rollId,
        uint256 roll,
        address indexed roller
    );
    event LogDiscardedRollResult(
        uint256 requestId,
        uint256 rollId,
        address indexed roller
    );
    event LogGameOver(address indexed winner, uint256 winnings);
    event LogOnCollectRevenueSplit(address indexed user, uint256 split);
    event LogAddToRevenue(uint256 amount);
    event LogToggleEnableSingleRoll(bool enabled);

    // Allows users to collect their share of revenue split after a game is over
    function collectRevenueSplit() external;

    // Roll dice once
    function rollDice() external;

    // Approve WETH once and roll multiple times
    function rollMultipleDice(uint32 times) external;

    // Returns current available fees
    function getFees() external view returns (uint256);

    // Returns revenue split for rollers above 600k
    function getRevenueSplit() external view returns (uint256);

    // Returns whether the game is still running
    function isGameOver() external view returns (bool);

    // Returns whether the game duration has ended
    function hasGameDurationElapsed() external view returns (bool);
}
