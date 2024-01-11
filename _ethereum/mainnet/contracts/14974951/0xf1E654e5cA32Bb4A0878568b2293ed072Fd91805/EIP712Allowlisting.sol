//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ECDSA.sol";
import "./EIP712Base.sol";

contract EIP712Allowlisting is AccessControl, EIP712Base {
    using ECDSA for bytes32;
    bytes32 public constant ALLOWLISTING_ROLE = keccak256("ALLOWLISTING_ROLE");

    mapping(bytes32 => bool) public signatureUsed;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side allowlist signing code
    // https://github.com/msfeldstein/EIP712-allowlisting/blob/main/test/signAllowlist.ts#L22
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet,uint256 nonce)");

    /// @notice setup configures allowlisting roles and domains
    /// @param name Name for EIP712 domain
    constructor(string memory name) {
        setUpDomain(name);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); /*Grant role to deployer for access control changes*/
        _setupRole(ALLOWLISTING_ROLE, msg.sender);
    }

    modifier requiresAllowlist(bytes calldata signature, uint256 nonce) {
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 structHash = keccak256(
            abi.encode(MINTER_TYPEHASH, msg.sender, nonce)
        );
        bytes32 digest = toTypedMessageHash(structHash); /*Calculate EIP712 digest*/
        require(!signatureUsed[digest], "signature used");
        signatureUsed[digest] = true;
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        require(
            hasRole(ALLOWLISTING_ROLE, recoveredAddress),
            "Invalid Signature"
        );
        _;
    }
}
