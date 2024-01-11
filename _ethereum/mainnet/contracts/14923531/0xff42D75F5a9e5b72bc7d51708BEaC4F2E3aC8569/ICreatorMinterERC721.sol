// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
// (https://github.com/unreal-accelerator/contracts)
pragma solidity ^0.8.9;

import "./IERC165.sol";

/**
 * @title ICreatorMinterERC721
 * @dev Interface for getting the quantity of ERC721 tokens minted by an address
 */

interface ICreatorMinterERC721 is IERC165 {
    function minterCount(address account) external view returns (uint256);

    function totalMinted() external view returns (uint256);
}
