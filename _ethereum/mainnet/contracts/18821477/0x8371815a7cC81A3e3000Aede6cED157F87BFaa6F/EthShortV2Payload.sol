// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./AaveGovernanceV2.sol";
import "./GovernanceV3.sol";
import "./GovernanceV3Ethereum.sol";
import "./GovernanceV3Polygon.sol";
import "./GovernanceV3Avalanche.sol";
import "./MiscEthereum.sol";
import "./GovV3Helpers.sol";
import "./ITransparentUpgradeableProxy.sol";

interface IAaveArcTimelock {
  function queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) external;

  function updateEthereumGovernanceExecutor(address ethereumGovernanceExecutor) external;

  function getActionsSetCount() external view returns (uint256);

  function execute(uint256 actionsSetId) external;

  function getDelay() external view returns (uint256);

  function getEthereumGovernanceExecutor() external view returns (address);

  function getCurrentState(uint256 actionsSetId) external view returns (uint8);
}

interface ICrossChainForwarder {
  function execute(address payload) external;
}

/**
 * @title EthShortV2Payload
 * @notice Migrate ethereum executor of the ARC and ecosystem reserve, queue gov v 2.5 execution
 * @author BGD Labs
 **/
contract EthShortV2Payload {
  uint40 public immutable MAINNET_PAYLOAD_ID;
  uint40 public immutable POLYGON_PAYLOAD_ID;
  uint40 public immutable AVALANCHE_PAYLOAD_ID;

  constructor(uint40 mainnetPayloadId, uint40 polygonPayloadId, uint40 avalanchePayloadId) public {
    MAINNET_PAYLOAD_ID = mainnetPayloadId;
    POLYGON_PAYLOAD_ID = polygonPayloadId;
    AVALANCHE_PAYLOAD_ID = avalanchePayloadId;
  }

  function execute() external {
    // migrate ecosystem reserve
    _ecosystemReserve();

    // migrate aave arc gov executor to new gov v3 executor lvl 1
    _migrateArc();

    // call governance 2.5
    _forwardToGovernance2_5();
  }

  function _ecosystemReserve() internal {
    IOwnable(address(MiscEthereum.AAVE_ECOSYSTEM_RESERVE_CONTROLLER)).transferOwnership(
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );
    ITransparentUpgradeableProxy(MiscEthereum.ECOSYSTEM_RESERVE).changeAdmin(
      MiscEthereum.PROXY_ADMIN
    );
  }

  function _migrateArc() internal {
    address[] memory targets = new address[](1);
    targets[0] = AaveGovernanceV2.ARC_TIMELOCK;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'updateEthereumGovernanceExecutor(address)';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encode(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    // create payload for arc timelock
    IAaveArcTimelock(AaveGovernanceV2.ARC_TIMELOCK).queue(
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls
    );
  }

  function _forwardToGovernance2_5() internal {
    PayloadsControllerUtils.Payload[] memory payloads = new PayloadsControllerUtils.Payload[](3);

    payloads[0] = PayloadsControllerUtils.Payload({
      chain: 1,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      payloadsController: address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER),
      payloadId: MAINNET_PAYLOAD_ID
    });
    payloads[1] = PayloadsControllerUtils.Payload({
      chain: 137,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      payloadsController: address(GovernanceV3Polygon.PAYLOADS_CONTROLLER),
      payloadId: POLYGON_PAYLOAD_ID
    });
    payloads[2] = PayloadsControllerUtils.Payload({
      chain: 43114,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      payloadsController: address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER),
      payloadId: AVALANCHE_PAYLOAD_ID
    });

    for (uint256 i = 0; i < payloads.length; i++) {
      IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE)).forwardPayloadForExecution(
        payloads[i]
      );
    }
  }
}
