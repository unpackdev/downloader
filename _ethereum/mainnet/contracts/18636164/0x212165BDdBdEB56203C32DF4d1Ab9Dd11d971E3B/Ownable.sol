// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

/**
 * Abstract contract implementing ownership handling and verification.
 *
 * The owner address gets stored in the contract's _owner slot and is
 * used to verify both implicit (direct method calls) and explicit
 * (passed in as an argument from arbitrary address, on owner's
 * behalf) signatures.
 *
 * The proposed owner address gets stored in _nextOwner slot and is only
 * promoted to the _owner slot upon receiving a signed approval.
 *
 * The reusable modifiers are utilized to validate that certain functions get
 * invoked by the current owner of the contract.
 */
abstract contract Ownable {
  /**
   * A struct holding the ECDSA explicit signature and the nonce used to
   * produce it.  Nonce is strictly increasing to prevent replay attacks.
   *
   * The recovery id "v" should be 27 or 28.
   */
  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint96 nonce;
  }

  // Current owner of the contract
  address public _owner;
  // Last explicit signature's nonce
  uint96 public _lastNonce;

  // Proposed owner of the contract
  address public _nextOwner;

  /**
   * Validates that the caller of the method matches the requiredOwner parameter.
   *
   * @param requiredOwner the required address
   */
  modifier onlyBy(address requiredOwner) {
    require(msg.sender == requiredOwner, "Only owner can do that");
    _;
  }

  /**
   * Validates that the provided signature was signed by an address matching requiredOwner parameter.
   *
   * @param requiredOwner the required address for the explicit signature
   * @param argsHash an opaque digest of whatever parameters are authorized by the explicit signature
   * @param signature an explicit ECDSA signature over argHash
   */
  modifier onlySignedBy(address requiredOwner, bytes32 argsHash, Signature calldata signature) {
    // Pack the hash of the arguments along with the nonce and contract address to prevent replay attacks.
    bytes32 hash = keccak256(abi.encodePacked(address(this), argsHash, signature.nonce));
    // Check the explicit ECDSA signature by recovering the signer address
    address signer = ecrecover(hash, signature.v, signature.r, signature.s);

    // Make sure the nonce is strictly greater to avoid re-use
    require(signature.nonce > _lastNonce, "The nonce is too old");
    // Make sure the signer matches the one requested
    require(signer == requiredOwner, "Only owner can do that");

    // Update the nonce
    _lastNonce = signature.nonce;

    _;
  }

  /**
   * Updates the proposed owner to a new address. To be called directly by the Owner.
   *
   * Requires the transaction to be signed by current owner.
   *
   * @param nextOwner the proposed address of the new owner
   */
  function setNextOwner(address nextOwner) public onlyBy(_owner) {
    _nextOwner = nextOwner;
  }

  /**
   * Updates the proposed owner to a new address. To be called on Owner's behalf.
   *
   * Requires the signature from the current owner to be passed.
   *
   * @param nextOwner the proposed address of the new owner
   * @param signature an explicit ECDSA signature of the authorization with the Owner's public key
   */
  function setNextOwner(address nextOwner, Signature calldata signature) public onlySignedBy(_owner, keccak256(abi.encodePacked(nextOwner)), signature) {
    _nextOwner = nextOwner;
  }

  /**
   * Accepts the new owner. To be called by the proposed Owner directly.
   */
  function acceptNextOwner() public onlyBy(_nextOwner) {
    _owner = _nextOwner;
  }

  /**
   * Accepts the new owner. To be called on the proposed Owner's behalf.
   *
   * @param signature an explicit ECDSA signature of the authorization with the Owner's public key
   */
  function acceptNextOwner(Signature calldata signature) public onlySignedBy(_nextOwner, keccak256(abi.encodePacked()), signature) {
    _owner = _nextOwner;
  }
}
