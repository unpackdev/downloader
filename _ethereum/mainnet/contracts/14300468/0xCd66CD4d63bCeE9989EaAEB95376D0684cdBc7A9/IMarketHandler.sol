// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";

/**
 * @title IMarketHandler
 *
 * @notice Provides no functions, only common events to market handler facets.
 *
 * No ERC-165 identifier for this interface, not checked or supported.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IMarketHandler {

    // Events
    event RoyaltyDisbursed(uint256 indexed consignmentId, address indexed recipient, uint256 amount);
    event EscrowAgentFeeDisbursed(uint256 indexed consignmentId, address indexed recipient, uint256 amount);
    event FeeDisbursed(uint256 indexed consignmentId, address indexed recipient, uint256 amount);
    event PayoutDisbursed(uint256 indexed consignmentId, address indexed recipient, uint256 amount);
    event AudienceChanged(uint256 indexed consignmentId, SeenTypes.Audience indexed audience);
    event EthCredited(address indexed recipient, uint256 amount);

}