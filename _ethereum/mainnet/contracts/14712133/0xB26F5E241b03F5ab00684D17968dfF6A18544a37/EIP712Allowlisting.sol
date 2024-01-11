//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";

contract EIP712Allowlisting is Ownable {
    using ECDSA for bytes32;

    // We will check to ensure that the key that signed the signature
    // is this one that we expect.
    address private allowlistSigningKey = address(0);

    // Domain Separator is the EIP-712 defined structure that defines what contract
    // and chain these signatures can be used for.  This ensures people can't take
    // a signature used to mint on one contract and use it for another, or a signature
    // from testnet to replay on mainnet.
    // It has to be created in the constructor so we can dynamically grab the chainId.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 public DOMAIN_SEPARATOR;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");

    constructor() {
        // This should match whats in the client side allowlist signing code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // This should match the domain you set in your client side signing.
                keccak256(bytes("NieuxAllowlist")),
                keccak256(bytes("1")),
                getChainId(),
                address(this)
            )
        );
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    function setAllowlistSigningAddress(address newSigningKey) public onlyOwner {
        allowlistSigningKey = newSigningKey;
    }

    modifier requiresAllowlist(bytes calldata signature) {
        require(allowlistSigningKey != address(0), "allowlist not enabled");
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == allowlistSigningKey, "Invalid Signature");
        _;
    }
}