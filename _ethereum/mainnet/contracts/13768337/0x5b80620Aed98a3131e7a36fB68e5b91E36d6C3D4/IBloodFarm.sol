// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/// @notice functions that can be called by a game controller
interface IBloodFarm {
    function stakeHuman(address owner, uint16 tokenId) external;

    function claimBloodBags(address sender, uint16 tokenId)
        external
        returns (uint256 owed);

    function requestToUnstakeHuman(address sender, uint16 tokenId) external;

    function unstakeHuman(
        address sender,
        uint16 tokenId
    ) external returns (uint256 owed);

    function isStaked(uint16 tokenId) external view returns (bool);

    function hasRequestedToUnstake(uint16 tokenId) external view returns (bool);

    function ownerOf(uint16 tokenId) external view returns (address);
}
