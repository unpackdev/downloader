// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./Initializable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./MintGoldDustCompany.sol";
import "./MintGoldDustNFT.sol";

/// @title A contract responsible by all the operations related with Mint Gold Dust ERC721 tokens.
/// @notice Contains functions to mint, transfer and burn Mint Gold Dust ERC721 tokens.
/// @author Mint Gold Dust LLC
/// @custom:contact klvh@mintgolddust.io

contract MintGoldDustERC721 is
    Initializable,
    ERC721URIStorageUpgradeable,
    MintGoldDustNFT
{
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    /**
     *
     * @notice that the MintGoldDustERC721 is composed by other contract.
     * @param _mintGoldDustCompany The contract responsible to Mint Gold Dust management features.
     */
    function initializeChild(
        address _mintGoldDustCompany
    ) external initializer {
        __ERC721_init("Mint Gold Dust NFT", "MGDNFT");
        __ERC721URIStorage_init();
        MintGoldDustNFT.initialize(_mintGoldDustCompany);
    }

    /**
     * @dev the safeTransferFrom function is a function of ERC721. And because of the
     * necessity of call this function from other contract by composition we did need to
     * create this public function.
     * @param _from sender of the token.
     * @param _to token destionation.
     * @param _tokenId id of the token.
     * @param _amount is unused for MintGoldDustERC721.
     */
    function transfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external override nonReentrant {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Internal function to handle the complete flow for minting a new token.
     *
     * @param _tokenURI The URI of the minted token, storing metadata off-chain.
     * @param _royaltyPercent The royalty percentage for the artist.
     * @param _amount The amount of tokens to be minted (for ERC1155 compatibility, set to 1 for ERC721).
     * @param _sender The address of the user who initiates the minting process.
     * @param _collectorMintId The ID associated with the collector mint.
     * @param _memoir Extra data associated with the token.
     *
     * @return newTokenId Returns the newly minted token's ID.
     *
     * Requirements:
     *
     * - `_sender` must not be the zero address.
     *
     * Emits a {MintGoldDustNFTMinted} event.
     */
    function executeMintFlow(
        string calldata _tokenURI,
        uint256 _royaltyPercent,
        uint256 _amount,
        address _sender,
        uint256 _collectorMintId,
        bytes calldata _memoir
    ) internal override isZeroAddress(_sender) returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(_sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        tokenIdArtist[newTokenId] = _sender;
        tokenIdRoyaltyPercent[newTokenId] = _royaltyPercent;
        tokenIdMemoir[newTokenId] = _memoir;

        emit MintGoldDustNFTMinted(
            newTokenId,
            _tokenURI,
            _sender,
            _royaltyPercent,
            1,
            true,
            _collectorMintId,
            _memoir
        );
        return newTokenId;
    }

    /// @dev Allows an approved address or token owner to burn a token.
    /// The function also checks if the token has been previously sold before allowing it to be burned.
    /// Emits a `TokenBurned` event upon successful burn.
    ///
    /// @param tokenId The unique identifier for the token.
    ///
    /// Requirements:
    ///
    /// - `tokenId` must exist.
    /// - The caller must be the owner of `tokenId`, or an approved address for `tokenId`,
    ///   or the owner of the contract, or a validated MintGoldDust address.
    /// - The token specified by `tokenId` must not have been sold previously.
    ///
    /// Events:
    ///
    /// - Emits a `TokenBurned` event containing the tokenId, burn status, sender, and amount.
    function burnToken(uint256 tokenId) external whenNotPaused {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) ||
                msg.sender == mintGoldDustCompany.owner() ||
                mintGoldDustCompany.isAddressValidator(msg.sender),
            "Only creator or allowed"
        );

        require(tokenWasSold[tokenId] == false, "Token already sold");

        _burn(tokenId);
        emit TokenBurned(tokenId, true, tokenIdArtist[tokenId], msg.sender, 1);
    }

    /// @dev Overrides the `_burn` function from `ERC721URIStorageUpgradeable` to perform custom logic, if any.
    /// This is an internal function that is only accessible from within this contract or derived contracts.
    ///
    /// @param tokenId The unique identifier for the token.
    ///
    /// Requirements:
    ///
    /// - `tokenId` must exist.
    ///
    /// Note:
    ///
    /// - As this is an internal function, additional requirements may be imposed by public/external functions
    ///   that call this function. Refer to those for more details.
    function _burn(
        uint256 tokenId
    ) internal override(ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
}
