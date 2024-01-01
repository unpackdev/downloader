// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet FeeManagerErrors library
 * @author Dollet Team
 * @notice Library with all FeeManager errors.
 */
library FeeManagerErrors {
    error WrongFeeRecipient(address _recipient);
    error WrongFee(uint16 _fee);
}
