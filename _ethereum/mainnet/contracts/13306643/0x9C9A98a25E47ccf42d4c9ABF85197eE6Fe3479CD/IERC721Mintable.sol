// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";

interface IERC721Mintable is IERC721Upgradeable {
    function mint(
        address to,
        uint256 tokenId,
        string calldata uri
    ) external;
}