// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ECDSA.sol";
import "./Strings.sol";
import "./Ownable.sol";

error InvalidSignature();
error NoSigningKey();

contract EIP712Common is Ownable {
    using ECDSA for bytes32;

    // The key used to sign whitelist signatures.
    address signingKey = address(0);

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant TYPEHASH =
        keccak256("Minter(address wallet,bytes32 packId,bytes32 accountId)");

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("FloorStore")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    modifier requiresAllowlist(
        bytes calldata signature,
        string calldata packId,
        string calldata accountId
    ) {
        if (signingKey == address(0)) revert NoSigningKey();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        TYPEHASH,
                        msg.sender,
                        keccak256(bytes(packId)),
                        keccak256(bytes(accountId))
                    )
                )
            )
        );

        address recoveredAddress = digest.recover(signature);

        if (recoveredAddress != signingKey) revert InvalidSignature();
        _;
    }
}
