// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Interface to contract for Universal Minting and Evolution of ERC721 tokens
 * @dev The ERC-165 identifier for this interface is 0x9832f941
 * @author Freeverse.io, www.freeverse.io
 */
interface IERC721Universal {
    /**
     * @notice Event emitted on contract deployment
     * @param newContractAddress the address of the newly deployed contract
     * @param baseURI the baseURI string provided on the deploy transaction
     */
    event NewERC721Universal(address newContractAddress, string baseURI);

    /**
     * @notice Returns the version of the ERC721Universal spec that the contract implements
     * @return the version of the ERC721Universal specification
     */
    function ERC721UniversalVersion() external view returns (uint32);

    /**
     * @notice Returns the baseURI used to create the tokenURI for each asset
     * @dev It must end with a slash "/" so that it concatenates correctly with tokenId
     * @return the baseURI used to create the tokenURI for each asset
     */
    function baseURI() external view returns (string memory);
}
