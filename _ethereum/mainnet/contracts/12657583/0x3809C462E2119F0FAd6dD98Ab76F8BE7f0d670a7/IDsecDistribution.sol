// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IDsecDistribution {
    function addDsec(address account, uint256 amount) external;

    function hasRedeemedDsec(address account, uint256 epoch)
        external
        view
        returns (bool);

    function hasRedeemedTeamReward(uint256 epoch) external view returns (bool);

    function removeDsec(address account, uint256 amount) external;

    function redeemDsec(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) external returns (uint256);

    function redeemTeamReward(uint256 epoch) external;

    event DsecAdd(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount,
        uint256 timestamp,
        uint256 dsec
    );

    event DsecRemove(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount,
        uint256 timestamp,
        uint256 dsec
    );

    event DsecRedeem(
        address indexed account,
        uint256 indexed epoch,
        uint256 distributionAmount,
        uint256 rewardAmount
    );

    event TeamRewardRedeem(address indexed sender, uint256 indexed epoch);
}
