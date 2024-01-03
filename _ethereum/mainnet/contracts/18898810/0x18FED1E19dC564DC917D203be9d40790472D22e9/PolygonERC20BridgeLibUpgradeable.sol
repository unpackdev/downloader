// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "./PolygonBridgeLibUpgradeable.sol";

/**
 * @title PolygonERC20BridgeLibUpgradeable
 * @author sepyke.eth
 * @dev Upgradeable version of PolygonERC20BridgeLib
 *
 * https://github.com/0xPolygonHermez/code-examples/blob/main/customERC20-bridge-example/contracts/lib/PolygonERC20BridgeLib.sol
 */
abstract contract PolygonERC20BridgeLibUpgradeable is
  PolygonBridgeLibUpgradeable
{
  /**
   * Sets bridge values
   * @param _polygonZkEVMBridge Polygon zkEVM bridge address
   * @param _counterpartContract L2 contract address
   * @param _counterpartNetwork Network ID (mainnet=0, zkevm=1)
   */
  function __PolygonERC20BridgeLib_init(
    IPolygonZkEVMBridge _polygonZkEVMBridge,
    address _counterpartContract,
    uint32 _counterpartNetwork
  ) internal onlyInitializing {
    __PolygonBridgeLib_init_unchained(
      _polygonZkEVMBridge, _counterpartContract, _counterpartNetwork
    );
  }

  function __PolygonERC20BridgeLib_init_unchained(
    IPolygonZkEVMBridge _polygonZkEVMBridge,
    address _counterpartContract,
    uint32 _counterpartNetwork
  ) internal onlyInitializing {}

  /**
   * @dev Emitted when bridge tokens to the counterpart network
   */
  event BridgeTokens(address destinationAddress, uint256 amount);

  /**
   * @dev Emitted when claim tokens from the counterpart network
   */
  event ClaimTokens(address destinationAddress, uint256 amount);

  /**
   * @notice Send a message to the bridge that contains the destination address
   * and the token amount
   * The parent contract should implement the receive token protocol and
   * afterwards call this function
   * @param destinationAddress Address destination that will receive the tokens
   * on the other network
   * @param amount Token amount
   * @param forceUpdateGlobalExitRoot Indicates if the global exit root is
   * updated or not
   */
  function bridgeToken(
    address destinationAddress,
    uint256 amount,
    bool forceUpdateGlobalExitRoot
  ) external {
    _receiveTokens(amount);

    // Encode message data
    bytes memory messageData = abi.encode(destinationAddress, amount);

    // Send message data through the bridge
    _bridgeMessage(messageData, forceUpdateGlobalExitRoot);

    emit BridgeTokens(destinationAddress, amount);
  }

  /**
   * @notice Internal function triggered when receive a message
   * @param data message data containing the destination address and the token
   * amount
   */
  function _onMessageReceived(bytes memory data) internal override {
    // Decode message data
    (address destinationAddress, uint256 amount) =
      abi.decode(data, (address, uint256));

    _transferTokens(destinationAddress, amount);
    emit ClaimTokens(destinationAddress, amount);
  }

  /**
   * @dev Handle the reception of the tokens
   * Must be implemented in parent contracts
   */
  function _receiveTokens(uint256 amount) internal virtual;

  /**
   * @dev Handle the transfer of the tokens
   * Must be implemented in parent contracts
   */
  function _transferTokens(address destinationAddress, uint256 amount)
    internal
    virtual;

  // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
  uint256[50] private __gap;
}
