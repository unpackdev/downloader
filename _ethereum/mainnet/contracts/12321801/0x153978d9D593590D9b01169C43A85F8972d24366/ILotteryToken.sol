// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;


interface ILotteryToken {
    struct Lottery {
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        uint256 participants;
        address winner;
        uint256 epochId;
        uint256 winningPrize;
        bool isActive;
    }

    struct Epoch {
        uint256 totalFees;
        uint256 minParticipationFee;
        uint256 firstLotteryId;
        uint256 lastLotteryId;
    }
    
    struct UserBalance {
        uint256 lastGameId;
        uint256 balance;
        uint256 at;
    }

    function lockTransfer() external;
    function unlockTransfer() external;

    function startLottery(uint256 _participationFee) external returns (Lottery memory startedLottery);
    function finishLottery(
        uint256 _participants,
        address _winnerAddress,
        address _marketingAddress,
        uint256 _winningPrizeValue,
        uint256 _marketingFeeValue
    ) external returns (Lottery memory finishedLotteryGame);

    function lastLottery() external view returns (Lottery memory lottery);
    function lastEpoch() external view returns (Epoch memory epoch);
}
