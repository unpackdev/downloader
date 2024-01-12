/**  
 SPDX-License-Identifier: GPL-3.0
*/
pragma solidity ^0.8.13;

import "./ECDSA.sol";
import "./Ownable.sol";

error SignatureNotEnabled();
error InvalidSignature();

contract Signature is Ownable {
    using ECDSA for bytes32;

    address signatureSigningKey;
    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 private immutable EIP712_Domain = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private immutable NAME = keccak256("Extracts Of Sin");
    bytes32 private immutable NUMBER = keccak256("1");

    bytes32 private immutable MINTER_TYPEHASH =
        keccak256("Minter(address wallet,string nonce)");

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_Domain, 
                NAME, 
                NUMBER,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev set signature signing address to enable signature
     */
    function setSignatureSigningAddress(address newSigningKey) public onlyOwner {
        signatureSigningKey = newSigningKey;
    }

    modifier requiresSignature(bytes calldata signature, string calldata nonce) {
        if(signatureSigningKey == address(0)) revert SignatureNotEnabled();
        
        bytes32 DIGEST = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        MINTER_TYPEHASH,
                        msg.sender,
                        keccak256(bytes(nonce))
                    )
                )
            )
        );

        address recoveredAddress = DIGEST.recover(signature);
        if(recoveredAddress != signatureSigningKey) revert InvalidSignature();
        _;
    }
}