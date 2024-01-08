// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "./IERC721.sol";

interface ITux is IERC721 {
    function tokenCreator(uint256 tokenId) external view returns (address);
    function getCreatorTokens(address creator) external view returns (uint256[] memory);
}
