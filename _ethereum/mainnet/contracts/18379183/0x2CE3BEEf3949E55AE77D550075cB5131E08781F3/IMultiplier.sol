// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMultiplier {
    /**
     * Applies a multiplier on the _amount, based on the _pool and _beneficiary.
     * The multiplier is not necessarily a constant number, it can be a more complex factor.
     */
    function applyMultiplier(
        uint256 _amount,
        address _beneficiary,
        address _pool
    ) external view returns (uint256);

    function getDurationGroup(uint256 _duration) external view returns (uint8);

    function getDurationMultiplier(uint256 _duration) external view returns (uint256);

    function getMultiplier(address _beneficiary, address _pool) external view returns (uint256);

    function getAmountMultiplier(uint256 _amount) external view returns (uint256);

    function getAmountGroup(uint256 _amount) external view returns (uint8);
}
