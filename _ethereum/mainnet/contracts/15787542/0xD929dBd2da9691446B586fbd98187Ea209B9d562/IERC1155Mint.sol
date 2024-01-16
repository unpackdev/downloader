// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155Mint {
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}
