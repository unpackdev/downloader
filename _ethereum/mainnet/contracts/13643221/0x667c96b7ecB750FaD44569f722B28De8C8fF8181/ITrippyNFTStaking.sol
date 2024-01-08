// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface ITrippyNFTStaking {
    struct UserInfo {
        mapping(uint256 => bool) isStaked;
        uint256 rewardDebt;
        uint256 hashes;
    }
    event StakedTrippyNFT(uint256 nftId, address indexed recipient);

    event WithdrawnTrippyNFT(uint256 nftId, address indexed recipient);
    event ClaimTrippyNFT(uint256 pending, address indexed recipient);

    function stake(uint256 _nftId) external;

    function withdraw(uint256 _nftId) external;

    function claim() external;

    function setRewardPerBlock(uint256 _amount) external;
}
