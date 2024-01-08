// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./MomentsAdminRole.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC165StorageUpgradeable.sol";

/**
 * @notice A mixin to extend the OpenZeppelin metadata implementation.
 */
abstract contract NFT721Metadata is
    ERC165StorageUpgradeable,
    AccessControlUpgradeable,
    MomentsAdminRole,
    ERC721Upgradeable
{
    using StringsUpgradeable for uint256;

    /**
     * @dev Stores token path to avoid duplication in token uri.
     */
    mapping(string => bool) private tokenUriMinted;

    event BaseURIUpdated(string baseURI);

    modifier onlyCreatorAndOwner(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender || isAdmin(msg.sender),
            "NFT721: Caller does not own the NFT or not the admin"
        );

        _;
    }

    /**
     * @notice Checks if the nft is already minted.
     */
    function getMintedTokenUri(string memory tokenUri)
        external
        view
        returns (bool)
    {
        return tokenUriMinted[tokenUri];
    }

    /**
     * @notice Sets the token path.
     */
    function _setTokenUriPath(uint256 tokenId, string memory tokenUri)
        internal
    {
        require(
            bytes(tokenUri).length > 0,
            "NFT721Metadata: Invalid token path"
        );
        require(
            !tokenUriMinted[tokenUri],
            "NFT721Metadata: NFT was already minted"
        );

        tokenUriMinted[tokenUri] = true;
        _setTokenURI(tokenId, tokenUri);
    }

    /**
     * @notice Updates base uri.
     */
    function _updateBaseURI(string memory _baseURI) internal {
        _setBaseURI(_baseURI);

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Allows the creator or owner to burn if they currently own the NFT.
     */
    function burn(uint256 tokenId) external onlyCreatorAndOwner(tokenId) {
        _burn(tokenId);
    }

    /**
     * @dev Remove the record when burned.
     */
    function _burn(uint256 tokenId) internal virtual override {
        delete tokenUriMinted[_tokenURIs[tokenId]];

        super._burn(tokenId);
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165StorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[1000] private __gap;
}
