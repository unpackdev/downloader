// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import "./IVariableBalanceRecords.sol";

/**
 * @title IVariableBalanceRecordsProvider
 * @notice The variable balance records provider interface
 */
interface IVariableBalanceRecordsProvider {
    /**
     * @notice Getter of the variable balance records contract reference
     * @return The variable balance records contract reference
     */
    function variableBalanceRecords() external returns (IVariableBalanceRecords);
}
