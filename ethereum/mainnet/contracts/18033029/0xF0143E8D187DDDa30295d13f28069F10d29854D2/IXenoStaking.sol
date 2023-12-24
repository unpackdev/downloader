// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC165.sol";

struct Stake {
    uint256 tokenId;
    uint256 ammoWithdrawn;
    uint256 ammoStaked;
    uint256 timeStaked;
    address staker;
}

interface IXenoStaking is IERC165 {

    function stake(uint256 tokenId) external;
    function stakeMany(uint256[] calldata tokenIds) external;
    function unstake(uint256 tokenId) external;
    function unstakeMany(uint256[] calldata tokenIds) external;

    function stakeAmmo(uint256 tokenId, uint256 amount) external;
    function stakeAmmoMany(uint256[] calldata tokenIds, uint256[] calldata amounts) external;
    function unstakeAmmo(uint256 tokenId, uint256 amount) external;
    function unstakeAmmoMany(uint256[] calldata tokenIds, uint256[] calldata amounts) external;
    function withdrawAmmo(uint256 tokenId, uint256 amount) external;
    function withdrawAmmoAndStake(uint256 tokenIdToWithdrawFrom, uint256 amount, uint256 tokenIdToStakeTo) external;

    function addSubscriber(bytes32 _topic, address _subscriber) external;
    function removeSubscriber(bytes32 _topic, address _subscriber) external;

    /** Read */
    function isLegendary(uint256 tokenId) external view returns (bool);
    function ammoRewards(uint256 tokenId) external view returns (uint256);
    function ammoRewardsRemainder(uint256 tokenId) external view returns (uint256);
    function tokenStakedDetails(uint256 tokenId) external view returns (Stake memory);
    function stakedByOwner(address owner) external view returns (uint16[] memory);
    function stakedByOwnerDetails(address owner) external view returns (Stake[] memory);
}
