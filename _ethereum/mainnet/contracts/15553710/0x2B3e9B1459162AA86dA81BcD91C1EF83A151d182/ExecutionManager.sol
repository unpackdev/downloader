// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./TheExManager.sol";

/**
 * @title ExecutionManager
 * @notice It allows adding/removing execution strategies for trading on the LooksRare exchange.
 */
contract ExecutionManager is TheExManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelistedStrategies;

    event StrategyRemoved(address indexed strategy);
    event StrategyWhitelisted(address indexed strategy);

    //
    // function addStrategy
    //  @Description: Add a strategy
    //  @param address
    //  @return external
    //
    function addStrategy(address strategy) external override onlyOwner {
        require(!_whitelistedStrategies.contains(strategy), "the ex already  whitelisted");
        _whitelistedStrategies.add(strategy);

        emit StrategyWhitelisted(strategy);
    }

    //
    // function removeStrategy
    //  @Description: Remove a strategy
    //  @param address
    //  @return external
    //
    function removeStrategy(address strategy) external override onlyOwner {
        require(_whitelistedStrategies.contains(strategy), "the ex not whitelisted");
        _whitelistedStrategies.remove(strategy);

        emit StrategyRemoved(strategy);
    }

    //
    // function isStrategyWhitelisted
    //  @Description: Confirm strategy has been added to whitelist
    //  @param address
    //  @return external
    //
    function isStrategyWhitelisted(address strategy) external view override returns (bool) {
        return _whitelistedStrategies.contains(strategy);
    }

    //
    // function viewCountWhitelistedStrategies
    //  @Description: Count number of whitelisted strategies
    //  @return external
    //
    function viewCountWhitelistedStrategies() external view override returns (uint256) {
        return _whitelistedStrategies.length();
    }

    //
    // function viewWhitelistedStrategies
    //  @Description: Look through all whitelisted strategies
    //  @param uint256
    //  @param uint256
    //  @return external
    //
    function viewWhitelistedStrategies(uint256 cursor, uint256 size)
        external
        view
        override
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedStrategies.length() - cursor) {
            length = _whitelistedStrategies.length() - cursor;
        }

        address[] memory whitelistedStrategies = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedStrategies[i] = _whitelistedStrategies.at(cursor + i);
        }

        return (whitelistedStrategies, cursor + length);
    }
}
