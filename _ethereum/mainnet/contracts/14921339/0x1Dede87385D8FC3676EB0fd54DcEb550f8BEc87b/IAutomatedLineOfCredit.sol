// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "IERC20.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";

enum AutomatedLineOfCreditStatus {
    Open,
    Full,
    Closed
}

interface IAutomatedLineOfCredit {
    struct InterestRateParameters {
        uint32 minInterestRate;
        uint32 minInterestRateUtilizationThreshold;
        uint32 optimumInterestRate;
        uint32 optimumUtilization;
        uint32 maxInterestRate;
        uint32 maxInterestRateUtilizationThreshold;
    }

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _borrower,
        uint256 _maxSize,
        InterestRateParameters memory _interestRateParameters,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        string memory name,
        string memory symbol
    ) external;

    function borrow(uint256 amount) external;

    function repay(uint256 amount) external;
}
