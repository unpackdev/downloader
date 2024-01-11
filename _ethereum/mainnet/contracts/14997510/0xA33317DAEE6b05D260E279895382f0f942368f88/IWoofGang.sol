// SPDX-License-Identifier: MIT
// Creator: The Systango Team

pragma solidity ^0.8.7;

/**
 * @dev Interface of the Entrypass token implementation.
*/

interface IWoofGang {

    // The event emitted when nft will airdrop
    event NFTAirDrop(uint tokenId);

    /**
     * @dev Update the base uri
     */
    function updateBaseURI(string memory newBaseUri) external;

    /**
     * @dev Update the end time
     */
    function updateEndTime(uint256 newMintEndTime) external;
    
    /**
     * @dev Update the mint price
     */
    function updateMintPrice (uint256 newMintPrice) external;

     /**
     * @dev Update Treasury Address
     */
    function updateTreasuryAddress(address newAddress) external;


    /**
     * @dev Mint a new token 
     */
    function mint(uint256 quantity) external;
    
    /**
     * @dev Airdrop the Tokens to assigned address by the owner
     */
    function airDrop(address[] memory account , uint256[] memory amount) external;

    /**
     * @dev Mint the remaining token which is left to mint
     */
    function mintRemainingToOwner(uint amount)external ; 
}