// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IKeep3rJob.sol";

interface IKeep3rMeteredJob is IKeep3rJob {
  // Events

  event Keep3rHelperSet(address keep3rHelper);
  event GasBonusSet(uint256 gasBonus);
  event GasMaximumSet(uint256 gasMaximum);
  event GasMultiplierSet(uint256 gasMultiplier);
  event GasMetered(uint256 initialGas, uint256 gasAfterWork, uint256 bonus);

  // Variables

  // solhint-disable-next-line func-name-mixedcase, var-name-mixedcase
  function BASE() external view returns (uint32 _BASE);

  function keep3rHelper() external view returns (address _keep3rHelper);

  function gasBonus() external view returns (uint256 _gasBonus);

  function gasMaximum() external view returns (uint256 _gasMultiplier);

  function gasMultiplier() external view returns (uint256 _gasMultiplier);

  // Methods

  function setKeep3rHelper(address _keep3rHelper) external;

  function setGasBonus(uint256 _gasBonus) external;

  function setGasMaximum(uint256 _gasMaximum) external;

  function setGasMultiplier(uint256 _gasMultiplier) external;
}
