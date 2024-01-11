// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC1155Upgradeable.sol";

interface IERC1155Permit is IERC1155Upgradeable {
    function permit(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
