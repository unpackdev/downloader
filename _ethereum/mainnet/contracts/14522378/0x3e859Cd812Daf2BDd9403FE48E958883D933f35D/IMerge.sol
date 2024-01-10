// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC721.sol";
import "./IERC721Metadata.sol";

interface IMerge is IERC721, IERC721Metadata {
    function getMergeCount(uint256 tokenId) external virtual view returns (uint256 mergeCount);    
    function totalSupply() external virtual view returns (uint256);    
    function massOf(uint256 tokenId) external virtual view returns (uint256);
    function getValueOf(uint256 tokenId) external view virtual returns (uint256 value);
    function exists(uint256 tokenId) external virtual view returns (bool);
    function decodeClassAndMass(uint256 value) external pure returns (uint256, uint256);
    function decodeClass(uint256 value) external pure returns (uint256 class);
    function decodeMass(uint256 value) external pure returns (uint256 mass);
}