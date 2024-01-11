// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
// (https://github.com/unreal-accelerator/contracts)
pragma solidity ^0.8.9;

import "./IERC165.sol";

/**
 * @title ICreatorMintableERC721
 * @dev Interface for a mintable Creator ERC721 with a unique
 * uri for each token
 */

interface ICreatorMintableERC721 is IERC165 {
    function mint(address to, string memory tokenMetadataCID) external;

    function totalSupply() external view returns (uint256);
}
