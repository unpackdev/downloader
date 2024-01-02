// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event ActivePoolUSDEDebtUpdated(uint256 _USDEDebt);
    event ActivePoolCollBalanceUpdated(
        address _collateral,
        uint256 _amount
    );

    // --- Functions ---
    function sendCollateral(
        address _account,
        address[] memory _collaterals,
        uint256[] memory _colls
    ) external;

    function sendCollFees(
        address[] memory _collaterals,
        uint256[] memory _colls
    ) external;

    function increaseUSDEDebt(uint256 _amount) external;

    function decreaseUSDEDebt(uint256 _amount) external;

    function getUSDEDebt() external view returns (uint256);
}
