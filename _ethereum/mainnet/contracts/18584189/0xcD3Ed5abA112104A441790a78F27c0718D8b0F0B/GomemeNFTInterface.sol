// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface GomemeNFTInterface {
    /** 
     * @dev Event emitted when nft is minted
    */
    event NewNFTMinted(uint256 tokenId);
 
    /**
     * @dev User mint a new NFT for the meme created.
     * @param tokenMetadata The metadata uri for the token id.
     */
    function mint(
        string memory tokenMetadata
    ) external returns (uint256);

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() external;

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() external;
}