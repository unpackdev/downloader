// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC1155.sol";

/// @title IKeyUniverse1
/// @dev Keys are non-transferable semi-fungible tokens.
interface IKeyUniverse1 is IERC1155 {
    function mint(address to, uint256 tokenId) external;

    function mintBatch(address to, uint256[] memory ids) external;

    function setURIs(
        uint256[] memory tokenIds,
        string[] memory tokenURIs
    ) external;
}
