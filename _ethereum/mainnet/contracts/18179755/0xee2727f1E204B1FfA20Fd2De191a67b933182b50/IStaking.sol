// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStaking {
    function updateRewardRecord(address _token, uint256 _index) external;

    function calculateTotalStakedInfo(
        address _usr
    )
        external
        view
        returns (
            uint256 stakedAmount,
            uint256 withdrawableAmount,
            uint256 penaty
        );

    function users(
        address
    )
        external
        view
        returns (
            uint256 amount,
            uint256 checkpoint,
            uint256 claimedReward,
            uint256 totalclaimed,
            uint256 reward,
            uint256 startTime,
            uint256 withdrawTime,
            bool isActive,
            bool isExists
        );
}
