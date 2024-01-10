// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";

/**
 * @title IEscrowTicketer
 *
 * @notice Manages the issue and claim of escrow tickets.
 *
 * The ERC-165 identifier for this interface is: 0x73811679
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IEscrowTicketer {

    event TicketIssued(uint256 ticketId, uint256 indexed consignmentId, address indexed buyer, uint256 amount);
    event TicketClaimed(uint256 ticketId, address indexed claimant, uint256 amount);

    /**
     * @notice The nextTicket getter
     */
    function getNextTicket() external view returns (uint256);

    /**
     * @notice Get info about the ticket
     */
    function getTicket(uint256 _ticketId) external view returns (SeenTypes.EscrowTicket memory);

    /**
     * @notice Get how many claims can be made using tickets (does not change after ticket burns)
     */
    function getTicketClaimableCount(uint256 _consignmentId) external view returns (uint256);

    /**
     * @notice Gets the URI for the ticket metadata
     *
     * This method normalizes how you get the URI,
     * since ERC721 and ERC1155 differ in approach
     *
     * @param _ticketId - the token id of the ticket
     */
    function getTicketURI(uint256 _ticketId) external view returns (string memory);

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
     * @param _consignmentId - the id of the consignment being sold
     * @param _amount - the amount of the given token to escrow
     * @param _buyer - the buyer of the escrowed item(s) to whom the ticket is issued
     */
    function issueTicket(uint256 _consignmentId, uint256 _amount, address payable _buyer) external;

    /**
     * Claim the holder's escrowed items associated with the ticket.
     *
     * @param _ticketId - the ticket representing the escrowed items
     */
    function claim(uint256 _ticketId) external;

}