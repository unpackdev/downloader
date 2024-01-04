// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface ISynthereumFactoryVersioning {
  function setPoolFactory(uint8 version, address poolFactory) external;

  function removePoolFactory(uint8 version) external;

  function setDerivativeFactory(uint8 version, address derivativeFactory)
    external;

  function removeDerivativeFactory(uint8 version) external;

  function getPoolFactoryVersion(uint8 version) external view returns (address);

  function numberOfVerisonsOfPoolFactory() external view returns (uint256);

  function getDerivativeFactoryVersion(uint8 version)
    external
    view
    returns (address);

  function numberOfVerisonsOfDerivativeFactory()
    external
    view
    returns (uint256);
}
