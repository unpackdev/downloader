// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ==================== MaverickRewardHandler =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini


import "./IMaverickRewardOpenSlim.sol";

contract MaverickRewardHandler {
    /* ================================================== FUNCTIONS ========================================================= */

    /// @notice Function to deposit incentives for one pool 
    /// @param poolAddress Address of liquidity pool
    /// @param gaugeAddress Address of liquidity pool's gauge
    /// @param incentivePoolAddress Contract that handle incentive distribution e.g. Bribe contract
    /// @param incentiveTokenAddress Address of Token that AMO uses as an incentive (e.g. FXS)
    /// @param indexId Pool ID in Votium or Votemarket platforms 
    /// @param amount Amount of incentives to be deposited
    function incentivizePool(
        address poolAddress,
        address gaugeAddress, 
        address incentivePoolAddress, 
        address incentiveTokenAddress,
        uint256 indexId, 
        uint256 amount) external 
    {
        IMaverickRewardOpenSlim rewardContract = IMaverickRewardOpenSlim(incentivePoolAddress);
        uint256 duration = 86400 * 14; // 2 weeks
        rewardContract.notifyAndTransfer(incentiveTokenAddress, amount, duration);
    }
} 
