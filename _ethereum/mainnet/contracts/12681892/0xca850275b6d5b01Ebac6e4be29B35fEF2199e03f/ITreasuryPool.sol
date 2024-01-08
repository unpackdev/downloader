// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ITreasuryPool {
    function estimateLtokensFor(uint256 amount) external view returns (uint256);

    function estimateUnderlyingAssetsFor(uint256 amount)
        external
        view
        returns (uint256);

    function getTotalUnderlyingAssetAvailable() external view returns (uint256);

    function getUtilisationRate() external view returns (uint256);

    function addLiquidity(uint256 amount) external;

    function loan(uint256 amount) external;

    function removeLiquidity(uint256 amount) external;

    function redeemProviderReward(uint256 fromEpoch, uint256 toEpoch) external;

    function redeemTeamReward(uint256 fromEpoch, uint256 toEpoch) external;

    function repay(uint256 principal, uint256 interest) external;

    event AddLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        address indexed ltokenAddress,
        uint256 underlyingAssetToken,
        uint256 ltokenAmount,
        uint256 timestamp
    );

    event Loan(uint256 amount, address operator, uint256 timestamp);

    event RemoveLiquidity(
        address indexed account,
        address indexed ltokenAddress,
        address indexed underlyingAssetAddress,
        uint256 ltokenToken,
        uint256 underlyingAssetAmount,
        uint256 timestamp
    );

    event RedeemProviderReward(
        address indexed account,
        uint256 indexed fromEpoch,
        uint256 indexed toEpoch,
        address rewardTokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event RedeemTeamReward(
        address indexed account,
        uint256 indexed fromEpoch,
        uint256 indexed toEpoch,
        address rewardTokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event Repay(
        uint256 principal,
        uint256 interest,
        address operator,
        uint256 timestamp
    );
}
