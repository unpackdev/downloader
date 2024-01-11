// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC1155Upgradeable.sol";

interface IERC1155Mintable is IERC1155Upgradeable {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;
}
