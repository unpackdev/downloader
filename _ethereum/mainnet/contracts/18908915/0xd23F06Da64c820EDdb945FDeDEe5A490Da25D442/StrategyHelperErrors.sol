// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet StrategyHelperErrors library
 * @author Dollet Team
 * @notice Library with all StrategyHelper errors.
 */
library StrategyHelperErrors {
    error UnderMinimumOutputAmount();
    error ZeroMinimumOutputAmount();
    error WrongSlippageTolerance();
    error ExpiredDeadline();
    error WrongRecipient();
    error UnknownOracle();
    error UnknownPath();
}
