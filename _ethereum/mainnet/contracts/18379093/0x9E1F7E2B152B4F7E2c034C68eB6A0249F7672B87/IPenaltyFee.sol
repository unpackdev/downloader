// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPenaltyFee {
    /**
     * Calculates the penalty fee for the given _amount for a specific _beneficiary.
     */
    function calculate(
        address _beneficiary,
        uint256 _amount,
        address _pool
    ) external view returns (uint256);
}
