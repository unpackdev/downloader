// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.21;

interface ITrait {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function traitToExternalAvatarID(
        uint16 _tokenId
    ) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function onTraitAddedToAvatar(uint16 _tokenId, uint16 _avatarId) external;

    function onAvatarTransfer(
        address _from,
        address _to,
        uint16 _tokenId
    ) external;

    function onTraitRemovedFromAvatar(uint16 _tokenId, address _owner) external;

    function traitToAvatar(uint16) external returns (uint16);

    function mint(uint256 _tokenId, address _to) external;

    function burn(uint16 _tokenId) external;
}
