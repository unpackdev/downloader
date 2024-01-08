//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";

interface ISouly is IERC721Upgradeable {
    function mint(address payable creator, address to, bytes32 tokenHash) external returns (uint256);
    function burn(uint256 tokenId) external;
    function creatorOf(uint256 tokenId) external view returns (address payable);
}