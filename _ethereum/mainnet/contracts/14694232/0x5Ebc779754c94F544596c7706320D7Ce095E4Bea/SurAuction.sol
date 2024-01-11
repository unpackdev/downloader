// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract SurrivativeAuctions is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    string public baseUri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721_init("Surrivative Auctions", "SURV-AUCTIONS");
        __Ownable_init();
        __UUPSUpgradeable_init();
        baseUri = 'ipfs://QmRcrukMNr42SbLBhw9QPm3qz7pqcJUcH5cgRMB8J3eTdP/';
    }

    function safeMint(address to, uint tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function _baseURI() internal view override returns (string memory){
        return baseUri;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}