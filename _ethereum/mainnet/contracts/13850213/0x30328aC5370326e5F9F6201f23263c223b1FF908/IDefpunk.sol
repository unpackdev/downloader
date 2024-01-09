// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IDefpunk is IERC721Enumerable {

  // struct to store each token's traits
  struct Defpunk {
    bool isMale;
    uint8 background;
    uint8 skin;
    uint8 nose;
    uint8 eyes;
    uint8 neck;
    uint8 mouth;
    uint8 ears;
    uint8 hair;
    uint8 mouthAccessory;
    uint8 fusionIndex;
    uint8[3] aged;
  }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function setBaseURI(string memory _baseURI) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function fuseTokens(uint256 fuseTokenId, uint256 burnTokenId, uint256 seed) external;
    function setPaused(bool _paused) external;
    function getBaseURI() external view returns (string memory);
    function getMaxTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (Defpunk memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isMale(uint256 tokenId) external view returns(bool);
}