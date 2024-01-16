// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title LimitsVerifier
 * @author NeatFi
 */
contract LimitsVerifier {
    /**
     * @dev Sanity check modifier of the incoming native token amounts.
     * @param _value - the amount in Eth to be checked.
     */
    modifier isWithinLimits(uint256 _value) {
        require(
            _value >= 1000000000,
            "LimitsCheck:isWithinLimits: value is too small."
        );
        require(
            _value <= 1000000000000000000000000000,
            "LimitsCheck:isWithinLimits: value is too large."
        );
        _;
    }
}
