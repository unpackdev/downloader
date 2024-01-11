// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "./PermissionManagement.sol";

/// @title Taxes Contract
/// @author kumareth@monument.app
/// @notice In Monument.app context, this contract allows the Beneficiary to collect taxes everytime a Monument or an Artifact is minted.
abstract contract Taxes {
  PermissionManagement private permissionManagement;

  constructor (
    address _permissionManagementContractAddress
  ) {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  event TaxesChanged (
    uint256 newTaxOnMintingAnArtifact,
    address indexed actionedBy
  );

  uint256 public taxOnMintingAnArtifact; // `26 * (10 ** 13)` was around $1 in Oct 2021

  /// @notice To set new taxes for Building and Minting
  /// @param _onMintingArtifact Tax in wei, for minting an Artifact.
  function setTaxes(uint256 _onMintingArtifact)
    external
    returns (uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);

    taxOnMintingAnArtifact = _onMintingArtifact;

    emit TaxesChanged (
      _onMintingArtifact,
      msg.sender
    );

    return _onMintingArtifact;
  }

  /// @notice Taxes are sent to the Beneficiary
  function _chargeArtifactTax()
    internal
    returns (bool)
  {
    require(
      msg.value >= taxOnMintingAnArtifact || 
      permissionManagement.moderators(msg.sender), // moderators dont pay taxes
      "Insufficient amount sent"
    );

    if (msg.value >= taxOnMintingAnArtifact) {
      (bool success, ) = permissionManagement.beneficiary().call{value: taxOnMintingAnArtifact}("");
      require(success, "Transfer to Beneficiary failed");
    }
    
    return true;
  }
}