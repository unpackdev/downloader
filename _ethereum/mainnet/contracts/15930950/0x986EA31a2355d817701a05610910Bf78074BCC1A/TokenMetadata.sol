// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./OwnableUpgradeable.sol";

abstract contract TokenMetadata is OwnableUpgradeable {
    // URI for the actual metadata of the collection
    string public baseURI;

    // URI for the preview metadata for the collection
    string public previewURI;

    // file extension of the metadata
    string public baseExtension;

    // delays the revealing of metadata of tokens
    bool public delayReveal;

    // toggle to reveal the actual metadata of the collection
    bool public isRevealed;

    function __TokenMetadata_init(
        string memory _baseURI,
        string memory _previewURI
    ) internal onlyInitializing {
        __TokenMetadata_init_unchained(_baseURI, _previewURI);
    }

    function __TokenMetadata_init_unchained(
        string memory _baseURI,
        string memory _previewURI
    ) internal onlyInitializing {
        baseExtension = ".json";
        baseURI = _baseURI;
        previewURI = _previewURI;
    }

    /***********************************************************************
                                ONLY OWNER FUNCTIONS
     *************************************************************************/

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setPreviewURI(string memory uri) public onlyOwner {
        previewURI = uri;
    }

    function setBaseExtension(string memory extension) external onlyOwner {
        baseExtension = extension;
    }

    function toggleDelayReveal() external onlyOwner {
        delayReveal = !delayReveal;
    }

    function reveal() external onlyOwner {
        require(delayReveal, "Metadata delayed reveal is not enabled");
        require(!isRevealed, "Metadata has already been revealed");
        isRevealed = true;
    }
}
