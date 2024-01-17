// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";

contract LOOTaDOGNFT is
    ERC721,
    ERC721Enumerable,
    AccessControl,
    ERC721Burnable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _baseTokenURI;

    constructor(string memory baseURI) ERC721("LOOTaDOG", "LAD") {
        _baseTokenURI = baseURI;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setBaseURI(string calldata baseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function safeMint(address to, uint256 tokenId)
        public
        onlyRole(MINTER_ROLE)
    {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
