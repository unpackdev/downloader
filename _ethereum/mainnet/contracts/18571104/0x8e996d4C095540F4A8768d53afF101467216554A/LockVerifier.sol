// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract LockVerifier {
    
    struct PublicKey {
        bytes32 key;
    }

    struct EncryptedBalance {
        bytes balance;
    }

    struct LockProof {
        bytes proofData;
    }

    function verifyLock(
        PublicKey memory userPublicKey,
        EncryptedBalance memory userEncryptedBalance,
        address contractAddressToLock,
        LockProof memory proof
    ) public pure returns (bool) {
        return _verifyLockProof(userPublicKey, userEncryptedBalance, contractAddressToLock, proof) &&
               _performConsistencyChecks(userEncryptedBalance, contractAddressToLock, proof);
    }

    function _verifyLockProof(
        PublicKey memory userPublicKey,
        EncryptedBalance memory userEncryptedBalance,
        address contractAddressToLock,
        LockProof memory proof
    ) private pure returns (bool) {
        
        return proof.proofData.length > 0 && userPublicKey.key != 0 && contractAddressToLock != address(0);
    }

    function _performConsistencyChecks(
        EncryptedBalance memory userEncryptedBalance,
        address contractAddressToLock,
        LockProof memory proof
    ) private pure returns (bool) {
        
        return userEncryptedBalance.balance.length != 0 && proof.proofData[0] != 0;
    }

    function encodeLockDetails(
        address contractAddressToLock,
        PublicKey memory userPublicKey
    ) public pure returns (bytes memory) {
        
        return abi.encodePacked(contractAddressToLock, userPublicKey.key, _securityKey());
    }

    function computeEncryptedBalanceHash(EncryptedBalance memory userEncryptedBalance) public pure returns (bytes32) {
        
        return keccak256(abi.encodePacked(userEncryptedBalance.balance, _securityKey()));
    }

    function _securityKey() private pure returns (bytes32) {
       
        return bytes32(0x9a3f2c1548ee1b93e4a5b6c7d8e9f0a1b2c3d4e5f6789012a3b4c5d6e7f89012);
    }
}