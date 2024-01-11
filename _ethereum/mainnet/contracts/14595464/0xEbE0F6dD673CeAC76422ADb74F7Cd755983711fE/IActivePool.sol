// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IPool.sol";

interface IActivePool is IPool {
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolLUSDDebtUpdated(uint256 _LUSDDebt);
    event ActivePoolETHBalanceUpdated(uint256 _ETH);

    event Repay(address indexed from, uint256 amount);
    event Borrow(address indexed from, uint256 amount);

    // --- Functions ---
    function sendETH(address _account, uint256 _amount) external;

    function receiveETH(uint256 _amount) external;

    function borrow(uint256 amount) external;

    function repay(uint256 amount) external;
}
