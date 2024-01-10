// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ECDSA.sol";

contract EIP712Whitelist is Ownable {
    using ECDSA for bytes32;

    address whitelistSigningKey = address(0);
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant MINTER_TYPEHASH = keccak256("Minter(address wallet,uint256 nonce)");

    mapping(uint256 => bool) usedNonces;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function setWhitelistSigningAddress(address newSigningKey) 
        public 
        onlyOwner
    {
        whitelistSigningKey = newSigningKey;
    }

    function useNonce(uint256 nonce) 
        internal
    {
        usedNonces[nonce] = true;
    }

    modifier requiresWhitelist(bytes calldata signature, uint256 nonce) {
        require(whitelistSigningKey != address(0), "whitelist not enabled");
        require(!usedNonces[nonce], "Signature already claimed");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        MINTER_TYPEHASH, 
                        msg.sender,
                        nonce
                    )
                )
            )
        );
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == whitelistSigningKey, "Invalid Signature");
        _;
    }
}