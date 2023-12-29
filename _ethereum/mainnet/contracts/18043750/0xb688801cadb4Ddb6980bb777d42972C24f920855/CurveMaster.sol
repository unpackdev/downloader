// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICurveMaster.sol";
import "./ICurveSlave.sol";
import "./IVaultController.sol";
import "./Ownable.sol";

/// @notice Curve master keeps a record of CurveSlave contracts and links it with an address
/// @dev All numbers should be scaled to 1e18. for instance, number 5e17 represents 50%
contract CurveMaster is ICurveMaster, Ownable {
  /// @dev Mapping of token to address
  mapping(address => address) public curves;

  /// @dev The vault controller address
  address public vaultControllerAddress;

  /// @notice Returns the value of curve labled _tokenAddress at _xValue
  /// @param _tokenAddress The key to lookup the curve with in the mapping
  /// @param _xValue The x value to pass to the slave
  /// @return _value The y value of the curve
  function getValueAt(address _tokenAddress, int256 _xValue) external view override returns (int256 _value) {
    if (curves[_tokenAddress] == address(0)) revert CurveMaster_TokenNotEnabled();
    ICurveSlave _curve = ICurveSlave(curves[_tokenAddress]);
    _value = _curve.valueAt(_xValue);
    if (_value == 0) revert CurveMaster_ZeroResult();
  }

  /// @notice Set the VaultController addr in order to pay interest on curve setting
  /// @param _vaultMasterAddress The address of vault master
  function setVaultController(address _vaultMasterAddress) external override onlyOwner {
    address _oldCurveAddress = vaultControllerAddress;
    vaultControllerAddress = _vaultMasterAddress;

    emit VaultControllerSet(_oldCurveAddress, _vaultMasterAddress);
  }

  /// @notice Setting a new curve should pay interest
  /// @param _tokenAddress The address of the token
  /// @param _curveAddress The address of the curve for the contract
  function setCurve(address _tokenAddress, address _curveAddress) external override onlyOwner {
    if (vaultControllerAddress != address(0)) IVaultController(vaultControllerAddress).calculateInterest();
    address _oldCurve = curves[_tokenAddress];
    curves[_tokenAddress] = _curveAddress;

    emit CurveSet(_oldCurve, _tokenAddress, _curveAddress);
  }

  /// @notice Special function that does not calculate interest, used for deployment
  /// @param _tokenAddress The address of the token
  /// @param _curveAddress The address of the curve for the contract
  function forceSetCurve(address _tokenAddress, address _curveAddress) external override onlyOwner {
    address _oldCurve = curves[_tokenAddress];
    curves[_tokenAddress] = _curveAddress;

    emit CurveForceSet(_oldCurve, _tokenAddress, _curveAddress);
  }
}
