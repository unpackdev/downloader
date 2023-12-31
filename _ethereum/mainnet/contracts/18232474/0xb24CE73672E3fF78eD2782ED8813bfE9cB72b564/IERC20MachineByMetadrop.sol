// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import "./Context.sol";
import "./IConfigStructures.sol";
import "./IERC20ConfigByMetadrop.sol";
import "./ERC20ByMetadrop.sol";
import "./IErrors.sol";

/**
 * @dev Metadrop ERC-20 contract deployer
 *
 * @dev Implementation of the {IERC20DeployerByMetasdrop} interface.
 *
 * Lightweight deployment module for use with template contracts
 */
interface IERC20MachineByMetadrop is IERC20ConfigByMetadrop, IErrors {
  /**
   * @dev function {deploy}
   *
   * Deploy a fresh instance
   */
  function deploy(
    bytes32 salt_,
    bytes memory args_
  ) external payable returns (address erc20ContractAddress_);
}
