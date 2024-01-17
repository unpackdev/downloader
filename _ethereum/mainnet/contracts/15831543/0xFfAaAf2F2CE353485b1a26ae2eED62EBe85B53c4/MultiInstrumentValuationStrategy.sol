// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Upgradeable} from "Upgradeable.sol";
import {IValuationStrategy} from "IValuationStrategy.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";
import {IFlexiblePortfolio} from "IFlexiblePortfolio.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";

contract MultiInstrumentValuationStrategy is Upgradeable, IValuationStrategy {
    IDebtInstrument[] public instruments;
    mapping(IDebtInstrument => IValuationStrategy) public strategies;

    modifier onlyPortfolio(IFlexiblePortfolio portfolio) {
        require(msg.sender == address(portfolio), "MultiInstrumentValuationStrategy: Can only be called by portfolio");
        _;
    }

    function initialize(IProtocolConfig _protocolConfig) external initializer {
        __Upgradeable_init(msg.sender, _protocolConfig.pauserAddress());
    }

    function addStrategy(IDebtInstrument instrument, IValuationStrategy strategy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(strategy) != address(0), "MultiInstrumentValuationStrategy: Cannot add address 0 strategy");

        if (address(strategies[instrument]) == address(0)) {
            instruments.push(instrument);
        }
        strategies[instrument] = strategy;
    }

    function onInstrumentFunded(
        IFlexiblePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolio(portfolio) whenNotPaused {
        strategies[instrument].onInstrumentFunded(portfolio, instrument, instrumentId);
    }

    function onInstrumentUpdated(
        IFlexiblePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolio(portfolio) whenNotPaused {
        strategies[instrument].onInstrumentUpdated(portfolio, instrument, instrumentId);
    }

    function getSupportedInstruments() external view returns (IDebtInstrument[] memory) {
        return instruments;
    }

    function calculateValue(IFlexiblePortfolio portfolio) external view returns (uint256) {
        uint256 value = 0;
        for (uint256 i; i < instruments.length; i++) {
            value += strategies[instruments[i]].calculateValue(portfolio);
        }
        return value;
    }
}
