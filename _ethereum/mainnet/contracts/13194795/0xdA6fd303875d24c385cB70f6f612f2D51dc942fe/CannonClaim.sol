// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CannonActivity.sol";

/**
 * @title Nifty Cannon Claim Activity
 *
 * @notice Activities related to picking up will-call volleys and claiming tickets
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract CannonClaim is CannonActivity {

    /**
     * @notice Claim a specific Volley awaiting the caller.
     * There must be one or more Volleys awaiting the recipient.
     * This contract must already be approved as an operator for the NFTs specified in the Volley.
     * @param _index the index of the volley in the recipient's list of will-call volleys
     */
    function claimVolley(uint256 _index) public returns (bool success) {

        // Verify there are one or more waiting volleys and the specified index is valid
        uint256 length = willCallVolleys[msg.sender].length;
        require(length > 0, "Caller has no volleys to claim.");
        require(_index < length, "Volley index out of bounds.");

        // Get the volley and mark it as AIRDROP mode so it will transfer when processed
        Volley memory volley = willCallVolleys[msg.sender][_index];
        volley.mode = Mode.AIRDROP;
        require(msg.sender == volley.recipient, "Caller not recipient.");

        // If not the last, replace the current volley with the last volley and pop the array
        if (length != _index + 1) {
            willCallVolleys[msg.sender][_index] = willCallVolleys[msg.sender][--length];
        }
        willCallVolleys[msg.sender].pop();

        // Process the volley
        processVolley(volley);
        success = true;
    }

    /**
     * @notice Claim a specific Ticket the caller owns.
     * Caller must own the specified ticket (a "FODDER" NFT).
     * This contract must already be approved as an operator for the NFTs specified in the Volley.
     * @param _ticketId the id of the transferable ticket
     */
    function claimTicket(uint256 _ticketId) public returns (bool success) {

        // Verify that the ticket exists and hasn't been claimed
        require(_ticketId < nextTicketNumber, "Invalid ticket id.");
        require(_exists(_ticketId), "Ticket has already been claimed.");

        // Verify that caller is the holder of the ticket
        require(msg.sender == ownerOf(_ticketId), "Caller is not the owner of the ticket.");

        // Create volley from the ticket
        // 1. mark it as AIRDROP mode so it will transfer when processed
        // 2. set recipient to caller
        Volley memory volley;
        volley.mode = Mode.AIRDROP;
        volley.sender = transferableTickets[_ticketId].sender;
        volley.recipient = msg.sender;
        volley.tokenContract = transferableTickets[_ticketId].tokenContract;
        volley.tokenIds = transferableTickets[_ticketId].tokenIds;

        // Burn the ticket
        burnTicket(_ticketId);

        // Process the volley
        processVolley(volley);
        success = true;
    }

    /**
     * @notice Claim all will-call Volleys awaiting the caller.
     * There must be one or more will-call Volleys awaiting the caller.
     * This contract must already be approved as an operator for the NFTs specified in the Volleys.
     */
    function claimAllVolleys() external {

        // Get the first volley and process it, looping until all volleys are picked up
        while(willCallVolleys[msg.sender].length > 0) {
            claimVolley(0);
        }
    }

    /**
     * @notice Claim all Tickets the caller owns.
     * Caller must own one or more Tickets.
     * This contract must already be approved as an operator for the NFTs specified in the Volley.
     */
    function claimAllTickets() external {

        // Caller must own at least one ticket
        require(balanceOf(msg.sender) > 0, "Caller owns no tickets");

        // Get the first ticket and process it, looping until all volleys are picked up
        while(balanceOf(msg.sender) > 0) {
            claimTicket(tokenOfOwnerByIndex(msg.sender, 0));
        }

    }

}