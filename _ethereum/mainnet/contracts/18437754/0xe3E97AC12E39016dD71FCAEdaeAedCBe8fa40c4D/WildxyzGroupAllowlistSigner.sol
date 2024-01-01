// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

// It ain't much, but it's honest work.

pragma solidity ^0.8.17;

import "./Strings.sol";
import "./ECDSA.sol";

import "./WildxyzGroup.sol";

abstract contract WildxyzGroupAllowlistSigner is WildxyzGroup {
  
  address allowlistSigner;

  uint256[] public groupIds_AllowlistSigners;

  error InvalidSignature(bytes signature, uint256 groupId);

  // modifier validation hooks

  modifier validateSigner(address _receiver, bytes memory _signature) {
    _validateSignature(_receiver, _signature);
    _;
  }

  // internal functions

  function _setupGroupAllowlistSigner(string memory _name, uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _reserveSupply) internal returns (uint256) {
    uint256 groupId = _createGroup(_name, _startTime, _endTime, _price, _reserveSupply);

    groupIds_AllowlistSigners.push(groupId);

    return groupId;
  }

  function _isAllowlistSignerGroup(uint256 _groupId) internal view returns (bool validGroup) {
    for (uint256 i = 0; i < groupIds_AllowlistSigners.length; i++) {
      if (groupIds_AllowlistSigners[i] == _groupId) {
        validGroup = true;
        break;
      }
    }
  }

  function _verifySignature(address _receiver, bytes memory _signature) internal view returns (bool, uint256) {
    if (_signature.length != 65) return (false, 0);

    for (uint256 i = 0; i < groupIds_AllowlistSigners.length; i++) {
      uint256 groupId = groupIds_AllowlistSigners[i];

      bytes32 addressHash = keccak256(abi.encodePacked(_receiver, address(this), Strings.toString(groupId)));
      bytes32 message = ECDSA.toEthSignedMessageHash(addressHash);
      address signer = ECDSA.recover(message, _signature);

      if (signer != address(0) && signer == allowlistSigner) {
        return (true, groupId);
      }
    }

    return (false, 0);
  }

  function _validateSignature(address _receiver, bytes memory _signature) internal view {
    (bool valid, uint256 groupId) = _verifySignature(_receiver, _signature);
    if (!valid) revert InvalidSignature(_signature, groupId);
  }

  function _validateSignatureAndGetGroupId(address _receiver, bytes memory _signature) internal view returns (uint256) {
    (bool valid, uint256 groupId) = _verifySignature(_receiver, _signature);
    if (!valid) revert InvalidSignature(_signature, groupId);

    return groupId;
  }

  function _setAllowlistSigner(address _signer) internal {
    allowlistSigner = _signer;
  }

  // only admin

  function setAllowlistSigner(address _signer) public onlyAdmin {
    _setAllowlistSigner(_signer);
  }

  // public functions

  /** @notice Verifies the signature of the signer for a given address.
   * @param _receiver The address the message was signed for.
   * @param _signature The signature to verify.
   * @return valid True if the signature is valid, false otherwise.
   */
  function verifySignature(address _receiver, bytes memory _signature) public view returns (bool, uint256) {
    return _verifySignature(_receiver, _signature);
  }

  // minting implemented in child contract
}