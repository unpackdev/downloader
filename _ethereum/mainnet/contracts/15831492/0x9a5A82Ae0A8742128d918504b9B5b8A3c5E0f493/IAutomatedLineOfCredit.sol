// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Metadata} from "ERC20.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IPortfolio} from "IPortfolio.sol";
import {IDepositController} from "IDepositController.sol";
import {IWithdrawController} from "IWithdrawController.sol";
import {ITransferController} from "ITransferController.sol";

enum AutomatedLineOfCreditStatus {
    Open,
    Full,
    Closed
}

interface IAutomatedLineOfCredit is IPortfolio {
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
        IERC20Metadata _asset,
        address _borrower,
        uint256 _maxSize,
        InterestRateParameters memory _interestRateParameters,
        IDepositController _depositController,
        IWithdrawController _withdrawController,
        ITransferController _transferController,
        string memory name,
        string memory symbol
    ) external;

    function borrow(uint256 amount) external;

    function repay(uint256 amount) external;
}
