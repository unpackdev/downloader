// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDebtInstrument} from "IDebtInstrument.sol";
import {IBasePortfolio} from "IBasePortfolio.sol";

interface IValuationStrategy {
    function onInstrumentFunded(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external;

    function onInstrumentUpdated(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external;

    function calculateValue(IBasePortfolio portfolio) external view returns (uint256);
}
