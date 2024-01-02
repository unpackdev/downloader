// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPenaltyFee {
    /**
     * Calculates the penalty fee for the given _amount for a specific _beneficiary.
     */
    function calculate(
        uint256 _amount,
        uint256 _duration,
        address _pool
    ) external view returns (uint256);
}
