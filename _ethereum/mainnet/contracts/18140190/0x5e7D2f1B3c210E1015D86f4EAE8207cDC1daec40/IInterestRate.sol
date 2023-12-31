// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./DataTypes.sol";

/**
 * @title IInterestRate interface
 * @dev Interface for the calculation of the interest rates
 * @author MetaFire
 */
interface IInterestRate {
  function baseVariableBorrowRate() external view returns (uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    DataTypes.ReserveData memory reserve,
    uint256 availableLiquidity,
    uint256 totalVariableDebt,
    uint256 reserveFactor,
    uint256[4] memory liquidities
  ) external view returns (uint256[4] memory liquidityRates, uint256 variableBorrowRate);

  function calculateInterestRates(
    DataTypes.ReserveData memory reserve,
    address targetMToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  ) external view returns (uint256[4] memory liquidityRates, uint256 variableBorrowRate);
}
