// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Nifty Cannon Types
 *
 * @notice Defines the data types used by the Cannon contract
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract CannonTypes {

    /**
     * @notice Mode of operation
     */
    enum Mode {
        AIRDROP,
        WILLCALL,
        TICKET
    }

    /**
     * @notice Request to fire one or more NFTs out to a single recipient
     */
    struct Volley {
        Mode mode;
        address sender;
        address recipient;
        address tokenContract;
        uint256[] tokenIds;
        uint256[] amounts;
    }

    /**
     * @notice transferable ticket
     */
    struct Ticket {
        address sender;
        address tokenContract;
        uint256 ticketId;
        uint256[] tokenIds;
        uint256[] amounts;
    }
}