// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./IKeeperIncentive.sol";

/**
 *  @notice Provides modifiers and internal functions for processing keeper incentives
 *  @dev Derived contracts using `KeeperIncentivized` must also inherit `ContractRegistryAccess`
 *   and override `_getContract`.
 */
abstract contract KeeperIncentivized {
  /**
   *  @notice Role ID for KeeperIncentive
   *  @dev Equal to keccak256("KeeperIncentive")
   */
  bytes32 public constant KEEPER_INCENTIVE = 0x35ed2e1befd3b2dcf1ec7a6834437fa3212881ed81fd3a13dc97c3438896e1ba;

  /**
   *  @notice Process the specified incentive with `msg.sender` as the keeper address
   *  @param _contractName bytes32 name of calling contract
   *  @param _index uint8 incentive ID
   */
  modifier keeperIncentive(bytes32 _contractName, uint8 _index) {
    _handleKeeperIncentive(_contractName, _index, msg.sender);
    _;
  }

  /**
   *  @notice Process a keeper incentive
   *  @param _contractName bytes32 name of calling contract
   *  @param _index uint8 incentive ID
   *  @param _keeper address of keeper to reward
   */
  function _handleKeeperIncentive(
    bytes32 _contractName,
    uint8 _index,
    address _keeper
  ) internal {
    _keeperIncentive().handleKeeperIncentive(_contractName, _index, _keeper);
  }

  /**
   *  @notice Return an IKeeperIncentive interface to the registered KeeperIncentive contract
   *  @return IKeeperIncentive keeper incentive interface
   */
  function _keeperIncentive() internal view returns (IKeeperIncentive) {
    return IKeeperIncentive(_getContract(KEEPER_INCENTIVE));
  }

  /**
   *  @notice Get a contract address by name from the contract registry
   *  @param _name bytes32 contract name
   *  @return contract address
   *  @dev Users of this abstract contract should also inherit from `ContractRegistryAccess`
   *   and override `_getContract` in their implementation.
   */
  function _getContract(bytes32 _name) internal view virtual returns (address);
}
