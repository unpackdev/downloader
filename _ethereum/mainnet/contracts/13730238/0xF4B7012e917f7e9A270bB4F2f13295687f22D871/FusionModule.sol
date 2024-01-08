// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

import "./ISavageDroids.sol";

/**
 * @title Fusion contract for Savage Droids
 * @dev This contract allows the fusion of Savage Droids tokens.
 *
 * Users supply 2 Droids to be fused into 1 Droid.
 *
 * SAVAGE DROIDS X BLOCK::BLOCK
 *
 * Smart contract work done by joshpeters.eth
 */

contract FusionModule is Ownable, ReentrancyGuard {
  using ECDSA for bytes32;
  using Address for address;

  ISavageDroids savageDroids;

  // Fusion toggle
  bool private _isFusionActive;

  // Singer for fusion
  address private signVerifier;

  event Fusion(
    address indexed to,
    uint256 indexed tokenId,
    uint256 indexed serialId,
    uint256 factionId,
    bytes32 biosHash
  );

  constructor(address savageDroidsAddress) {
    savageDroids = ISavageDroids(savageDroidsAddress);

    _isFusionActive = false;
    signVerifier = 0x251738372e272681FcD8e2E3D0D09A9Af047C562;
  }

  // @dev Returns the enabled/disabled status for fusion
  function getFusionState() external view returns (bool) {
    return _isFusionActive;
  }

  // @dev Allows to enable/disable minting of fusion
  function flipFusionState() external onlyOwner {
    _isFusionActive = !_isFusionActive;
  }

  // @dev Sets a new signature verifier
  function setSignVerifier(address verifier) external onlyOwner {
    signVerifier = verifier;
  }

  function getFusionSigningHash(
    address recipient,
    uint256 sourceTokenId,
    uint256 destinationTokenId,
    uint256 destinationSerialId,
    bytes32 destinationBiosHash
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          recipient,
          sourceTokenId,
          destinationTokenId,
          destinationSerialId,
          destinationBiosHash
        )
      );
  }

  function fuseDroid(
    uint256 sourceTokenId,
    uint256 destinationTokenId,
    uint256 destinationSerialId,
    bytes32 destinationBiosHash,
    bytes memory sig
  ) external nonReentrant {
    require(_isFusionActive, "Fusion not active");
    require(sourceTokenId != destinationTokenId, "Droids cannot be the same");
    require(
      savageDroids.ownerOf(sourceTokenId) == msg.sender,
      "Must own source Droid"
    );
    require(
      savageDroids.ownerOf(destinationTokenId) == msg.sender,
      "Must own destination Droid"
    );

    // Verify signature
    bytes32 message = getFusionSigningHash(
      msg.sender,
      sourceTokenId,
      destinationTokenId,
      destinationSerialId,
      destinationBiosHash
    ).toEthSignedMessageHash();
    require(
      ECDSA.recover(message, sig) == signVerifier,
      "Permission to call fusion function failed"
    );

    // Emit fusion event for destination droid
    uint256 destinationFactionId = savageDroids.getFaction(destinationTokenId);
    emit Fusion(
      msg.sender,
      destinationTokenId,
      destinationSerialId,
      destinationFactionId,
      destinationBiosHash
    );

    //Burn old source droid
    savageDroids.burnToken(sourceTokenId);
  }
}
