//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./ECDSA.sol";

contract EIP712Whitelisting {
  using ECDSA for bytes32;

  // The key used to sign whitelist signatures.
  // We will check to ensure that the key that signed the signature
  // is this one that we expect.
  address whitelistSigningKey = address(0);

  // Domain Separator is the EIP-712 defined structure that defines what contract
  // and chain these signatures can be used for.  This ensures people can't take
  // a signature used to mint on one contract and use it for another, or a signature
  // from testnet to replay on mainnet.
  // It has to be created in the constructor so we can dynamically grab the chainId.
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
  bytes32 public DOMAIN_SEPARATOR;

  // The typehash for the data type specified in the structured data
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
  // This should match whats in the client side whitelist signing code
  // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L22
  bytes32 public constant MINTER_TYPEHASH = keccak256("Minter(address wallet)");

  constructor(string memory tokenName, string memory version) {
    // This should match whats in the client side whitelist signing code
    // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L12
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        // This should match the domain you set in your client side signing.
        keccak256(bytes(tokenName)),
        keccak256(bytes(version)),
        block.chainid,
        address(this)
      )
    );
  }

  function _setWhitelistSigningAddress(address newSigningKey) internal {
    whitelistSigningKey = newSigningKey;
  }

  modifier requiresWhitelist(bytes calldata signature) {
    require(whitelistSigningKey != address(0), "Whitelist not enabled; please set the private key.");
    // Verify EIP-712 signature by recreating the data structure
    // that we signed on the client side, and then using that to recover
    // the address that signed the signature for this data.
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))));
    // Use the recover method to see what address was used to create
    // the signature on this data.
    // Note that if the digest doesn't exactly match what was signed we'll
    // get a random recovered address.
    address recoveredAddress = digest.recover(signature);
    require(recoveredAddress == whitelistSigningKey, "Invalid signature");
    _;
  }
}
