// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
// (https://github.com/unreal-accelerator/contracts)
pragma solidity ^0.8.9;

/**
 * @title IMinterERC1155
 * @dev Interface for getting the quantity of ERC721 tokens minted by an address
 *
 */

interface IMinterERC1155 {
    function minterCount(address account) external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
