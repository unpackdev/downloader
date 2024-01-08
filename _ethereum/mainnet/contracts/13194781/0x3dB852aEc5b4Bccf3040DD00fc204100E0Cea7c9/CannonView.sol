// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CannonState.sol";
import "./CannonActivity.sol";

/**
 * @title Nifty Cannon View Activity
 *
 * @notice View functions that report to the caller about contract state
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract CannonView is CannonActivity {

    /**
     * @notice Check next ticket number without incrementing.
     * @return ticketId - number to be assigned to the next ticket
     */
    function getNextTicketId() public view returns (uint256 ticketId) {
        ticketId = nextTicketNumber;
    }

    /**
     * @notice Check combined count of Will-call Volleys and Tickets
     * @return count the total number of volleys and tickets awaiting the caller
     */
    function myWillCallCount() public view returns (uint256 count) {
        uint256 volleyCount = willCallVolleys[msg.sender].length;
        uint256 ticketCount = balanceOf(msg.sender);
        count = volleyCount + ticketCount;
    }

    /**
     * @notice Get the caller's will-call volleys
     * @return volleys the volleys awaiting the caller
     */
    function myVolleys() public view returns (Volley[] memory volleys) {
        uint256 volleyCount = willCallVolleys[msg.sender].length;
        volleys = new Volley[](volleyCount);
        if (volleyCount > 0) {
            for (uint256 i = 0; i < volleyCount; i++) {
                Volley memory volley = willCallVolleys[msg.sender][i];
                volleys[i] = volley;
            }
        }
    }

    /**
     * @notice Get the caller's transferable tickets
     * @return tickets the tickets awaiting the caller
     */
    function myTickets() public view returns (Ticket[] memory tickets) {
        uint256 ticketCount = balanceOf(msg.sender);
        tickets = new Ticket[](ticketCount);
        if (ticketCount > 0) {
            for (uint256 i = 0; i < ticketCount; i++) {
                uint256 ticketId = tokenOfOwnerByIndex(msg.sender, i);
                Ticket memory ticket = transferableTickets[ticketId];
                tickets[i] = ticket;
            }
        }
    }

}