// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.4;

interface IYieldFarm {
    enum NftTypes {
        principal,
        bonus
    }

    struct NFTMetadata {
        address token;
        uint256 amount;
        uint256 depositTime;
        uint256 endTime;
        bool claimed;
        NftTypes nftType;
    }

    event StakeEvent(
        address indexed farmer,
        uint256 stakedAmountTokenId,
        uint256 rewardTokenId,
        uint256 amount,
        uint256 interval,
        uint256 reward
    );
    event ClaimEvent(address indexed farmer, uint256 tokenId, uint256 amount);
    event AddRewardEvent(address indexed sender, uint256 amount);
    event RemoveRewardEvent(uint256 amount);
    event MinLockTimeChangedEvent(uint128 value);
    event MaxLockTimeChangedEvent(uint128 value);
    event MultiplierChangedEvent(uint256 multiplier);

    function setup(address eqzYieldNftToken) external;

    function stake(uint256 desiredAmount, uint256 interval) external;

    function claim(uint256 tokenId) external;

    function computeReward(uint256 desiredAmount, uint256 interval)
        external
        view
        returns (uint256 stakeAmount, uint256 rewardAmount);

    function addReward(uint256 amount) external;

    function removeReward(uint256 amount) external;
}
