// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC1155.sol";

interface GatchaItem is IERC1155 {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;
}
