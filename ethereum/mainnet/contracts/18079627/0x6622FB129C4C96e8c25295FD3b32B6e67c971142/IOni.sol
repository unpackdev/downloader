// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

import "./IERC721.sol";

interface IOni is IERC721 {
    function getParent(uint256 tokenId) external view returns (uint256);
    function getParentBatch(uint256 start, uint256 end) external view returns (uint256[] memory);
    function getDepth(uint256 tokenId) external view returns (uint256);
    function mint(address to, uint256 parent, address originalAddress, uint256 originalTokenId) external returns(uint256);
    function getStatus(uint256 tokenId) external view returns (uint256);
    function setStatus(uint256 tokenId, uint256 status) external;
}