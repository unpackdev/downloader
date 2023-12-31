// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IERC721.sol";

interface IERC721PlusInterface is IERC721 {
    function safeMintToken(address to, uint256 tokenId) external;

    function exists(uint256 tokenId) external view returns (bool);
}
