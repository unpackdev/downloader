// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/// @title Supra SMR Block Utilities
/// @notice This library contains the data structures and functions for hashing SMR blocks.
library Smr {
    /// @notice A vote is a block with a round number.
    /// @dev The library assumes the round number is passed in little endian format
    struct Vote {
        MinBlock smrBlock;
        // SPEC: smrBlock.round.to_le_bytes()
        bytes8 roundLE;
    }

    /// @notice A partial SMR block containing the bare-minimum for hashing
    struct MinBlock {
        uint64 round;
        uint128 timestamp;
        bytes32 author;
        bytes32 qcHash;
        bytes32[] batchHashes;
    }

    /// @notice An SMR Transaction
    struct MinTxn {
        bytes32[] clusterHashes;
        bytes32 sender;
        bytes10 protocol;
        bytes1 tx_sub_type;
        // SPEC: Index of the transaction in its batch
        uint256 txnIdx;
    }

    /// @notice A partial SMR batch containing the bare-minimum for hashing
    /// @dev The library assumes that txnHashes is a list of keccak256 hashes of abi encoded SMR transaction
    struct MinBatch {
        bytes10 protocol;
        // SPEC: List of keccak256(Txn.clusterHashes, Txn.sender, Txn.protocol, Txn.tx_sub_type)
        bytes32[] txnHashes;
        // SPEC: Index of the batch in its block
        uint256 batchIdx;
    }

    /// @notice An SMR Signed Coherent Cluster
    struct SignedCoherentCluster {
        CoherentCluster cc;
        bytes qc;
        uint256 round;
        Origin origin;
    }

    /// @notice An SMR Coherent Cluster containing the price data
    struct CoherentCluster {
        bytes32 dataHash;
        uint256[] pair;
        uint256[] prices;
        uint256[] timestamp;
        uint256[] decimals;
    }

    /// @notice An SMR Txn Sender
    struct Origin {
        bytes32 _publicKeyIdentity;
        uint256 _pubMemberIndex;
        uint256 _committeeIndex;
    }

    /// @notice Hash an SMR Transaction
    /// @param txn The SMR transaction to hash
    /// @return Hash of the SMR Transaction
    function hashTxn(MinTxn memory txn) internal pure returns (bytes32) {
        bytes memory clustersConcat = abi.encodePacked(txn.clusterHashes);
        return
            keccak256(
                abi.encodePacked(
                    clustersConcat,
                    txn.sender,
                    txn.protocol,
                    txn.tx_sub_type
                )
            );
    }

    /// @notice Hash an SMR Batch
    /// @param batch The SMR batch to hash
    /// @return Hash of the SMR Batch
    function hashBatch(MinBatch memory batch) internal pure returns (bytes32) {
        bytes32 txnsHash = keccak256(abi.encodePacked(batch.txnHashes));
        return keccak256(abi.encodePacked(batch.protocol, txnsHash));
    }

    /// @notice Hash an SMR Vote
    /// @param vote The SMR vote to hash
    /// @return Hash of the SMR Vote
    function hashVote(Vote memory vote) internal pure returns (bytes32) {
        bytes32 batchesHash = keccak256(
            abi.encodePacked(vote.smrBlock.batchHashes)
        );
        bytes32 blockHash = keccak256(
            abi.encodePacked(
                vote.smrBlock.round,
                vote.smrBlock.timestamp,
                vote.smrBlock.author,
                vote.smrBlock.qcHash,
                batchesHash
            )
        );
        return keccak256(abi.encodePacked(blockHash, vote.roundLE));
    }   
}