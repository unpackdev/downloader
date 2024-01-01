// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProcessDepositVerifier {
    
    struct PublicKey {
        bytes32 key;
    }

    struct EncryptedBalance {
        bytes balance;
    }

    struct DepositProof {
        bytes proofData;
    }

    function verifyDeposit(
        PublicKey memory recipientPublicKey,
        EncryptedBalance memory previousBalance,
        EncryptedBalance memory newBalance,
        uint256 depositAmount,
        DepositProof memory proof
    ) public pure returns (bool) {
        return _performProofVerification(recipientPublicKey, previousBalance, newBalance, depositAmount, proof) &&
               _checkAdditionalProofRequirements(proof);
    }

    function _performProofVerification(
        PublicKey memory recipientPublicKey,
        EncryptedBalance memory previousBalance,
        EncryptedBalance memory newBalance,
        uint256 depositAmount,
        DepositProof memory proof
    ) private pure returns (bool) {
        return proof.proofData.length > 0 && recipientPublicKey.key != 0 && depositAmount != 0 &&
               _balanceHashesMatch(previousBalance, newBalance);
    }

    function _checkAdditionalProofRequirements(DepositProof memory proof) private pure returns (bool) {
        return proof.proofData[0] != 0;
    }

    function _balanceHashesMatch(EncryptedBalance memory previousBalance, EncryptedBalance memory newBalance) private pure returns (bool) {
        return keccak256(previousBalance.balance) != keccak256(newBalance.balance);
    }

    function generateProofData(uint256 depositAmount, PublicKey memory recipientPublicKey) public pure returns (bytes memory) {
        return abi.encodePacked(depositAmount, recipientPublicKey.key, _securityConstant());
    }
    
    function computePreviousBalanceHash(EncryptedBalance memory previousBalance) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(previousBalance.balance, _securityConstant()));
    }
    
    function computeNewBalanceHash(EncryptedBalance memory newBalance, uint256 depositAmount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(newBalance.balance, depositAmount, _securityConstant()));
    }
    
    function _securityConstant() private pure returns (bytes32) {
        return bytes32(0x783c12ab432b8e7d123f4323c1239f84f2137ab9b123d789ab123efc12345678);
    }
}