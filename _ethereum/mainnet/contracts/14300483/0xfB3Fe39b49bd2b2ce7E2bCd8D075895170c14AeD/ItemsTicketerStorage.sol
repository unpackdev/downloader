// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";

/**
 * @title ItemsTicketerStorage
 * @notice Splits storage away from the logic in ItemsTicketer.sol for maintainability
 *
 */
contract ItemsTicketerStorage is SeenTypes {

    // Ticket ID => Ticket
    mapping (uint256 => EscrowTicket) internal tickets;
    
    // Consignment ID => Ticket Claimable Count (does not change after ticket burns)
    mapping (uint256 => uint256) internal consignmentIdToTicketClaimableCount;

    /// @dev Next ticket number
    uint256 internal nextTicket;

}