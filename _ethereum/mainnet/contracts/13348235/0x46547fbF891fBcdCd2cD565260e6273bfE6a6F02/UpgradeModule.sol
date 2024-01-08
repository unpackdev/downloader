// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

import "./ISavageDroids.sol";

/**
 * @title Upgrade contract for Savage Droids
 * @dev This contract allows the upgrade of Savage Droids tokens.
 *
 * Users supply 2 Droids to be upgraded.
 *
 * SAVAGE DROIDS X BLOCK::BLOCK
 *
 * Smart contract work done by joshpeters.eth
 */

contract UpgradeModule is Ownable, ReentrancyGuard {
  using ECDSA for bytes32;
  using Address for address;

  ISavageDroids savageDroids;

  // Token ID
  uint256 private _currentTokenId;

  // Upgrade toggle
  bool private _isUpgradeActive;

  // Singer for upgrade
  address private signVerifier;

  // Module contract
  mapping(address => bool) private moduleContracts;

  event Mint(
    address indexed to,
    uint256 indexed tokenId,
    uint256 indexed serialId,
    uint256 factionId,
    bytes32 biosHash
  );

  constructor(address savageDroidsAddress, uint256 currentTokenId) {
    savageDroids = ISavageDroids(savageDroidsAddress);
    _currentTokenId = currentTokenId;

    _isUpgradeActive = false;
    signVerifier = 0x251738372e272681FcD8e2E3D0D09A9Af047C562;
  }

  // @dev Returns the token id of the last token
  function getCurrentTokenId() external view returns (uint256) {
    return _currentTokenId;
  }

  // @dev Returns the enabled/disabled status for upgrade
  function getUpgradeState() external view returns (bool) {
    return _isUpgradeActive;
  }

  // @dev Allows to enable/disable minting of upgrade
  function flipUpgradeState() external onlyOwner {
    _isUpgradeActive = !_isUpgradeActive;
  }

  // @dev Sets a new signature verifier
  function setSignVerifier(address verifier) external onlyOwner {
    signVerifier = verifier;
  }

  // @dev Future proof the contract to allow for
  // functionality like fusion to increment token id counter.
  function toggleModuleContract(address module, bool state) external onlyOwner {
    moduleContracts[module] = state;
  }

  // @dev Future proof the contract to allow for
  // functionality like fusion to increment token id counter.
  function incrementCurrentTokenId() external returns (uint256) {
    require(moduleContracts[msg.sender]);
    _currentTokenId += 1;
    return _currentTokenId;
  }

  function getUpgradeSigningHash(
    address recipient,
    uint256 sourceTokenId,
    uint256 destinationTokenId,
    uint256 sourceSerialId,
    uint256 destinationSerialId,
    bytes32 sourceBiosHash,
    bytes32 destinationBiosHash
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          recipient,
          sourceTokenId,
          destinationTokenId,
          sourceSerialId,
          destinationSerialId,
          sourceBiosHash,
          destinationBiosHash
        )
      );
  }

  function upgradeDroid(
    uint256 sourceTokenId,
    uint256 destinationTokenId,
    uint256 sourceSerialId,
    uint256 destinationSerialId,
    bytes32 sourceBiosHash,
    bytes32 destinationBiosHash,
    bytes memory sig
  ) external nonReentrant {
    require(_isUpgradeActive, "Upgrade not active");
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
    bytes32 message = getUpgradeSigningHash(
      msg.sender,
      sourceTokenId,
      destinationTokenId,
      sourceSerialId,
      destinationSerialId,
      sourceBiosHash,
      destinationBiosHash
    ).toEthSignedMessageHash();
    require(
      ECDSA.recover(message, sig) == signVerifier,
      "Permission to call upgrade function failed"
    );

    // Mint new source droid
    _currentTokenId += 1;
    uint256 sourceFactionId = savageDroids.getFaction(sourceTokenId);
    emit Mint(
      msg.sender,
      _currentTokenId,
      sourceSerialId,
      sourceFactionId,
      sourceBiosHash
    );
    savageDroids.mintToken(msg.sender, _currentTokenId, sourceFactionId);

    // Mint new destination droid
    _currentTokenId += 1;
    uint256 destinationFactionId = savageDroids.getFaction(destinationTokenId);
    emit Mint(
      msg.sender,
      _currentTokenId,
      destinationSerialId,
      destinationFactionId,
      destinationBiosHash
    );
    savageDroids.mintToken(msg.sender, _currentTokenId, destinationFactionId);

    //Burn old source droid
    savageDroids.burnToken(sourceTokenId);

    //Burn old destination droid
    savageDroids.burnToken(destinationTokenId);
  }
}
