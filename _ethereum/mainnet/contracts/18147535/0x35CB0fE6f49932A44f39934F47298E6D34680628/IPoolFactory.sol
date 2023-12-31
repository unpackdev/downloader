// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IQuadPassportStore.sol";

interface IPoolFactory {
  function getPoolSymbol(address currency, address manager) external view returns (string memory);

  function isPool(address pool) external view returns (bool);

  function getPoolsByMarket(address market) external view returns (address[] memory);

  function interestRateModel() external view returns (address);

  function auction() external view returns (address);

  function treasury() external view returns (address);

  function reserveFactor() external view returns (uint256);

  function insuranceFactor() external view returns (uint256);

  function warningUtilization() external view returns (uint256);

  function provisionalRepaymentUtilization() external view returns (uint256);

  function provisionalDefaultUtilization() external view returns (uint256);

  function warningGracePeriod() external view returns (uint256);

  function maxInactivePeriod() external view returns (uint256);

  function periodToStartAuction() external view returns (uint256);

  function owner() external view returns (address);

  function closePool() external;

  function burnStake() external;

  function getPools() external view returns (address[] memory);

  function getKYCAttributes(
    address lender
  ) external returns (IQuadPassportStore.Attribute[] memory, uint256);
}
