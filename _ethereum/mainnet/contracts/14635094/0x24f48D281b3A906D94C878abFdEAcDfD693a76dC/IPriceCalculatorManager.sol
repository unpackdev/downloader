// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPriceCalculatorManager {
    function addCalculator(address calculator) external;

    function removeCalculator(address calculator) external;

    function isCalculatorAllowed(address calculator) external view returns (bool);

    function viewAllowedCalculators(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountAllowedCalculators() external view returns (uint256);
}