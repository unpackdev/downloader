// SPDX-License-Identifier: UNLICENSED
// Author: Kai Aldag <kai.aldag@everyrealm.com>
// Date: June 13th, 2022
// Purpose: Standard interface for Atari GFT's phase 2 Access Pass

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";

interface IAccessPass is IERC1155Upgradeable {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}
