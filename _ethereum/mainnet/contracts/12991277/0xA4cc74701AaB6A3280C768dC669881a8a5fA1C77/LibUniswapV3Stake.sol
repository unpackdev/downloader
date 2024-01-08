// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibUniswapV3Stake {
    struct StakeLiquidity {
        address owner;
        uint256 idIndex;
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
        uint32 startTime;
        uint32 claimedTime;
        uint160 secondsInsideInitial;
        uint160 secondsInsideLast;
        bool claimLock;
        bool withdraw;
    }

    struct StakedTokenAmount {
        uint256 amount;
        uint32 startTime;
        uint32 claimedTime;
        uint256 claimedAmount;
        uint256 nonMiningAmount;
    }

    struct StakedTotalTokenAmount {
        bool staked;
        uint256 totalDepositAmount;
        uint256 totalMiningAmount;
        uint256 totalNonMiningAmount;
    }
}
