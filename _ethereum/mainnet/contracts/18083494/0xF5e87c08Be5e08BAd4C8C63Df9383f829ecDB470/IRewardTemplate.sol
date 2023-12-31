// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AStructs.sol";

interface IRewardTemplate {
    function updateReward(UpdateRewardParam memory param) external payable;

    function claimDaoCreatorReward(
        bytes32 daoId,
        address protocolFeePool,
        address daoCreator,
        uint256 currentRound,
        address token
    )
        external
        returns (uint256 protocolClaimableReward, uint256 daoCreatorClaimableReward);

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 currentRound,
        address token
    )
        external
        returns (uint256 claimableReward);

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 currentRound,
        address token
    )
        external
        returns (uint256 claimableReward);

    function setRewardCheckpoint(bytes32 daoId, int256 mintableRoundDelta) external payable;

    function getRoundReward(bytes32 daoId, uint256 round) external view returns (uint256 rewardAmount);
}
