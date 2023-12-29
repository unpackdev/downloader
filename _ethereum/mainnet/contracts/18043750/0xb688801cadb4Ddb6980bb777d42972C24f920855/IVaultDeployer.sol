// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4 <0.9.0;

import "./IVault.sol";
import "./IVaultController.sol";
import "./IERC20.sol";

// @notice Deployer of Vaults
// @dev    This contract is needed to reduce the size of the VaultController contract
interface IVaultDeployer {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  // @notice Thrown when someone other than the vault controller tries to call the method
  error VaultDeployer_OnlyVaultController();

  /*///////////////////////////////////////////////////////////////
                              VARIABLES
  //////////////////////////////////////////////////////////////*/

  /// @notice The address of the CVX token
  /// @return _cvx The address of the CVX token
  function CVX() external view returns (IERC20 _cvx);

  /// @notice The address of the CRV token
  /// @return _crv The address of the CRV token
  function CRV() external view returns (IERC20 _crv);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @notice Deploys a new Vault
  /// @param _id The id of the vault
  /// @param _minter The address of the minter of the vault
  /// @return _vault The vault that was created
  function deployVault(uint96 _id, address _minter) external returns (IVault _vault);
}
