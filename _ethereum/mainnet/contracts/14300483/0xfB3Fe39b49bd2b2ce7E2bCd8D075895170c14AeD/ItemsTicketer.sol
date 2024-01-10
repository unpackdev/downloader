// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";
import "./IEscrowTicketer.sol";
import "./ISeenHausNFT.sol";
import "./StringUtils.sol";
import "./MarketClientBase.sol";
import "./ItemsTicketerStorage.sol";

/**
 * @title ItemsTicketer
 *
 * @notice An IEscrowTicketer contract implemented with ERC-1155.
 *
 * Holders of this style of ticket have the right to transfer or
 * claim a given number of a physical consignment, escrowed by
 * Seen.Haus.
 *
 * Since this is an ERC155 implementation, the holder can
 * sell / transfer part or all of the balance of their ticketed
 * items rather than claim them all.
 *
 * N.B.: This contract supports piece-level reseller behavior,
 * e.g., an entity scooping up a bunch of the available items
 * in a multi-edition sale with the purpose of flipping each
 * item individually to make maximum profit.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract ItemsTicketer is ItemsTicketerStorage, StringUtils, IEscrowTicketer, MarketClientBase, ERC1155Upgradeable {

    /**
     * @notice Initializer
     */
    function initialize()
    public {
        __ERC1155_init(ESCROW_TICKET_URI);
    }

    /**
     * @notice The getNextTicket getter
     * @dev does not increment counter
     */
    function getNextTicket()
    external
    view
    override
    returns (uint256)
    {
        return nextTicket;
    }

    /**
     * @notice Get info about the ticket
     */
    function getTicket(uint256 _ticketId)
    external
    view
    override
    returns (EscrowTicket memory)
    {
        require(_ticketId < nextTicket, "Ticket does not exist");
        return tickets[_ticketId];
    }

    /**
     * @notice Get how many claims can be made using tickets (does not change after ticket burns)
     */
    function getTicketClaimableCount(uint256 _consignmentId)
    external
    view
    override
    returns (uint256)
    {
        return consignmentIdToTicketClaimableCount[_consignmentId];
    }

    /**
     * @notice Gets the URI for the ticket metadata
     *
     * IEscrowTicketer method that normalizes how you get the URI,
     * since ERC721 and ERC1155 differ in approach.
     *
     * @param _ticketId - the token id of the ticket
     */
    function getTicketURI(uint256 _ticketId)
    external
    pure
    override
    returns (string memory)
    {
        return uri(_ticketId);
    }

    /**
     * @notice Get the token URI
     *
     * ex: tokenId = 12
     * https://seen.haus/ticket/metadata/items-ticketer/12
     *
     * @param _tokenId - the ticket's token id
     * @return tokenURI - the URI for the given token id's metadata
     */
    function uri(uint256 _tokenId)
    public
    pure
    override
    returns (string memory)
    {
        string memory base = strConcat(ESCROW_TICKET_URI,  "items-ticketer/");
        return strConcat(base, uintToStr(_tokenId));
    }

    /**
     * Issue an escrow ticket to the buyer
     *
     * For physical consignments, Seen.Haus must hold the items in escrow
     * until the buyer(s) claim them.
     *
     * When a buyer wins an auction or makes a purchase in a sale, the market
     * handler contract they interacted with will call this method to issue an
     * escrow ticket, which is an NFT that can be sold, transferred, or claimed.
     *
     * Reverts if token amount hasn't already been transferred to this contract
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _amount - the amount of the given token to escrow
     * @param _buyer - the buyer of the escrowed item(s) to whom the ticket is issued
     */
    function issueTicket(uint256 _consignmentId, uint256 _amount, address payable _buyer)
    external
    override
    onlyRole(MARKET_HANDLER)
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Fetch consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = marketController.getConsignment(_consignmentId);

        // Make sure amount is non-zero
        require(_amount > 0, "Token amount cannot be zero.");

        consignmentIdToTicketClaimableCount[_consignmentId] += _amount;

        // Make sure that there can't be more tickets issued than the maximum possible consignment allocation
        require(consignmentIdToTicketClaimableCount[_consignmentId] <= consignment.supply, "Can't issue more tickets than max possible allowed for consignment");

        // Get the ticketed token
        Token memory token = ISeenHausNFT(consignment.tokenAddress).getTokenInfo(consignment.tokenId);

        // Create and store escrow ticket
        uint256 ticketId = nextTicket++;
        EscrowTicket storage ticket = tickets[ticketId];
        ticket.amount = _amount;
        ticket.consignmentId = _consignmentId;
        ticket.id = ticketId;
        ticket.itemURI = token.uri;

        // Mint escrow ticket and send to buyer
        _mint(_buyer, ticketId, _amount, new bytes(0x0));

        // Notify listeners about state change
        emit TicketIssued(ticketId, _consignmentId, _buyer, _amount);

    }

    /**
     * Claim escrowed items associated with the ticket.
     *
     * @param _ticketId - the ticket representing the escrowed item(s)
     */
    function claim(uint256 _ticketId) external override
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Make sure the ticket exists
        EscrowTicket memory ticket = tickets[_ticketId];
        require(ticket.id == _ticketId, "Ticket does not exist");

        uint256 amount = balanceOf(msg.sender, _ticketId);
        require(amount > 0, "Caller has no balance for this ticket");

        // Burn the caller's balance
        _burn(msg.sender, _ticketId, amount);

        // Reduce the ticket's amount by the claim amount
        ticket.amount -= amount;

        // When entire supply is claimed and burned, delete the ticket structure
        if (ticket.amount == 0) {
            delete tickets[_ticketId];
        } else {
            tickets[_ticketId] = ticket;
        }

        // Release the consignment to claimant
        marketController.releaseConsignment(ticket.consignmentId, amount, msg.sender);

        // Notify listeners of state change
        emit TicketClaimed(_ticketId, msg.sender, amount);

    }

    /**
     * @notice Implementation of the {IERC165} interface.
     *
     * N.B. This method is inherited from several parents and
     * the compiler cannot decide which to use. Thus, they must
     * be overridden here.
     *
     * if you just call super.supportsInterface, it chooses
     * 'the most derived contract'. But that's not good for this
     * particular function because you may inherit from several
     * IERC165 contracts, and all concrete ones need to be allowed
     * to respond.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable)
    returns (bool)
    {
        return (
            interfaceId == type(IEscrowTicketer).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

}