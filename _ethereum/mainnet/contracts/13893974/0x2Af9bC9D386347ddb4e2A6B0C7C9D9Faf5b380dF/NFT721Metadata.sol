// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./WethioAdminRole.sol";

/**
 * @notice A mixin to extend the OpenZeppelin metadata implementation.
 */
abstract contract NFT721Metadata is WethioAdminRole, ERC721Upgradeable {
    using StringsUpgradeable for uint256;

    /**
     * @dev Stores hashes minted by a creator to prevent duplicates.
     */
    mapping(address => mapping(string => bool))
        private creatorToIPFSHashToMinted;

    event BaseURIUpdated(string baseURI);
    event TokenUriUpdated(
        uint256 indexed tokenId,
        string indexed indexedTokenUri,
        string tokenPath
    );

    modifier onlyCreatorAndOwner(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender || _isWethioAdmin(),
            "NFT721Creator: Caller does not own the NFT or not the admin"
        );

        _;
    }

    /**
     * @notice Checks if the creator has already minted a given NFT.
     */
    function getHasCreatorMintedTokenUri(
        address creator,
        string memory tokenUri
    ) external view returns (bool) {
        return creatorToIPFSHashToMinted[creator][tokenUri];
    }

    /**
     * @notice Sets the token uri.
     */
    function _setTokenUriPath(uint256 tokenId, string memory _tokenIPFSPath)
        internal
    {
        require(
            bytes(_tokenIPFSPath).length >= 46,
            "NFT721Metadata: Invalid IPFS path"
        );

        require(
            !creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath],
            "NFT721Metadata: NFT was already minted"
        );

        creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath] = true;
        _setTokenURI(tokenId, _tokenIPFSPath);
    }

    function _updateBaseURI(string memory _baseURI) internal {
        _setBaseURI(_baseURI);

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Allows the creator to burn if they currently own the NFT.
     */
    function burn(uint256 tokenId) public onlyCreatorAndOwner(tokenId) {
        _burn(tokenId);
    }

    /**
     * @dev Remove the record when burned.
     */
    function _burn(uint256 tokenId) internal virtual override {
        delete creatorToIPFSHashToMinted[msg.sender][_tokenURIs[tokenId]];

        super._burn(tokenId);
    }

    uint256[1000] private __gap;
}
