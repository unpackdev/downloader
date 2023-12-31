// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title ERC721 Mintable - Interface
/// @author akibe

interface IERC721Mintable {
    function mint(address, uint256) external;
    function exists(uint256) external view returns (bool);
}
