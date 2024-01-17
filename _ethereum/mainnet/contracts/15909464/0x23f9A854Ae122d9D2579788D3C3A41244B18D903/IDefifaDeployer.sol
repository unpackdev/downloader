// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IJBTiered721DelegateDeployer.sol";
import "./IJBController.sol";
import "./DefifaLaunchProjectData.sol";
import "./DefifaDelegateData.sol";
import "./DefifaTimeData.sol";

interface IDefifaDeployer {
  function SPLIT_PROJECT_ID() external view returns (uint256);

  function SPLIT_DOMAIN() external view returns (uint256);

  function token() external view returns (address);

  function controller() external view returns (IJBController);

  function protocolFeeProjectTokenAccount() external view returns (address);

  function timesFor(uint256 _gameId) external view returns (DefifaTimeData memory);

  function mintDurationOf(uint256 _gameId) external view returns (uint256);

  function startOf(uint256 _gameId) external view returns (uint256);

  function tradeDeadlineOf(uint256 _gameId) external view returns (uint256);

  function endOf(uint256 _gameId) external view returns (uint256);

  function terminalOf(uint256 _gameId) external view returns (IJBPaymentTerminal);

  function distributionLimit(uint256 _gameId) external view returns (uint256);

  function holdFeesDuring(uint256 _gameId) external view returns (bool);

  function currentGamePhaseOf(uint256 _gameId) external view returns (uint256);

  function launchGameWith(
    DefifaDelegateData calldata _delegateData,
    DefifaLaunchProjectData calldata _launchProjectData
  ) external returns (uint256 projectId);

  function queueNextPhaseOf(uint256 _projectId) external returns (uint256 configuration);

  function claimProtocolProjectToken() external;
}
