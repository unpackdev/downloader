//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Initializable.sol";

contract EIP712BaseUpgradeable is Initializable {
  struct EIP712Domain {
    string name;
    string version;
    address verifyingContract;
    bytes32 salt;
  }

  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(
      bytes(
        "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
      )
    );

  bytes32 internal domainSeparator;

  function _initialize(
    string memory name,
    string memory version
  ) internal virtual onlyInitializing {
    domainSeparator = keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        address(this),
        bytes32(getChainID())
      )
    );
  }

  function getChainID() internal view returns (uint256 id) {
    assembly {
      id := chainid()
    }
  }

  function getDomainSeparator() private view returns (bytes32) {
    return domainSeparator;
  }

  /**
   * Accept message hash and returns hash message in EIP712 compatible form
   * So that it can be used to recover signer from signature signed using EIP712 formatted data
   * https://eips.ethereum.org/EIPS/eip-712
   * "\\x19" makes the encoding deterministic
   * "\\x01" is the version byte to make it compatible to EIP-191
   */
  function toTypedMessageHash(
    bytes32 messageHash
  ) internal view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash)
      );
  }
}
