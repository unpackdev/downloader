// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC165Storage.sol";

interface ERC721CollectionMetadataExtensionInterface {
    function setContractURI(string memory newValue) external;

    function contractURI() external view returns (string memory);
}

/**
 * @dev Extension to allow configuring contract-level collection metadata URI.
 */
abstract contract ERC721CollectionMetadataExtension is
    Ownable,
    ERC165Storage,
    ERC721CollectionMetadataExtensionInterface
{
    string private _contractURI;

    constructor(string memory contractURI_) {
        _contractURI = contractURI_;

        _registerInterface(
            type(ERC721CollectionMetadataExtensionInterface).interfaceId
        );
    }

    // ADMIN

    function setContractURI(string memory newValue) external onlyOwner {
        _contractURI = newValue;
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
