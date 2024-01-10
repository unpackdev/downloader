// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IEscrowTicketer.sol";
import "./ISaleBuilder.sol";
import "./ISaleHandler.sol";
import "./ISaleRunner.sol";
import "./ISeenHausNFT.sol";
import "./MarketHandlerBase.sol";

/**
 * @title SaleBuilderFacet
 *
 * @notice Handles the operation of Seen.Haus sales.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract SaleBuilderFacet is ISaleBuilder, MarketHandlerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.saleBuilderFacet, "Initializer: contract is already initialized");
        mhi.saleBuilderFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(ISaleBuilder).interfaceId);  // when combined with ISaleRunner ...
        DiamondLib.addSupportedInterface(type(ISaleBuilder).interfaceId ^ type(ISaleRunner).interfaceId); // ... supports ISaleHandler
    }

    /**
     * @notice The sale getter
     */
    function getSale(uint256 _consignmentId)
    external
    override
    view
    returns (Sale memory)
    {
        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Return sale
        return mhs.sales[_consignmentId];
    }

    /**
     * @notice Create a new sale.
     *
     * For some lot size of one ERC-1155 token.
     *
     * Ownership of the consigned inventory is transferred to this contract
     * for the duration of the sale.
     *
     * Reverts if:
     *  - Sale start is zero
     *  - Sale exists for consignment
     *  - Consignment has already been marketed
     *
     * Emits a SalePending event.
     *
     * @param _consignmentId - id of the consignment being sold
     * @param _start - the scheduled start time of the sale
     * @param _price - the price of each item in the lot
     * @param _perTxCap - the maximum amount that can be bought in a single transaction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     */
    function createPrimarySale (
        uint256 _consignmentId,
        uint256 _start,
        uint256 _price,
        uint256 _perTxCap,
        Audience _audience
    )
    external
    override
    onlyRole(SELLER)
    onlyConsignor(_consignmentId)
    {
        require(_start > 0, "_start may not be zero");

        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Fetch the consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the consignment hasn't been marketed
        require(consignment.marketHandler == MarketHandler.Unhandled, "Consignment has already been marketed");

        // Get the storage location for the sale
        Sale storage sale = mhs.sales[consignment.id];

        // Make sure sale doesn't exist (start would always be non-zero on an actual sale)
        require(sale.start == 0, "Sale exists");

        // Set up the sale
        setAudience(_consignmentId, _audience);
        sale.consignmentId = _consignmentId;
        sale.start = _start;
        sale.price = _price;
        sale.perTxCap = _perTxCap;
        sale.state = State.Pending;
        sale.outcome = Outcome.Pending;

        // Notify MarketController the consignment has been marketed
        getMarketController().marketConsignment(consignment.id, MarketHandler.Sale);

        // Notify listeners of state change
        emit SalePending(msg.sender, consignment.seller, sale);
    }

    /**
     * @notice Create a new sale.
     *
     * For some lot size of one ERC-1155 token.
     *
     * Ownership of the consigned inventory is transferred to this contract
     * for the duration of the sale.
     *
     * Reverts if:
     *  - Sale start is zero
     *  - Supply is zero
     *  - Sale exists for consignment
     *  - This contract isn't approved to transfer seller's tokens
     *  - Token contract does not implement either IERC1155 or IERC721
     *
     * Emits a SalePending event.
     *
     * @param _seller - the address that procedes of the sale should go to
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _start - the scheduled start time of the sale
     * @param _supply - the supply of the given consigned token being sold
     * @param _price - the price of each item in the lot
     * @param _perTxCap - the maximum amount that can be bought in a single transaction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     */
    function createSecondarySale (
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _start,
        uint256 _supply,
        uint256 _price,
        uint256 _perTxCap,
        Audience _audience
    )
    external
    override
    {
        // Make sure sale start is not set to zero
        require(_start > 0, "_start may not be zero");

        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Determine if consignment is physical
        address nft = marketController.getNft();
        if (nft == _tokenAddress && ISeenHausNFT(nft).isPhysical(_tokenId)) {
            // Is physical NFT, require that msg.sender has ESCROW_AGENT role
            require(checkHasRole(msg.sender, ESCROW_AGENT), "Physical NFT secondary listings require ESCROW_AGENT role");
        } else if (nft != _tokenAddress) {
            // Is external NFT, require that listing external NFTs is enabled
            bool isEnabled = marketController.getAllowExternalTokensOnSecondary();
            require(isEnabled, "Listing external tokens is not currently enabled");
        }

        // Make sure supply is non-zero
        require (_supply > 0, "Supply must be non-zero");

        // Make sure this contract is approved to transfer the token
        // N.B. The following will work because isApprovedForAll has the same signature on both IERC721 and IERC1155
        require(IERC1155Upgradeable(_tokenAddress).isApprovedForAll(msg.sender, address(this)), "Not approved to transfer seller's tokens");

        // To register the consignment, tokens must first be in MarketController's possession
        if (IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId)) {

            // Ensure seller owns sufficient supply of token
            require(IERC1155Upgradeable(_tokenAddress).balanceOf(msg.sender, _tokenId) >= _supply, "Seller has insufficient balance of token");

            // Transfer supply to MarketController
            IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(getMarketController()),
                _tokenId,
                _supply,
                new bytes(0x0)
            );

        } else {

            require(_supply == 1, "ERC721 listings must use a supply of 1");

            // Token must be a single token NFT
            require(IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC721Upgradeable).interfaceId), "Invalid token type");

            // Transfer tokenId to MarketController
            IERC721Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(getMarketController()),
                _tokenId
            );

        }

        // Register consignment
        Consignment memory consignment = getMarketController().registerConsignment(Market.Secondary, msg.sender, _seller, _tokenAddress, _tokenId, _supply);
        // Secondaries are marketed directly after registration
        getMarketController().marketConsignment(consignment.id, MarketHandler.Sale);

        // Set up the sale
        setAudience(consignment.id, _audience);
        Sale storage sale = mhs.sales[consignment.id];
        sale.consignmentId = consignment.id;
        sale.start = _start;
        sale.price = _price;
        sale.perTxCap = _perTxCap;
        sale.state = State.Pending;
        sale.outcome = Outcome.Pending;

        // Notify listeners of state change
        emit SalePending(msg.sender, consignment.seller, sale);
    }

}