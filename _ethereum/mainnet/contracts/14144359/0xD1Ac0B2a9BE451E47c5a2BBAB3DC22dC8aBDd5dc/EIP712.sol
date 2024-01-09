/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

library EIP712 {
    bytes32 internal constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /**
     * @dev Calculates a EIP712 domain separator.
     * @param name The EIP712 domain name.
     * @param version The EIP712 domain version.
     * @param verifyingContract The EIP712 verifying contract.
     * @return result EIP712 domain separator.
     */
    function hashDomainSeperator(
        string memory name,
        string memory version,
        address verifyingContract
    ) internal view returns (bytes32 result) {
        bytes32 typehash = EIP712DOMAIN_TYPEHASH;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))
            let chainId := chainid()

            let memPtr := mload(64)

            mstore(memPtr, typehash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            result := keccak256(memPtr, 160)
        }
    }

    /**
     * @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
     * @param domainHash Hash of the domain domain separator data, computed with getDomainHash().
     * @param hashStruct The EIP712 hash struct.
     * @return result EIP712 hash applied to the given EIP712 Domain.
     */
    function hashMessage(bytes32 domainHash, bytes32 hashStruct) internal pure returns (bytes32 result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
            mstore(add(memPtr, 2), domainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            result := keccak256(memPtr, 66)
        }
    }
}
