// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721Enumerable.sol";

interface IGenesisBirdez is IERC721Enumerable {
    function owner() external view returns (address);
    function ownerOf() external view returns (address);
    function tokenOfOwnerByIndex() external view returns (address, uint256);
}