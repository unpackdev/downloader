// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";
import "./ContractMetadata.sol";

/// @custom:version 1
/// @custom:security-contact security@ikonia.com
contract IkoniaOneoff is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl, ContractMetadata {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private baseURI = "ipfs://";

    constructor(address admin) ERC721("Andrea Pirlo Mural", "APMU") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function safeMint(address receiver, uint256 tokenID, string memory ipfsPath)
        public
        onlyRole(MINTER_ROLE)
    {
        _safeMint(receiver, tokenID);
        _setTokenURI(tokenID, ipfsPath);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenID)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenID);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenID)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenID);
    }

    function _burn(uint256 tokenID) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenID);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}
