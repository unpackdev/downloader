// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64 {
    function getOriginalTokenId(uint256 editionId) external pure returns (uint256);

    function getEditionTokenId(uint256 id) external pure returns (uint256);

    function getMaxEditions() external view returns (uint256);

    function isEdition(uint256 id) external pure returns (bool);
}
