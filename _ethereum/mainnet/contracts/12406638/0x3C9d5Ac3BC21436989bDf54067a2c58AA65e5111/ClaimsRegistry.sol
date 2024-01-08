// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./Verifier.sol";

/// @title The claim verification interface expected by the Staking contract
/// @author Miguel Palhas <miguel@subvisual.co>
interface IClaimsRegistryVerifier {
  /// @notice Verifies that the given `sig` corresponds to a claim about `subject`, signed by `attester`
  /// @param subject The subject the claim refers to
  /// @param attester The account that is expected to have signed the claim
  /// @param sig The signature
  /// @return Whether a claim about `subject` and signed by `attester` does exist and matches `sig`
  function verifyClaim(address subject, address attester, bytes calldata sig) external view returns (bool);
}

/// @title A claim registry. Does not actually store data, but only signatures of claims and their subjects
/// @author Miguel Palhas <miguel@subvisual.co>
contract ClaimsRegistry is IClaimsRegistryVerifier, Verifier {
  /// @notice The mapping of keys to claims
  mapping(bytes32 => Claim) public registry;

  /// @notice Struct containing all public data about a claim (currently only the subject)
  struct Claim {
    address subject; // Subject the claim refers to
    bool revoked;    // Whether the claim is revoked or not
  }

  /// @notice Emitted when a signed claim is successfuly stored
  event ClaimStored(
    bytes sig
  );

  /// @notice Emitted when a previously stored claim is successfuly revoked by the attester
  event ClaimRevoked(
    bytes sig
  );

  /// @notice Stores a claim about `subject`, signed by `attester`. Instead of
  ///   actual data, receives only `claimHash` and `sig`, and checks whether the
  ///   signature matches the expected key, and is signed by `attester`
  /// @param subject Account the claim refers to
  /// @param attester Account that signed the claim
  /// @param claimHash the claimHash that was signed along with the subject
  /// @param sig The given signature that must match (`subject`, `claimhash`)
  function setClaimWithSignature(
    address subject,
    address attester,
    bytes32 claimHash,
    bytes calldata sig
  ) public {
    bytes32 signable = computeSignableKey(subject, claimHash);

    require(verifyWithPrefix(signable, sig, attester), "ClaimsRegistry: Claim signature does not match attester");

    bytes32 key = computeKey(attester, sig);

    registry[key] = Claim(subject, false);

    emit ClaimStored(sig);
  }

  /// @notice Checks if a claim signature is valid and stored, and returns the corresponding subject
  /// @param attester Account that signed the claim
  /// @param sig The given signature that must match keccak256([`subject`, `claimhash`])
  /// @return The subject of the claim, or address(0) if none was found
  function getClaim(
    address attester,
    bytes calldata sig
  ) public view returns (address) {
    bytes32 key = keccak256(abi.encodePacked(attester, sig));

    if (registry[key].revoked) {
      return address(0);
    } else {
      return registry[key].subject;
    }

  }

  /// @notice Checks if a claim signature is valid, and corresponds to the given subject
  /// @param subject Account the claim refers to
  /// @param attester Account that signed the claim
  /// @param sig The given signature that must match keccak256([`subject`, `claimhash`])
  /// @return The subject of the claim, or address(0) if none was found
  function verifyClaim(
    address subject,
    address attester,
    bytes calldata sig
  ) override external view returns (bool) {
    return getClaim(attester, sig) == subject;
  }

  /// @notice Callable by an attester, to revoke previously signed claims about a subject
  /// @param sig The given signature that must match keccak256([`subject`, `claimhash`])
  function revokeClaim(
    bytes calldata sig
  ) public {
    bytes32 key = computeKey(msg.sender, sig);

    require(registry[key].subject != address(0), "ClaimsRegistry: Claim not found");

    registry[key].revoked = true;

    emit ClaimRevoked(sig);
  }

  /// @notice computes the hash that must be signed by the attester before storing a claim
  /// @param subject Account the claim refers to
  /// @param claimHash the claimHash that was signed along with the subject
  /// @return The hash to be signed by the attester
  function computeSignableKey(address subject, bytes32 claimHash) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(subject, claimHash));
  }

  function computeKey(address attester, bytes calldata sig) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(attester, sig));
  }
}
