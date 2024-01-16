// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./OwnableUpgradeable.sol";

abstract contract TokenMetadata is OwnableUpgradeable {
    // URI for the actual metadata of the collection
    string public baseURI;

    // file extension of the metadata
    string public baseExtension;

    // delays the revealing of metadata of tokens
    bool public delayReveal;

    // toggle to reveal the actual metadata of the collection
    bool public isRevealed;

    function __TokenMetadata_init() internal onlyInitializing {
        __TokenMetadata_init_unchained();
    }

    function __TokenMetadata_init_unchained() internal onlyInitializing {
        baseExtension = ".json";
    }

    function previewURI() public view returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "/preview.json"))
                : "";
    }

    /***********************************************************************
                                ONLY OWNER FUNCTIONS
     *************************************************************************/

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
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
