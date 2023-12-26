// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./RocketStorageInterface.sol";
import "./RocketNetworkBalancesInterface.sol";
import "./IScrollMessenger.sol";

import "./RocketScrollPriceOracle.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Retrieves the rETH exchange rate from Rocket Pool and submits it to the oracle contract on Scroll
contract RocketScrollPriceMessenger {
    // Immutables
    IScrollMessenger immutable l1ScrollMessenger;
    RocketStorageInterface immutable rocketStorage;
    RocketScrollPriceOracle immutable rocketL2ScrollPriceOracle;
    bytes32 immutable rocketNetworkBalancesKey;

    /// @notice The most recently submitted rate
    uint256 lastRate;

    constructor(RocketStorageInterface _rocketStorage, RocketScrollPriceOracle _rocketL2ScrollPriceOracle, IScrollMessenger _l1ScrollMessenger) {
        rocketStorage = _rocketStorage;
        rocketL2ScrollPriceOracle = _rocketL2ScrollPriceOracle;
        l1ScrollMessenger = _l1ScrollMessenger;
        // Precompute storage key for RocketNetworkBalances address
        rocketNetworkBalancesKey = keccak256(abi.encodePacked("contract.address", "rocketNetworkBalances"));
    }

    /// @notice Returns whether the rate has changed since it was last submitted
    function rateStale() external view returns (bool) {
        return rate() != lastRate;
    }

    /// @notice Returns the calculated rETH exchange rate
    function rate() public view returns (uint256) {
        // Retrieve the inputs from RocketNetworkBalances and calculate the rate
        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(rocketStorage.getAddress(rocketNetworkBalancesKey));
        uint256 supply = rocketNetworkBalances.getTotalRETHSupply();
        if (supply == 0) {
            return 0;
        }
        return 1 ether * rocketNetworkBalances.getTotalETHBalance() / supply;
    }

    /// @notice Submits the current rETH exchange rate to the Scroll cross domain messenger contract
    function submitRate(uint256 _gasLimit) external payable {
        lastRate = rate();
        // Create message payload
        bytes memory message = abi.encodeWithSelector(
            rocketL2ScrollPriceOracle.updateRate.selector,
            lastRate
        );
        // Send the cross chain message
        l1ScrollMessenger.sendMessage{ value: msg.value }(
            address(rocketL2ScrollPriceOracle),
            0,
            message,
            _gasLimit,
            msg.sender
        );
    }
}
