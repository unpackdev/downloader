// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ContextMixin.sol";
import "./IMintableERC721.sol";

contract AvatarMinter is Ownable, ContextMixin {
    mapping(uint256 => address) public allocatedAvatars;

    mapping(uint256 => bool) public isMinted;

    IMintableERC721 public netvrkAvatar;

    event AvatarMinted(
        address indexed minter,
        uint256 tokenId
    );

    constructor(address avatarAddress) {
        netvrkAvatar = IMintableERC721(avatarAddress);
    }

    function allocateAvatars(uint256[] calldata tokenIds, address[] calldata addr) external onlyOwner {
        require(tokenIds.length == addr.length, "AvatarMinter: Wrong data format");
        for (uint256 i = 0; i < addr.length; i++) {
            allocatedAvatars[tokenIds[i]] = addr[i];
        }
    }

    function redeemAvatar(uint256 tokenId) public {
        require(isMinted[tokenId] == false, "AvatarMinter: Already Minted");

        address minter = msg.sender;
        require(allocatedAvatars[tokenId] == minter, "AvatarMinter: Not Allocated");

        isMinted[tokenId] = true;

        netvrkAvatar.mint(minter, tokenId);
        emit AvatarMinted(minter, tokenId);
    }

    function batchRedeemAvatars(uint256[] calldata tokenIds) public {
        uint256 tokenId;
        address minter = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            require(isMinted[tokenId] == false, "AvatarMinter: Already Minted");

            require(allocatedAvatars[tokenId] == minter, "AvatarMinter: Not allocated");

            isMinted[tokenId] = true;

            netvrkAvatar.mint(minter, tokenId);
            emit AvatarMinted(minter, tokenId);
        }
    }

    function _updateAddresses(address avatarAddress)
        external
        onlyOwner
    {
        netvrkAvatar = IMintableERC721(avatarAddress);
    }
}
