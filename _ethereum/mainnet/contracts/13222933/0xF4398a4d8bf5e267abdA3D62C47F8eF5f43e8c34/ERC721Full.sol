//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";

import "./ERC721Ownable.sol";
import "./ERC721WithMinters.sol";
import "./ERC721WithRoyalties.sol";

/// @title ERC721Full
/// @dev This contains all the different overrides needed on
///      ERC721 / Enumerable / URIStorage / Royalties
/// @author Simon Fremaux (@dievardump)
abstract contract ERC721Full is
    ERC721Ownable,
    ERC721Burnable,
    ERC721URIStorage,
    ERC721WithMinters,
    ERC721WithRoyalties
{
    /*
     * bytes4(keccak256('tokenCreator(uint256)')) == 0x40c1a064
     */
    bytes4 private constant _INTERFACE_TOKEN_CREATOR = 0x40c1a064;

    mapping(uint256 => address) private _tokenIdToCreator;

    /// @notice Helper for the owner to add new minter
    /// @dev needs to be owner
    /// @param newMinters list of new minters
    function addMinters(address[] memory newMinters) public onlyOwner {
        _addMinters(newMinters);
    }

    /// @notice Helper for the owner to remove a minter
    /// @dev needs to be owner
    /// @param removedMinters minters to remove
    function removeMinters(address[] memory removedMinters) public onlyOwner {
        for (uint256 i; i < removedMinters.length; i++) {
            _removeMinter(removedMinters[i]);
        }
    }

    /// @notice gets a token creator address
    /// @param tokenId the token id
    /// @return the creator's address
    function tokenCreator(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), 'Unknown token.');
        return _tokenIdToCreator[tokenId];
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721, ERC721WithRoyalties)
        returns (bool)
    {
        return
            // Taking this from FND contract
            // hoping this is what makes OpenSea display the creator's name in the description
            // and not the collection creator's name
            interfaceId == _INTERFACE_TOKEN_CREATOR ||
            // or ERC721Enumerable
            ERC721Enumerable.supportsInterface(interfaceId) ||
            // or Royalties
            ERC721WithRoyalties.supportsInterface(interfaceId);
    }

    /// @inheritdoc	ERC721Ownable
    function isApprovedForAll(address owner_, address operator)
        public
        view
        override(ERC721, ERC721Ownable)
        returns (bool)
    {
        return ERC721Ownable.isApprovedForAll(owner_, operator);
    }

    /// @inheritdoc	ERC721URIStorage
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    /// @inheritdoc	ERC721
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @inheritdoc	ERC721
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        // remove royalties
        _removeRoyalty(tokenId);

        // burn ERC721URIStorage
        ERC721URIStorage._burn(tokenId);
    }

    /// @notice internal helper for add minters batch so it can be used in constructor
    function _addMinters(address[] memory newMinters) internal {
        for (uint256 i; i < newMinters.length; i++) {
            _addMinter(newMinters[i]);
        }
    }

    /// @dev sets a token creator
    /// @param tokenId the token id
    /// @param creator the creator's address
    function _setTokenCreator(uint256 tokenId, address creator) internal {
        _tokenIdToCreator[tokenId] = creator;
    }
}
