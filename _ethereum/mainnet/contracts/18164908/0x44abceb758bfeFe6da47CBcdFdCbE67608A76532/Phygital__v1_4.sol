// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Phygital__v1_3.sol";

contract Phygital__v1_4 is Phygital__v1_3 {
  using ECDSA for bytes32;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {}

  // Phygital__v1_3 => Phygital__v1_4 upgrade initializer
  function upgradeTo__v1_4() public onlyOwner upgradeVersion(4) {}

  // Deploying Phygital__v1_4 initializer
  function initialize__v1_4(
    string memory _name,
    string memory _symbol,
    address _signVerifierRegistry,
    bytes32 _signVerifierId
  ) public initializer {
    Phygital__v1_3.initialize__v1_3(_name, _symbol, _signVerifierRegistry, _signVerifierId);
    upgradeTo__v1_4();
  }

  function getBatchClaimSigningHash(
    uint256 blockExpiry,
    address recipient,
    uint256 startTokenId,
    uint256 quantity
  ) public view virtual override returns (bytes32) {
    return keccak256(abi.encodePacked(address(this), blockExpiry, recipient, startTokenId, quantity));
  }

  /**
   * @notice Mint a batch of tokens with a valid signature
   * @dev For transaction relayers to mint
   */
  function mintBatchWithSig(
    bytes memory sig,
    uint256 blockExpiry,
    address recipient,
    uint256 startTokenId,
    uint256 quantity
  ) public virtual override {
    require(quantity > 0, "Must mint at least one token");

    bytes32 message = getBatchClaimSigningHash(blockExpiry, recipient, startTokenId, quantity).toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == getSignVerifier(), "Permission to call this function failed");
    require(block.number < blockExpiry, "Sig expired");

    for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
      _safeMint(recipient, i);
    }
  }
}
