// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.22;

import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./IERC20Metadata.sol";
import "./IVaultState.sol";
import "./IVaultEnterExit.sol";

/**
 * @title IVaultToken
 * @author StakeWise
 * @notice Defines the interface for the VaultToken contract
 */
interface IVaultToken is IERC20Permit, IERC20, IERC20Metadata, IVaultState, IVaultEnterExit {

}
