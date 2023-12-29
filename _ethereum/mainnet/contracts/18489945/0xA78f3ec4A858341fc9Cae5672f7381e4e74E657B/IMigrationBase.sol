// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IERC20.sol";
import "./IERC721.sol";

import "./ILoanCore.sol";
import "./IOriginationController.sol";
import "./IFeeController.sol";

import "./IFlashLoanRecipient.sol";

import "./ILoanCoreV2.sol";
import "./IRepaymentControllerV2.sol";

interface IMigrationBase is IFlashLoanRecipient {
    event PausedStateChanged(bool isPaused);

    function flushToken(IERC20 token, address to) external;

    function pause(bool _pause) external;
}
