pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

interface InscribeMetaDataInterface {

    /**
     * @dev Emitted when a URI has been added.
     */
    event BaseURIAdded(uint256 indexed baseUriId, string indexed baseUri);
    
    /**
     * @dev Emitted when a URI has been modified.
     */
    event BaseURIModified(uint256 indexed baseURIId, string indexed baseURI);
    
    /**
     * @dev Adds a base URI to the contract state. 
     * This URI can be referenced by the URIId which is emitted from the event.
     * Emits a {BaseURIAdded} event.
     */
    function addBaseURI(string memory baseURI) external;
    
    /**
     * @dev Migrates a base URI. Useful if the base endpoint needs to be adjusted.
     * 
     * Requirements:
     *
     * - `baseUriId` must exist.
     * -  Only the creator of this URI may call this function
     * 
     * Emits a {BaseURIModified} event.
     */
    function migrateBaseURI(uint256 baseUriId, string memory baseURI) external;
    
    /**
     * @dev Fetches the Base URI at `baseUriId`
     * 
     * Requirements:
     *
     * - `baseUriId` baseUri must exist at `baseUriId`
     * 
     */  
    function getBaseURI(uint256 baseUriId) external view returns (string memory baseURI);
}