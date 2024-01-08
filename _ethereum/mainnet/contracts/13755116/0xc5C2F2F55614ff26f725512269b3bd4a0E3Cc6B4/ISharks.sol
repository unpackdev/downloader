// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface ISharks is IERC721Enumerable {
    // game data storage
    enum SGTokenType {
        MINNOW,
        SHARK,
        ORCA
    }

    struct SGToken {
        SGTokenType tokenType;
        uint8 base;
        uint8 accessory;
    }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint16);
    function getPaidTokens() external view returns (uint16);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getTokenTraits(uint256 tokenId) external view returns (SGToken memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function getTokenType(uint256 tokenId) external view returns(SGTokenType);
}
