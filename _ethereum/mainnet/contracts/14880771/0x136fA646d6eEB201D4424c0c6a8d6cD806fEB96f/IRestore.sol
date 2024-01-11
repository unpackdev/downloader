// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./IERC721.sol";

interface IRestore is IERC721 {

    event ReadyForAuction(address to, uint256 tokenId, string uri);

    event ArtFrozen(address buyer, uint256 indexed tokenId);

    event ArtTransferred(address buyer, uint256 indexed tokenId, bytes data);

    function mintForAuction(address creator, string memory uri) external returns (uint256 tokenId);

    function transferToBuyer(uint256 tokenId, bytes memory data) external;

    function freeze(address buyer, uint256 frozenTokenId) external;

    function auctionable(uint256 tokenId) external returns (bool);
}