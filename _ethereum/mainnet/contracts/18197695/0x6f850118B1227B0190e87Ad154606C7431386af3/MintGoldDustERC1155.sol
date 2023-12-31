// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./Initializable.sol";
import "./ERC1155Upgradeable.sol";
import "./ERC1155URIStorageUpgradeable.sol";
import "./MintGoldDustCompany.sol";
import "./MintGoldDustNFT.sol";

/// @title A contract responsible by all the operations related with Mint Gold Dust ERC1155 tokens.
/// @notice Contains functions to mint, transfer and burn Mint Gold Dust ERC1155 tokens.
/// @author Mint Gold Dust LLC
/// @custom:contact klvh@mintgolddust.io

contract MintGoldDustERC1155 is
    Initializable,
    ERC1155Upgradeable,
    ERC1155URIStorageUpgradeable,
    MintGoldDustNFT
{
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    /**
     *
     * @notice that the MintGoldDustERC1155 is composed by other contract.
     * @param _mintGoldDustCompany The contract responsible to Mint Gold Dust management features.
     */
    function initializeChild(
        address _mintGoldDustCompany,
        string calldata baseURI
    ) external initializer {
        __ERC1155_init(baseURI);
        __ERC1155URIStorage_init();
        MintGoldDustNFT.initialize(_mintGoldDustCompany);
    }

    /**
     * @dev The transfer function wraps the safeTransferFrom function of ERC1155.
     * @param from Sender of the token.
     * @param to Token destination.
     * @param tokenId ID of the token.
     * @param amount Amount of tokens to be transferred.
     */
    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override nonReentrant {
        safeTransferFrom(from, to, tokenId, amount, "");
    }

    /// @notice that this mapping will return the uri for the respective token id.
    /// @param tokenId is the id of the token.
    function uri(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return super.uri(tokenId);
    }

    /**
     * Mints a new Mint Gold Dust token.
     * @notice Fails if artist is not whitelisted or if the royalty surpass the max royalty limit
     * setted on MintGoldDustCompany smart contract.
     * @dev tokenIdArtist keeps track of the work of each artist and tokenIdRoyaltyPercent the royalty
     * percent for each art work.
     * @param _tokenURI The uri of the token metadata.
     * @param _royaltyPercent The royalty percentage for this art work.
     * @param _amount The amount of tokens to be minted.
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
        _mint(_sender, newTokenId, _amount, "");
        _setURI(newTokenId, _tokenURI);
        tokenIdArtist[newTokenId] = _sender;
        tokenIdRoyaltyPercent[newTokenId] = _royaltyPercent;
        tokenIdMemoir[newTokenId] = _memoir;

        primarySaleQuantityToSold[newTokenId] = _amount;

        emit MintGoldDustNFTMinted(
            newTokenId,
            _tokenURI,
            _sender,
            _royaltyPercent,
            _amount,
            false,
            _collectorMintId,
            _memoir
        );

        return newTokenId;
    }

    /**
     * @dev Allows specified roles to burn a specific amount of a specific token ID.
     *
     * @param tokenId The ID of the token to be burned.
     * @param amount The amount of tokens to be burned.
     *
     * Requirements:
     *
     * - Caller must be either the owner or have been approved to manage the owner's tokens, or be the Mint Gold Dust Owner.
     * - The balance of the `tokenOwner` for the specific `tokenId` should be greater than or equal to the `amount` to be burned.
     * - The token specified by `tokenId` must not have been sold yet.
     *
     * Emits a {TokenBurned} event.
     */
    function burnToken(uint256 tokenId, uint256 amount) external whenNotPaused {
        require(
            // Ensure the caller is either (approved or is the owner) or is the Mint Gold Dust Owner
            isApprovedForAll(tokenIdArtist[tokenId], msg.sender) ||
                tokenIdArtist[tokenId] == msg.sender ||
                msg.sender == mintGoldDustCompany.owner() ||
                mintGoldDustCompany.isAddressValidator(msg.sender),
            "Only creator or allowed"
        );

        address tokenOwner = msg.sender;
        if (msg.sender != tokenIdArtist[tokenId]) {
            tokenOwner = tokenIdArtist[tokenId];
        }

        require(
            // Ensure the owner has enough tokens to burn
            balanceOf(tokenOwner, tokenId) >= amount,
            "Insufficient balance to burn"
        );

        require(
            // Ensure the owner has enough tokens to burn
            primarySaleQuantityToSold[tokenId] >= amount,
            "Items sold not possible to burn"
        );

        require(tokenWasSold[tokenId] == false, "Token already sold");

        _burn(tokenOwner, tokenId, amount);
        emit TokenBurned(
            tokenId,
            true,
            tokenIdArtist[tokenId],
            msg.sender,
            amount
        );
    }

    /**
     * @dev Overrides the ERC1155's `_burn` internal function to extend its functionalities.
     *
     * @param account The address of the token owner.
     * @param id The ID of the token to be burned.
     * @param amount The amount of tokens to be burned.
     *
     * Note: This internal function is called by the `burn` function, which takes care of validations like owner checks and sufficient balance checks.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);
    }
}
