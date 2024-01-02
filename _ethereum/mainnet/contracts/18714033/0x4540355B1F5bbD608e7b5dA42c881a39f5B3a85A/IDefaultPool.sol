// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolUSDEDebtUpdated(uint256 _USDEDebt);
    event DefaultPoolCollsBalanceUpdated(address[] _collaterals, uint256[] _collAmounts);

    // --- Functions ---
    function sendCollateralToActivePool(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external;

    function increaseUSDEDebt(uint256 _amount) external;

    function decreaseUSDEDebt(uint256 _amount) external;

    function getUSDEDebt() external view returns (uint256);
}
