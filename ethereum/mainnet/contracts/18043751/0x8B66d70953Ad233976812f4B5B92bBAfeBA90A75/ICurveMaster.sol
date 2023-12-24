// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title CurveMaster Interface
/// @notice Interface for interacting with CurveMaster
interface ICurveMaster {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

  // @notice Emited when the owner changes the vault controller address
  // @param _oldVaultControllerAddress The old address of the vault controller
  // @param _newVaultControllerAddress The new address of the vault controller
  event VaultControllerSet(address _oldVaultControllerAddress, address _newVaultControllerAddress);

  // @notice Emited when the owner changes the curve address
  // @param _oldCurveAddress The old address of the curve
  // @param _token The token to set
  // @param _newCurveAddress The new address of the curve
  event CurveSet(address _oldCurveAddress, address _token, address _newCurveAddress);

  // @notice Emited when the owner changes the curve address skipping the checks
  // @param _oldCurveAddress The old address of the curve
  // @param _token The token to set
  // @param _newCurveAddress The new address of the curve
  event CurveForceSet(address _oldCurveAddress, address _token, address _newCurveAddress);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Thrown when the token is not enabled
  error CurveMaster_TokenNotEnabled();

  /// @notice Thrown when result is zero
  error CurveMaster_ZeroResult();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice The vault controller address
  function vaultControllerAddress() external view returns (address _vaultController);

  /// @notice Returns the value of curve labled _tokenAddress at _xValue
  /// @param _tokenAddress The key to lookup the curve with in the mapping
  /// @param _xValue The x value to pass to the slave
  /// @return _value The y value of the curve
  function getValueAt(address _tokenAddress, int256 _xValue) external view returns (int256 _value);

  /// @notice Mapping of token to address
  function curves(address _tokenAddress) external view returns (address _curve);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Set the VaultController addr in order to pay interest on curve setting
  /// @param _vaultMasterAddress The address of vault master
  function setVaultController(address _vaultMasterAddress) external;

  /// @notice Setting a new curve should pay interest
  /// @param _tokenAddress The address of the token
  /// @param _curveAddress The address of the curve for the contract
  function setCurve(address _tokenAddress, address _curveAddress) external;

  /// @notice Special function that does not calculate interest, used for deployment
  /// @param _tokenAddress The address of the token
  /// @param _curveAddress The address of the curve for the contract
  function forceSetCurve(address _tokenAddress, address _curveAddress) external;
}
