// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IHouse is IERC721Enumerable {
    
    // House NFT struct
    struct HouseStruct {
        uint8 roll; //0 - Shack, 1 - Ranch, 2 - Mansion
        uint8 body;
    }

    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function isShack(uint256 tokenId) external view returns(bool);
    function isRanch(uint256 tokenId) external view returns(bool);
    function isMansion(uint256 tokenId) external view returns(bool);
    function getMaxTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (HouseStruct memory);
    function minted() external view returns (uint16);

    function emitShackStakedEvent(address owner, uint256 tokenId) external;
    function emitRanchStakedEvent(address owner, uint256 tokenId) external;
    function emitMansionStakedEvent(address owner, uint256 tokenId) external;

    function emitShackUnStakedEvent(address owner, uint256 tokenId) external;
    function emitRanchUnStakedEvent(address owner, uint256 tokenId) external;
    function emitMansionUnStakedEvent(address owner, uint256 tokenId) external;

}