// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC165.sol";

interface INFTExtension is IERC165 {
}

interface INFTURIExtension is INFTExtension {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
