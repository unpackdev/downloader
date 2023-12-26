// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract TokenInterface is Ownable{
    IERC1155 public erc1155;
    IERC721 public erc721;

    mapping(uint256 => bool) public usedERC721Tokens;
    mapping(uint256 => uint256) public erc1155TotalBurnCounter;
    mapping(uint256 => uint256) public erc721ToBurnedErc1155;
    mapping(uint256 => uint256) public erc721BurnCount;
    address public gemStash = 0x94112A7B2aE525e9E370e2C2a80Ae3a48b69F780;

    event TokenEvolved(
        address indexed user,
        uint256 burnedErc1155TokenId,
        uint256 usedErc721TokenId
    );

    constructor() {
        erc1155 = IERC1155(0x7cC7ADd921e2222738561D03c89589929ceFcF21);
        erc721 = IERC721(0x80336Ad7A747236ef41F47ed2C7641828a480BAA);
    }

    function updateGemStash(address newGemStash) onlyOwner public {
        gemStash = newGemStash;
    }

    function ownsERC1155TokenView(address user, uint256 tokenId) public view returns (bool) {
        return erc1155.balanceOf(user, tokenId) > 0;
    }

    function ownsERC721View(address user, uint256 tokenId) public view returns (bool) {
        return erc721.ownerOf(tokenId) == user;
    }

    function evolveChimp(uint256 erc1155TokenId, uint256 erc721TokenId) public {
        require(ownsERC1155TokenView(msg.sender, erc1155TokenId), "You don't own the ERC-1155 token");
        require(ownsERC721View(msg.sender, erc721TokenId), "You don't own the ERC-721 token");
        require(erc1155TokenId == 12 || erc1155TokenId == 13 || erc1155TokenId == 14, "Invalid ERC-1155 token ID, you can only burn gems");
        require(!usedERC721Tokens[erc721TokenId], "ERC-721 token has already been used");

        usedERC721Tokens[erc721TokenId] = true;
        erc1155TotalBurnCounter[erc1155TokenId] += 1;

        erc1155.safeTransferFrom(msg.sender, gemStash, erc1155TokenId, 1, "0x");

        emit TokenEvolved(msg.sender, erc1155TokenId, erc721TokenId);
        erc721ToBurnedErc1155[erc721TokenId] = erc1155TokenId;
        erc721BurnCount[erc721TokenId] = erc1155TotalBurnCounter[erc1155TokenId];
    }

    function getBurnInfoForERC1155(uint256 erc1155TokenId) public view returns (uint256 totalBurned) {
        return erc1155TotalBurnCounter[erc1155TokenId];
    }

    function getBurnInfoForERC721(uint256 erc721TokenId) public view returns (uint256 erc1155TokenId, uint256 count) {
        erc1155TokenId = erc721ToBurnedErc1155[erc721TokenId];
        if (erc1155TokenId == 0) {
            return (0, 0);
        }
        return (erc1155TokenId, erc721BurnCount[erc721TokenId]);
    }
}
