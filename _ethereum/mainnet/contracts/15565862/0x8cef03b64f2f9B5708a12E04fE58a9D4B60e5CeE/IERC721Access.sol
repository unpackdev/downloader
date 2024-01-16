// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Access {
    function isLocked(uint256 tokenId) external view returns (bool);
}
