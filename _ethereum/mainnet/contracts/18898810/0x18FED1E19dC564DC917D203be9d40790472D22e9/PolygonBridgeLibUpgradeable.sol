// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "./Initializable.sol";

import "./IPolygonZkEVMBridge.sol";

/**
 * @title PolygonBridgeLibUpgradeable
 * @author sepyke.eth
 * @dev Upgradeable version of PolygonBridgeLib
 *
 * https://github.com/0xPolygonHermez/code-examples/blob/main/customERC20-bridge-example/contracts/lib/PolygonBridgeLib.sol
 */
abstract contract PolygonBridgeLibUpgradeable is Initializable {
  IPolygonZkEVMBridge public polygonZkEVMBridge; // 20 bytes
  address public counterpartContract; // 20 bytes
  uint32 public counterpartNetwork; //

  /**
   * Sets bridge values
   * @param _polygonZkEVMBridge Polygon zkEVM bridge address
   * @param _counterpartContract L2 contract address
   * @param _counterpartNetwork Network ID (mainnet=0, zkevm=1)
   */
  function __PolygonBridgeLib_init(
    IPolygonZkEVMBridge _polygonZkEVMBridge,
    address _counterpartContract,
    uint32 _counterpartNetwork
  ) internal onlyInitializing {
    __PolygonBridgeLib_init_unchained(
      _polygonZkEVMBridge, _counterpartContract, _counterpartNetwork
    );
  }

  function __PolygonBridgeLib_init_unchained(
    IPolygonZkEVMBridge _polygonZkEVMBridge,
    address _counterpartContract,
    uint32 _counterpartNetwork
  ) internal onlyInitializing {
    polygonZkEVMBridge = _polygonZkEVMBridge;
    counterpartContract = _counterpartContract;
    counterpartNetwork = _counterpartNetwork;
  }

  /**
   * @notice Send a message to the bridge
   * @param messageData Message data
   * @param forceUpdateGlobalExitRoot Indicates if the global exit root is
   * updated or not
   */
  function _bridgeMessage(
    bytes memory messageData,
    bool forceUpdateGlobalExitRoot
  ) internal virtual {
    polygonZkEVMBridge.bridgeMessage(
      counterpartNetwork,
      counterpartContract,
      forceUpdateGlobalExitRoot,
      messageData
    );
  }

  /**
   * @notice Function triggered by the bridge once a message is received by the
   * other network
   * @param originAddress Origin address that the message was sended
   * @param originNetwork Origin network that the message was sended ( not
   * usefull for this contract )
   * @param data Abi encoded metadata
   */
  function onMessageReceived(
    address originAddress,
    uint32 originNetwork,
    bytes memory data
  ) external payable {
    // Can only be called by the bridge
    require(
      msg.sender == address(polygonZkEVMBridge),
      "TokenWrapped::PolygonBridgeLib: Not PolygonZkEVMBridge"
    );

    require(
      counterpartContract == originAddress,
      "TokenWrapped::PolygonBridgeLib: Not counterpart contract"
    );
    require(
      counterpartNetwork == originNetwork,
      "TokenWrapped::PolygonBridgeLib: Not counterpart network"
    );

    _onMessageReceived(data);
  }

  /**
   * @dev Handle the data of the message received
   * Must be implemented in parent contracts
   */
  function _onMessageReceived(bytes memory data) internal virtual;

  // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
  uint256[48] private __gap;
}
