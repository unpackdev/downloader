// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, with the optional Metadata and Enumerable extensions
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataEnumerable is IERC721Metadata, IERC721Enumerable {
    
}