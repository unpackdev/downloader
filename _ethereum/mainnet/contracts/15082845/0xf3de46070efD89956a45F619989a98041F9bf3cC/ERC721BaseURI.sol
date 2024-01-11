// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";

/// @title Add base uri functionality for the metadata endpoint.
/// @dev Implements a getter and setter for the base uri.
/// @custom:documentation https://roofstock-onchain.gitbook.io/roofstock-ideas/v1/home-ownership-token-genesis#base-uri
abstract contract ERC721BaseURI is Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    string private _baseTokenURI;

    function __ERC721BaseURI_init(string memory baseTokenURI)
        internal
        onlyInitializing
    {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
