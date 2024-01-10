// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "./IEscrowTicketer.sol";
import "./ISeenHausNFT.sol";
import "./ISaleEnder.sol";
import "./MarketHandlerBase.sol";

/**
 * @title SaleEnderFacet
 *
 * @notice Handles the operation of Seen.Haus sales.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract SaleEnderFacet is ISaleEnder, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.saleEnderFacet, "Initializer: contract is already initialized");
        mhi.saleEnderFacet = true;
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
        DiamondLib.addSupportedInterface(type(ISaleEnder).interfaceId);
    }

    /**
     * @notice Close out a successfully completed sale.
     *
     * Funds are disbursed as normal. See: {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     * - Sale doesn't exist or hasn't started
     * - There is remaining inventory (remaining supply in case of digital, remaining tickets in the case of physical)
     *
     * Emits a SaleEnded event.
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function closeSale(uint256 _consignmentId)
    external
    override
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the sale exists and can be closed normally
        Sale storage sale = mhs.sales[_consignmentId];
        require(sale.start != 0, "Sale does not exist");
        require(sale.state == State.Running, "Sale isn't currently running");

        // Determine if consignment is physical
        address nft = getMarketController().getNft();
        if (nft == consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(consignment.tokenId)) {

            // Check how many total claims are possible against issued tickets
            address escrowTicketer = getMarketController().getEscrowTicketer(_consignmentId);
            uint256 totalTicketClaimsIssued = IEscrowTicketer(escrowTicketer).getTicketClaimableCount(_consignmentId);

            // Ensure that sale is sold out before allowing closure
            require((consignment.supply - totalTicketClaimsIssued) == 0, "Sale cannot be closed with remaining inventory");

        } else {

            // Ensure that sale is sold out before allowing closure
            require((consignment.supply - consignment.releasedSupply) == 0, "Sale cannot be closed with remaining inventory");   

        }

        // Mark sale as settled
        sale.state = State.Ended;
        sale.outcome = Outcome.Closed;

        // Distribute the funds (handles royalties, staking, multisig, and seller)
        // First nullify pending payout in case of re-entrancy
        getMarketController().setConsignmentPendingPayout(consignment.id, 0);
        disburseFunds(_consignmentId, consignment.pendingPayout);

        // Notify listeners about state change
        emit SaleEnded(_consignmentId, sale.outcome);

    }

    /**
     * @notice Cancel a sale that has remaining inventory.
     *
     * Remaining tokens are returned to seller. If there have been any purchases,
     * the funds are distributed normally.
     *
     * Reverts if:
     * - Caller doesn't have ADMIN role
     * - Sale doesn't exist or has already been settled
     *
     * Emits a SaleEnded event
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function cancelSale(uint256 _consignmentId)
    external
    override
    onlyRoleOrConsignor(ADMIN, _consignmentId)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the sale exists and can canceled
        Sale storage sale = mhs.sales[_consignmentId];
        require(sale.start != 0, "Sale does not exist");
        require(sale.state != State.Ended, "Sale has already been settled");

        // Mark sale as settled
        sale.state = State.Ended;
        sale.outcome = Outcome.Canceled;

        // Determine the amount sold and remaining
        // uint256 remaining = getMarketController().getUnreleasedSupply(_consignmentId);
        // uint256 sold = consignment.supply - remaining;

        uint256 sold;
        uint256 remaining;
        // Determine if consignment is physical
        address nft = getMarketController().getNft();
        if (nft == consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(consignment.tokenId)) {

            // Check how many total claims are possible against issued tickets
            address escrowTicketer = getMarketController().getEscrowTicketer(_consignmentId);
            uint256 totalTicketClaimsIssued = IEscrowTicketer(escrowTicketer).getTicketClaimableCount(_consignmentId);

            // Derive sold & remaining counts
            sold = totalTicketClaimsIssued;
            remaining = consignment.supply - totalTicketClaimsIssued;

        } else {

            // Derive sold & remaining counts
            sold = consignment.releasedSupply;
            remaining = consignment.supply - consignment.releasedSupply;

        }

        // Disburse the funds for the sold items
        if (sold > 0) {
            // First nullify pending payout in case of re-entrancy
            getMarketController().setConsignmentPendingPayout(consignment.id, 0);
            disburseFunds(_consignmentId, consignment.pendingPayout);
        }

        if (remaining > 0) {

            // Transfer the remaining supply back to the seller (for physicals: excludes NFTs that have tickets issued for them)
            getMarketController().releaseConsignment(_consignmentId, remaining, consignment.seller);

        }

        // Notify listeners about state change
        emit SaleEnded(_consignmentId, sale.outcome);

    }

}