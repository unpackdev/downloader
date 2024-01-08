// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CannonTypes.sol";

/**
 * @title Nifty Cannon State
 *
 * @notice Defines the state members maintained by the CannonFacet contract
 *
 * @dev the order of items in this contract must never change, only added to,
 * since this will be behind a proxy and new implementations must extend the
 * previous storage structure to avoid corruption of state data.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract CannonState is CannonTypes {

    /**
     * @notice Non-transferable volleys by recipient address
     */
    mapping(address => Volley[]) public willCallVolleys;

    /**
     * @notice Transferable tickets by ticketId
     */
    mapping(uint256 => Ticket) public transferableTickets;

    /**
     * @dev Since tickets are burned once used, totalSupply cannot be used for new ticket numbers
     */
    uint256 internal nextTicketNumber = 0;

}
