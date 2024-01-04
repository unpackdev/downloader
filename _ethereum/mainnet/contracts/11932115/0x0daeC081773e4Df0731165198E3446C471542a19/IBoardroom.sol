// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IOperator.sol";

interface IBoardroom is IOperator {
    struct Boardseat {
        uint256 rewardClaimed;
        uint256 lastRPS;
        uint256 firstRPS;
        uint256 lastBoardSnapshotIndex;
        // // Pending reward from the previous epochs.
        // uint256 rewardPending;
        // Total reward earned in this epoch.
        uint256 rewardEarnedCurrEpoch;
        // Last time reward was claimed(not bound by current epoch).
        uint256 lastClaimedOn;
        // // The reward claimed in vesting period of this epoch.
        // uint256 rewardClaimedCurrEpoch;
        // // Snapshot of boardroom state when last epoch claimed.
        uint256 lastSnapshotIndex;
        // // Rewards claimable now in the current/next claim.
        // uint256 rewardClaimableNow;
        // // keep track of the current rps
        // uint256 claimedRPS;
    }

    struct BoardSnapshot {
        // Block number when recording a snapshot.
        uint256 number;
        // Block timestamp when recording a snapshot.
        uint256 time;
        // Amount of funds received.
        uint256 rewardReceived;
        // Equivalent amount per share staked.
        uint256 rewardPerShare;
    }

    struct BondingSnapshot {
        uint256 epoch;
        // Time when first bonding was made.
        uint256 when;
        // The snapshot index of when first bonded.
        uint256 balance;
        uint256 valid;
    }

    function allocateSeigniorage(uint256 amount) external;

    function getDirector(address who) external view returns (Boardseat memory);

    function getLastSnapshotIndexOf(address director)
        external
        view
        returns (uint256);
}
