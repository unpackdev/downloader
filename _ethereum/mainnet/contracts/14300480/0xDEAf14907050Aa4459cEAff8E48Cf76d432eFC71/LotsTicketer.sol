// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./IEscrowTicketer.sol";
import "./ISeenHausNFT.sol";
import "./StringUtils.sol";
import "./MarketClientBase.sol";
import "./LotsTicketerStorage.sol";

/**
 * @title LotsTicketer
 *
 * @notice An escrow ticketer contract implemented with ERC-721.
 *
 * Holders of this ticket have the right to transfer or claim a
 * given number of a physical consignment, escrowed by Seen.Haus.
 *
 * Since this is an ERC721 implementation, the holder must
 * claim, sell, or transfer the entire lot of the ticketed
 * items at once.
 *
 * N.B.: This contract disincentivizes whale behavior, e.g., a person
 * scooping up a bunch of the available items in a multi-edition
 * sale must flip or claim them all at once, not individually.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract LotsTicketer is LotsTicketerStorage, IEscrowTicketer, MarketClientBase, StringUtils, ERC721Upgradeable {

    /**
     * @notice Initializer
     */
    function initialize() external {
        __ERC721_init(NAME, SYMBOL);
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
    function getTicket(uint256 ticketId)
    external
    view
    override
    returns (EscrowTicket memory)
    {
        require(_exists(ticketId), "Ticket does not exist");
        return tickets[ticketId];
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
        return tokenURI(_ticketId);
    }

    /**
     * @notice Get the token URI
     *
     * This method is overrides the Open Zeppelin version, returning
     * a unique endpoint address on the seen.haus site for each token id.
     *
     * ex: tokenId = 12
     * https://seen.haus/ticket/metadata/lots-ticketer/12
     *
     * Tickets are transient and will be burned when claimed to obtain
     * proof of ownership NFTs with their metadata on IPFS as usual.
     *
     * Endpoint should serve metadata with fixed name, description,
     * and image, identifying it as a Seen.Haus Escrow Ticket, and
     * adding these fields, in OpenSea attributes format:
     *
     *  - ticketId
     *  - consignmentId
     *  - tokenAddress
     *  - tokenId
     *  - supply
     *
     * @param _tokenId - the ticket's token id
     * @return tokenURI - the URI for the given token id's metadata
     */
    function tokenURI(uint256 _tokenId)
    public
    pure
    override
    returns (string memory)
    {
        return strConcat(_baseURI(), uintToStr(_tokenId));
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI()
    internal
    pure
    override
    returns (string memory)
    {
        return strConcat(ESCROW_TICKET_URI, "lots-ticketer/");
    }

    /**
     * Mint an escrow ticket
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
        require(consignmentIdToTicketClaimableCount[_consignmentId] <= consignment.supply, "Can't issue more tickets than max possible allowed consignment");

        // Get the ticketed token
        Token memory token = ISeenHausNFT(consignment.tokenAddress).getTokenInfo(consignment.tokenId);

        // Create and store escrow ticket
        uint256 ticketId = nextTicket++;
        EscrowTicket storage ticket = tickets[ticketId];
        ticket.amount = _amount;
        ticket.consignmentId = _consignmentId;
        ticket.id = ticketId;
        ticket.itemURI = token.uri;

        // Mint the ticket and send to the buyer
        _mint(_buyer, ticketId);

        // Notify listeners about state change
        emit TicketIssued(ticketId, _consignmentId, _buyer, _amount);
    }

    /**
      * Claim the escrowed items associated with the ticket.
      *
      * @param _ticketId - the ticket representing the escrowed items
      */
    function claim(uint256 _ticketId)
    external
    override
    {
        require(_exists(_ticketId), "Invalid ticket id");
        require(ownerOf(_ticketId) == msg.sender, "Caller not ticket holder");

        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Get the ticket
        EscrowTicket memory ticket = tickets[_ticketId];

        // Burn the ticket
        _burn(_ticketId);
        delete tickets[_ticketId];

        // Release the consignment to claimant
        marketController.releaseConsignment(ticket.consignmentId, ticket.amount, msg.sender);

        // Notify listeners of state change
        emit TicketClaimed(_ticketId, msg.sender, ticket.amount);

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
    override(ERC721Upgradeable)
    returns (bool)
    {
        return (
            interfaceId == type(IEscrowTicketer).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

}