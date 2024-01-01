// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: VERTICAL.art

struct DropParams {
    uint256 maxSupply;
    uint256 price;
    string uri;
    uint64 startDate;
    uint64 endDate;
}

struct Drop {
    uint256 minted;
    uint256 maxSupply;
    uint256 price;
    string uri;
    uint64 startDate;
    uint64 endDate;
}

interface IDropExtension {
    event DropCreated(uint256 indexed id, address indexed artist);
    event DropUpdated(uint256 indexed id);
    event DropMinted(uint256 indexed id, address indexed buyer, uint256 count);

    function createDrop(DropParams calldata params) external;

    function updateDrop(uint256 id, DropParams calldata params) external;

    function mint(uint256 id, uint16 count) external payable;
}

interface ITokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
