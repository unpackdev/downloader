// SPDX-License-Identifier: MIT
// Written by Divergence (https://twitter.com/divergence_art) and MathsTown (https://twitter.com/MathsTown)
// My thanks to Divergence for his kind assistance.

pragma solidity >=0.8.0 <0.9.0;

import "./BaseOpenSea.sol";
import "./AccessControlEnumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";

///=====UPDATE DEMPLOYMENT WITH NETWORK======

contract MathsTown is AccessControlEnumerable, BaseOpenSea, ERC721Burnable, ERC721Enumerable, ERC721Pausable, ERC721URIStorage {
    /**
     * @dev Allowing more than one address to be able to mint keeps the door
     * open for future drops with collector minting via a proxy contract.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Similarly to MINTER_ROLE, allow for a proxy contract to set a URI
     * upon mint.
     */
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    

    constructor(address proxyRegistryAddress) ERC721("Maths Town", "MATHS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);


        // Allow for gas-free listings on OpenSea.
        _setOpenSeaRegistry(proxyRegistryAddress);
    }

    /**
     * @dev Mint a new token with the specified ID and owner.
     */
    function mint(address to, uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeMint(to, tokenId);
    }

    /**
     * @dev Set the metadata URI for a token.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyRole(URI_SETTER_ROLE) {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Set the metadata URI for a contract.
     */
    function setContractURI(string memory _contractURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setContractURI(_contractURI);
    }
    /**
     * @dev Return owner as fist member of DEFAULT_ADMIN_ROLE (for OpenSea compatibility)
     */
     function owner() public view returns (address) {
         return getRoleMember(DEFAULT_ADMIN_ROLE,0);
     }


    /**
     * @dev Returns the metadata URI as set by setTokenURI().
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    /**
     * @dev Burn a token iff owner is a contract admin AND they meet the
     * requirements of ERC721Burnable (token owner or approved). This stops
     * tokens from being burnt once distributed, while allowing an admin to
     * remove an accidentally created token.
     */
    function burn(uint256 tokenId) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC721Burnable.burn(tokenId);
    }

    /**
     * @dev Pause all token transfers (including minting) in the event of an
     * emergency. This is enforced by ERC721Pausable inheritance.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev As it says on the tin.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /* Necessary overrides from here on. No added functionality. */

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}