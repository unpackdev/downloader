// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ECDSA.sol";
import "./SignatureChecker.sol";

/**
 * @dev EIP-712 Helper
 */
library LibEIP712  {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant private _TYPE_HASH = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /**
     * @dev Returns the domain separator for the current domain.
     * @param domain domain as specified in EIP-712
     * @return domainSeparator as specified in EIP-712
     */
    function domainSeparator(EIP712Domain memory domain) private pure returns (bytes32) {
        return keccak256(
                    abi.encode(
                        _TYPE_HASH, 
                        keccak256(bytes(domain.name)), 
                        keccak256(bytes(domain.version)), 
                        domain.chainId, 
                        domain.verifyingContract
                    )
                );
    }

    /**
     * @dev Returns the hash typed data as specified in EIP-712
     * @param domain domain as specified in EIP-712
     * @param structHash hash of the struc to hashing  as specified in EIP-712
     * @return hashTypedData hash as specified in EIP-712
     */
    function hashTypedData(EIP712Domain memory domain, bytes32 structHash) internal pure returns (bytes32) {
        return ECDSA.toTypedDataHash(domainSeparator(domain), structHash);
    }

    /**
     * @dev Checks if signature is valid as specified in EIP-191
     * @param signer address witch sing data
     * @param hash data hash signed
     * @return isValidSignature true if is valid and fale in other case
     */
    function isValidSignature(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }


}