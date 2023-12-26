// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.22;

import "./IVaultAdmin.sol";
import "./IVaultVersion.sol";
import "./IVaultFee.sol";
import "./IVaultState.sol";
import "./IVaultValidators.sol";
import "./IVaultEnterExit.sol";
import "./IVaultOsToken.sol";
import "./IVaultMev.sol";
import "./IVaultEthStaking.sol";
import "./IMulticall.sol";

/**
 * @title IEthVault
 * @author StakeWise
 * @notice Defines the interface for the EthVault contract
 */
interface IEthVault is
  IVaultAdmin,
  IVaultVersion,
  IVaultFee,
  IVaultState,
  IVaultValidators,
  IVaultEnterExit,
  IVaultOsToken,
  IVaultMev,
  IVaultEthStaking,
  IMulticall
{
  /**
   * @dev Struct for initializing the EthVault contract
   * @param capacity The Vault stops accepting deposits after exceeding the capacity
   * @param feePercent The fee percent that is charged by the Vault
   * @param metadataIpfsHash The IPFS hash of the Vault's metadata file
   */
  struct EthVaultInitParams {
    uint256 capacity;
    uint16 feePercent;
    string metadataIpfsHash;
  }

  /**
   * @notice Initializes the EthVault contract. Must transfer security deposit together with a call.
   * @param params The encoded parameters for initializing the EthVault contract
   */
  function initialize(bytes calldata params) external payable;
}
