// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: BLOCKS
/// @author: manifold.xyz

/**
 * IBlocksERC721LazyAllowlist v1.1 - ERC721 Lazy Mint with Allowlist interface + additional Blocks functions
 */
 
interface IBlocksERC721LazyAllowlist {

    /**
     * @dev premints gifted nfts
     */
    function premint(address[] memory to) external;

    /**
     * @dev external mint function 
     */
    function mint(bytes32[] memory merkleProof) external payable;

    /**
     * @dev sets the allowList
     */
    function setAllowList(bytes32 merkleRoot) external;

    /**
     * @dev Set the token uri prefix
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev sets the mint price
     */
    function setMintPrice(uint256 mintPrice) external;

    /**
     * @dev sets the max mints
     */
    function setMaxMints(uint256 maxMints) external;

    /**
     * @dev Withdraw funds from the contract
     */
    function withdraw(address to, uint amount) external;
}
