// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";

interface INethermorphs is IERC721 {
    function mint(address to, uint regularQty, uint rareQty) external;
    function regularsMinted() external view returns (uint);
    function raresMinted() external view returns (uint);
    function safeTransferFrom(address from, address to, uint256 tokenId) external override;
}
