// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet OracleErrors library
 * @author Dollet Team
 * @notice Library with all Oracle errors.
 */
library OracleErrors {
    error WrongBalancerPoolTokensNumber();
    error WrongCurvePoolTokenIndex();
    error WrongValidityDuration();
    error WrongTwabPeriod();
    error StalePrice();
}
