// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.21;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional retrieving SVG image extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721GetImageSvg {
    function getTokenImageSvg(uint256 tokenId) external view returns (string memory);
}