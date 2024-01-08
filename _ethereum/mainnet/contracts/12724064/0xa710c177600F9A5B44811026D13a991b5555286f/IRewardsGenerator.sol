// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IRewardsGenerator {
    struct PolicyBookRewardInfo {
        uint256 rewardMultiplier; // includes 5 decimal places
        uint256 totalStaked;
        uint256 startStakeBlock;
        uint256 lastUpdateBlock;
        uint256 cumulativeSum; // includes 100 percentage
        uint256 cumulativeReward;
        uint256 average; // includes 100 percentage
        uint256 toUpdateAverage; // includes 100 percentage
    }

    struct StakeRewardInfo {
        uint256 averageOnStake; // includes 100 percentage
        uint256 aggregatedReward;
        uint256 stakeAmount;
        uint256 stakeBlock;
    }

    /// @notice this function is called every time policybook's DAI to DAIx rate changes
    function updatePolicyBookShare(uint256 newRewardMultiplier) external;

    /// @notice aggregates specified nfts into a single one
    function aggregate(
        address policyBookAddress,
        uint256[] calldata nftIndexes,
        uint256 nftIndexTo
    ) external;

    /// @notice informs generator of stake (rewards)
    function stake(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 amount
    ) external;

    /// @notice returns policybook's APY multiplied by 10**5
    function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

    /// @dev returns PolicyBook reward per block multiplied by 10**25
    function getPolicyBookRewardPerBlock(address policyBookAddress)
        external
        view
        returns (uint256);

    /// @notice returns PolicyBook's staked DAI
    function getStakedPolicyBookDAI(address policyBookAddress) external view returns (uint256);

    /// @notice returns NFT's staked DAI
    function getStakedNFTDAI(uint256 nftIndex) external view returns (uint256);

    /// @notice returns a reward of NFT
    function getReward(address policyBookAddress, uint256 nftIndex)
        external
        view
        returns (uint256);

    /// @notice informs generator of withdrawal (all funds)
    function withdrawFunds(address policyBookAddress, uint256 nftIndex) external returns (uint256);

    /// @notice informs generator of withdrawal (rewards)
    function withdrawReward(address policyBookAddress, uint256 nftIndex)
        external
        returns (uint256);
}
