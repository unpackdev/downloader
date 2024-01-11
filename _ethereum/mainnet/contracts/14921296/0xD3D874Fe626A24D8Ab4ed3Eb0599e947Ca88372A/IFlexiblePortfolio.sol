// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "IERC20.sol";
import {IBasePortfolio} from "IBasePortfolio.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";
import {IValuationStrategy} from "IValuationStrategy.sol";

interface IFlexiblePortfolio is IBasePortfolio {
    struct ERC20Metadata {
        string name;
        string symbol;
    }

    struct Strategies {
        address depositStrategy;
        address withdrawStrategy;
        address transferStrategy;
        IValuationStrategy valuationStrategy;
    }

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager,
        uint256 _maxValue,
        Strategies calldata _strategies,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee,
        ERC20Metadata calldata tokenMetadata
    ) external;

    function fundInstrument(IDebtInstrument loans, uint256 instrumentId) external;

    function repay(
        IDebtInstrument loans,
        uint256 instrumentId,
        uint256 amount
    ) external;
}
