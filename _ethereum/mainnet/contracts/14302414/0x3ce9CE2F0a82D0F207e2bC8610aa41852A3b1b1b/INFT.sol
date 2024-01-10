// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface INFT {
    function creatorToken(uint256 tokenId) external returns (address);

    function pause() external returns (bool);

    function unpause() external returns (bool);

    function transferOwnership(address newOwner) external;

    function setMarket(address newMarket) external returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}
