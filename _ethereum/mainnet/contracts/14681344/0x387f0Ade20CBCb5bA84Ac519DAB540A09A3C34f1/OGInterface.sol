// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title The interface to access the OG contract
 * @author nfttank.eth
 */
interface OGInterface {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex (address owner, uint256 index) external view returns (uint256);
    function tier(uint256 tokenId) external view returns (string memory);
}