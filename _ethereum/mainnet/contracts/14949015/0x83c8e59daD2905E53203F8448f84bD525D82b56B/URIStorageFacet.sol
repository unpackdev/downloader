// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./URIStorageLib.sol";
import "./AccessControlModifiers.sol";
import "./PausableModifiers.sol";

contract URIStorageFacet is AccessControlModifiers, PausableModifiers {
    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        external
        onlyOperator
        whenNotPaused
    {
        URIStorageLib.setTokenURI(tokenId, _tokenURI);
    }

    function setFolderStorageBaseURI(string memory _baseURI)
        public
        onlyOperator
        whenNotPaused
    {
        URIStorageLib.setFolderStorageBaseURI(_baseURI);
    }

    function setTokenStorageBaseURI(string memory _baseURI)
        public
        onlyOperator
        whenNotPaused
    {
        URIStorageLib.setTokenStorageBaseURI(_baseURI);
    }

    function lockMetadata() public onlyOwner whenNotPaused {
        URIStorageLib.lockMetadata();
    }

    function metadataLocked() public view returns (bool) {
        return URIStorageLib.uriStorage().metadataLocked;
    }

    function folderStorageBaseURI() public view returns (string memory) {
        return URIStorageLib.uriStorage().folderStorageBaseURI;
    }

    function tokenStorageBaseURI() public view returns (string memory) {
        return URIStorageLib.uriStorage().tokenStorageBaseURI;
    }

    function setTokenURIOverrideSelector(bytes4 selector)
        external
        onlyOwner
        whenNotPaused
    {
        URIStorageLib.setTokenURIOverrideSelector(selector);
    }

    function removeTokenURIOverrideSelector() external onlyOwner whenNotPaused {
        URIStorageLib.removeTokenURIOverrideSelector();
    }

    function tokenURIOverrideSelector() public view returns (bytes4) {
        return URIStorageLib.uriStorage().tokenURIOverrideSelector;
    }
}
