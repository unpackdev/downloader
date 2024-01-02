// SPDX-License-Identifier: AGPL-3.0-or-later

/// BaseDMACommand.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.22;

import "./RatioUtils.sol";
import "./ICommand.sol";
import "./IServiceRegistry.sol";
import "./ReentrancyGuard.sol";
import "./IOperationExecutorV4.sol";

/**
 * @title BaseDMACommand
 * @dev Abstract contract that serves as the base for DMA based commands.
 * It implements common functionality and error handling for DMA commands.
 */
abstract contract BaseDMACommand is ReentrancyGuard, ICommand {
    // Error declarations
    error EmptyAddress(string name);
    error InvalidTriggerType(uint16 triggerType);
    error CallerNotAutomationBot(address caller);
    error InvalidOperationName(bytes32 operationName);
    error InvalidSelector(bytes4 selector);

    using RatioUtils for uint256;

    address public immutable bot;
    address public immutable self;
    address public immutable weth;
    IOperationExecutorV4 public immutable operationExecutor;

    string private constant AUTOMATION_BOT = "AUTOMATION_BOT_V2";
    string private constant OPERATION_EXECUTOR = "OperationExecutor_4";
    string private constant WETH = "WETH";

    uint256 public constant MIN_ALLOWED_DEVIATION = 50; // corrresponds to 0.5%

    /**
     * @dev Constructor function.
     * @param _serviceRegistry The address of the service registry contract.
     */
    constructor(IServiceRegistry _serviceRegistry) {
        // Validate service registry address
        if (address(_serviceRegistry) == address(0)) {
            revert EmptyAddress("service registry");
        }
        // Get the address of the automation bot from the service registry
        bot = _serviceRegistry.getRegisteredService(AUTOMATION_BOT);
        // Validate automation bot address
        if (bot == address(0)) {
            revert EmptyAddress("bot");
        }

        // Get the address of the operation executor from the service registry
        operationExecutor = IOperationExecutorV4(
            _serviceRegistry.getRegisteredService(OPERATION_EXECUTOR)
        );
        // Validate operation executor address
        if (address(operationExecutor) == address(0)) {
            revert EmptyAddress("operation executor");
        }

        // Get the address of the WETH token from the service registry
        weth = _serviceRegistry.getRegisteredService(WETH);
        // Validate WETH address
        if (weth == address(0)) {
            revert EmptyAddress("weth");
        }
        self = address(this);
    }

    /**
     * @dev Checks if the provided deviation is valid.
     * @param deviation The deviation value to check.
     * @return A boolean indicating whether the deviation is valid or not.
     */
    function _isDeviationValid(uint256 deviation) internal pure returns (bool) {
        return deviation >= MIN_ALLOWED_DEVIATION;
    }

    /**
     * @dev Checks if the provided base fee is valid.
     * @param maxAcceptableBaseFeeInGwei The maximum acceptable base fee in Gwei.
     * @return A boolean indicating whether the base fee is valid or not.
     */
    function _isBaseFeeValid(uint256 maxAcceptableBaseFeeInGwei) internal view returns (bool) {
        return block.basefee <= maxAcceptableBaseFeeInGwei * 1 gwei;
    }

    /**
     * @dev Validates the trigger type. Reverts if that's not the case
     * @param triggerType The actual trigger type.
     * @param expectedTriggerType The expected trigger type.
     */
    function _validateTriggerType(uint16 triggerType, uint16 expectedTriggerType) internal pure {
        if (!_isTriggerTypeValid(triggerType, expectedTriggerType)) {
            revert InvalidTriggerType(triggerType);
        }
    }

    /**
     * @dev Checks if the given trigger type is valid.
     * @param triggerType The trigger type to check.
     * @param expectedTriggerType The expected trigger type.
     * @return A boolean indicating whether the trigger type is valid or not.
     */
    function _isTriggerTypeValid(
        uint16 triggerType,
        uint16 expectedTriggerType
    ) internal pure returns (bool) {
        return triggerType == expectedTriggerType;
    }

    /**
     * @dev Validates the selector. Reverts in case it is not.
     * @param expectedSelector The expected selector.
     * @param executionData The execution data containing the selector.
     */
    function _validateSelector(bytes4 expectedSelector, bytes memory executionData) internal pure {
        bytes4 selector = abi.decode(executionData, (bytes4));
        if (!_isSelectorValid(expectedSelector, selector)) {
            revert InvalidSelector(selector);
        }
    }

    /**
     * @dev Checks if the given selector is valid by comparing it with the expected selector.
     * @param expectedSelector The expected selector.
     * @param selector The selector to be checked.
     * @return A boolean indicating whether the selector is valid or not.
     */
    function _isSelectorValid(
        bytes4 expectedSelector,
        bytes4 selector
    ) internal pure returns (bool) {
        return selector == expectedSelector;
    }

    /**
     * @dev Validates the operation name.
     * @param expectedOpName The expected operation name byte string stored in trigger data.
     * @param actualOpName The actual operation name byte string computed from the calls.
     */
    function _validateOperationName(bytes32 expectedOpName, bytes32 actualOpName) internal pure {
        // Compare the bytes32 form of operation name with the expected operation name (bytes32)
        if (expectedOpName != actualOpName) {
            revert InvalidOperationName(expectedOpName);
        }
    }
}
