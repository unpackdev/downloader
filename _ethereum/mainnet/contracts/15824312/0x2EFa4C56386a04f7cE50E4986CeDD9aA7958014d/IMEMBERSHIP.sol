// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IMEMBERSHIP is IERC165 {

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function nfts_type(uint256 tokenId) external view returns (uint256 tokenType);
    function referees(uint256 tokenId) external view returns (address referee);
}