// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IScrollMessenger.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Receives updates from L1 on the canonical rETH exchange rate
contract RocketScrollPriceOracle {
    // Events
    event RateUpdated(uint256 rate);

    // Immutables
    IScrollMessenger internal immutable scrollMessenger;

    /// @notice The rETH exchange rate in the form of how much ETH 1 rETH is worth
    uint256 public rate;

    /// @notice The timestamp of the block in which the rate was last updated
    uint256 public lastUpdated;

    /// @notice Set to the contract on L1 that has permission to update the rate
    address public owner;

    constructor(address _scrollMessenger) {
        scrollMessenger = IScrollMessenger(_scrollMessenger);
        owner = msg.sender;
    }

    /// @notice Hands ownership to the L1 price messenger contract
    function setOwner(address _newOwner) external {
        require(msg.sender == owner, "Only owner");
        owner = _newOwner;
    }

    /// @notice Called by the messenger contract on L1 to update the exchange rate
    function updateRate(uint256 _newRate) external {
        // Only calls originating from L1 owner can update the rate
        require(
            msg.sender == address(scrollMessenger)
            && scrollMessenger.xDomainMessageSender() == owner,
            "Only owner"
        );
        // Set rate and last updated timestamp
        rate = _newRate;
        lastUpdated = block.timestamp;
        // Emit event
        emit RateUpdated(_newRate);
    }
}
