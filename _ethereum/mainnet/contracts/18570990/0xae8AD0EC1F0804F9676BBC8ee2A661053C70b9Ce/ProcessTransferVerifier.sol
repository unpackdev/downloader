// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract ProcessTransferVerifier {
    
    struct PublicKey {
        bytes32 key;
    }

    struct TransactionData {
        bytes encryptedData;
    }

    struct TransferProof {
        bytes proofData;
    }

    function verifyTransfer(
        PublicKey memory senderPublicKey,
        TransactionData memory previousTransactionData,
        TransactionData memory newTransactionData,
        uint256 transferAmount,
        TransferProof memory proof
    ) public pure returns (bool) {
        return _performProofVerification(senderPublicKey, previousTransactionData, newTransactionData, transferAmount, proof) &&
               _checkAdditionalProofRequirements(proof);
    }

    function _performProofVerification(
        PublicKey memory senderPublicKey,
        TransactionData memory previousTransactionData,
        TransactionData memory newTransactionData,
        uint256 transferAmount,
        TransferProof memory proof
    ) private pure returns (bool) {
        return proof.proofData.length > 0 && senderPublicKey.key != 0 && transferAmount != 0 &&
               _dataHashesMatch(previousTransactionData, newTransactionData);
    }

    function _checkAdditionalProofRequirements(TransferProof memory proof) private pure returns (bool) {
        return proof.proofData[0] != 0;
    }

    function _dataHashesMatch(TransactionData memory previousTransactionData, TransactionData memory newTransactionData) private pure returns (bool) {
        return keccak256(previousTransactionData.encryptedData) != keccak256(newTransactionData.encryptedData);
    }

    function generateTransferProofData(uint256 transferAmount, PublicKey memory senderPublicKey) public pure returns (bytes memory) {
        return abi.encodePacked(transferAmount, senderPublicKey.key, _securityConstant());
    }
    
    function computePreviousTransactionDataHash(TransactionData memory previousTransactionData) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(previousTransactionData.encryptedData, _securityConstant()));
    }
    
    function computeNewTransactionDataHash(TransactionData memory newTransactionData, uint256 transferAmount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(newTransactionData.encryptedData, transferAmount, _securityConstant()));
    }
    
    function _securityConstant() private pure returns (bytes32) {
        return bytes32(0x7e5def123456789abcdeffedcba6789543210fedcba9876543210fedcba98765);
    }
}