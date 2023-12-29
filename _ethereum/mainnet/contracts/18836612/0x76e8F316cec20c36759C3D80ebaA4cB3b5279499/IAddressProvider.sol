// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IDebtController.sol";

interface IAddressProvider {

    /// @dev Returns the debt controller
    function getDebtController() external view returns (IDebtController);

    /// @dev Returns the fee receiver address
    function getFeeReceiver() external view returns (address);

    /// @dev Returns the WETH address
    function getWethAddress() external view returns (address);
}