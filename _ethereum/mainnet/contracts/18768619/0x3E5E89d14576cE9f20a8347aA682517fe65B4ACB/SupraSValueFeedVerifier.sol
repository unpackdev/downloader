// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./BLS.sol";
import "./ISupraSValueFeed.sol";
import "./EnumerableSet.sol";
import "./Ownable2StepUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/// @title Supra SMR Block Utilities
/// @notice This library contains the data structures and functions for hashing SMR blocks.
/// @dev This library is primarily used by the SupraSValueFeedVerifier contract.
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
    }

    /// @notice A partial SMR batch containing the bare-minimum for hashing
    /// @dev The library assumes that txnHashes is a list of keccak256 hashes of abi encoded SMR transaction
    struct MinBatch {
        bytes10 protocol;
        // SPEC: List of keccak256(Txn.clusterHashes, Txn.sender, Txn.protocol, Txn.tx_sub_type)
        bytes32[] txnHashes;
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

/// @title Supra Oracle Value Feed Verifier Contract
/// @notice This contract verifies Oracle SMR Transactions using BLS Signatures and stores the price data
/// @dev The storage is done in a separate contract called `SupraSValueFeedStorage`
contract SupraSValueFeedVerifier is Ownable2StepUpgradeable,UUPSUpgradeable {


    
    /// @notice It is identification that is common for both client and contract
    /// @dev It is BLS signature verification dependency mostly keccak256 hash of some input
    bytes32 domain;

    /// @notice The current contract authority
    /// @dev It is the BN254 public key of the committee
    uint256[4] publicKey;

    ISupraSValueFeed public supraSValueFeedStorage;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.AddressSet private whitelistedFreeNodes;
    /// @notice Currently Deprecated
    /// @dev We need to keep this just to avoid storage collision
    EnumerableSet.UintSet private hccPairs;

    /// @dev Set of verified votes to minimize computation
    mapping(bytes32 => bool) verifiedVotes;
    /// @dev Set of processed transactions to prevent replay attacks
    mapping(bytes32 => bool) processedTxns;

    uint256 internal blsPrecompileGasCost;

    /// @notice It will put log to the individual free node wallets those added to the whitelist
    /// @dev It will be emitted once the free node is added to the whitelist
    /// @param freeNodeWalletAddress is the address through which free node wallet is to be whitelisted
    event FreeNodeWhitelisted(address freeNodeWalletAddress);

    /// @notice It will put log to the multiple free node wallets those added to the whitelist in bulk
    /// @dev It will be emitted once multiple free nodes are added to the whitelist
    /// @param freeNodeWallets is the array of address through which is multiple free nodes are to be whitelisted
    event MultipleFreeNodesWhitelisted(address[] freeNodeWallets);

    /// @notice It will put log to the individual free node wallets those removed from the whitelist
    /// @dev It will be emitted once the free node is removed from the whitelist
    /// @param freeNodeWallet is the address which to be removed from the whitelist
    event FreeNodeRemovedFromWhitelist(address freeNodeWallet);


    error InvalidBatch();
    error InvalidTransaction();
    error DuplicateCluster();
    error ClusterNotVerified();
    error BLSInvalidPubllicKeyorSignaturePoints();
    error BLSIncorrectInputMessaage();
    error FreeNodeIsAlreadyWhitelisted();
    error FreeNodeIsNotWhitelisted();

    event PublicKeyUpdated(uint256[4] publicKey);


    /// @notice This function will work similar to Constructor as we cannot use constructor while using proxy
    /// @dev Initialize the respective variables once and behaves similar to constructor
    /// @param _domain This a part of the data on which BLS Signature will be made.
    /// @param _supraSValueFeedStorage SupraSValueFeedStorage contract address
    /// @param _publicKey BLS public key
    /// @param _blsPrecompileGasCost amount of gas needed to verify the signature
    function initialize(
        bytes32 _domain,
        address _supraSValueFeedStorage,
        uint256[4] memory _publicKey,
        uint256 _blsPrecompileGasCost
    ) public initializer {
        Ownable2StepUpgradeable.__Ownable2Step_init();
        domain = _domain;
        supraSValueFeedStorage = ISupraSValueFeed(_supraSValueFeedStorage);
        publicKey = _publicKey;
        blsPrecompileGasCost = _blsPrecompileGasCost;
    }


    /// @notice Helper function for upgradibility
    /// @dev While upgrading using UUPS proxy interface, when we call upgradeTo(address) function
    /// @dev we need to check that only owner can upgrade
    /// @param newImplementation address of the new implementation contract

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    /// @notice Verify and mark a vote as verified.
    /// @param vote The vote to be verified.
    /// @param sig The signature associated with the vote.
    /// @dev This function verifies the given vote by checking if it has already been verified or if the signature is valid.
    /// @dev   If the vote is verified, it is marked as verified by updating the `verifiedVotes` mapping.
    function requireVoteVerified(Smr.Vote memory vote, uint256[2] calldata sig)
        internal
    {
        bytes32 smrVoteHash = Smr.hashVote(vote);
        if (verifiedVotes[smrVoteHash]) {
            return;
        }

        requireHashVerified(bytes.concat(smrVoteHash), sig);
        verifiedVotes[smrVoteHash] = true;
    }


    /// @notice Verify and process an Oracle Transaction
    /// @dev The vote hash is cached to avoid re-verifying BLS signatures
    /// @dev Each transaction contains price data for multiple pairs
    /// @dev The price data is stored in a separate contract
    /// @dev Stale price data is ignored
    /// @param vote The SMR Vote the transaction is part of
    /// @param smrBatch The SMR Batch the transaction is part of
    /// @param smrTxn The SMR Transaction
    /// @param sccR The Signed Coherent Cluster containing the price data
    /// @param batchIdx The index of the batch in the vote
    /// @param txnIdx The index of the transaction in the batch
    /// @param clusterIdx the index of the EVM cluster hash in the transaction
    /// @param sig The BLS signature of the vote, signed by the contract's authority
    function processCluster(
        Smr.Vote memory vote,
        Smr.MinBatch memory smrBatch,
        Smr.MinTxn memory smrTxn,
        bytes calldata sccR,
        uint256 batchIdx,
        uint256 txnIdx,
        uint256 clusterIdx,
        uint256[2] calldata sig
    ) external {
        requireVoteVerified(vote, sig);
        bytes32 batchHash = Smr.hashBatch(smrBatch);
        if (vote.smrBlock.batchHashes[batchIdx] != batchHash) {
            revert InvalidBatch();
        }
        bytes32 txnHash = Smr.hashTxn(smrTxn);
        if (smrBatch.txnHashes[txnIdx] != txnHash) {
            revert InvalidTransaction();
        }
        if (processedTxns[txnHash]) {
            revert DuplicateCluster();
        }
        processedTxns[txnHash] = true;
        bytes32 sccHash = keccak256(sccR);

        if (smrTxn.clusterHashes[clusterIdx] != sccHash) {
            revert ClusterNotVerified();
        }

        Smr.SignedCoherentCluster memory scc = abi.decode(
            sccR,
            (Smr.SignedCoherentCluster)
        );

        uint256 round = scc.round;

        for (uint256 i=0 ; i < scc.cc.pair.length; ++i) {
            uint256 pair = scc.cc.pair[i];
            uint256 timestamp = scc.cc.timestamp[i];
            uint256 prevTimestamp = supraSValueFeedStorage.getTimestamp(pair);
            if (prevTimestamp > timestamp) {
                continue;
            }
            packData(
                pair,
                round,
                scc.cc.decimals[i],
                timestamp,
                scc.cc.prices[i]
            );
        }
    }



    /// @notice It helps to pack many data points into one single word (32 bytes)
    /// @dev This function will take the required parameters, Will shift the value to its specific position 
    /// @dev For concatenating one value with another we are using unary OR operator 
    /// @dev Saving the Packed data into the SupraStorage Contract 
    /// @param _pair Pair identifier of the token pair
    /// @param _round Round on which DORA nodes collects and post the pair data
    /// @param _decimals Number of decimals that the price of the pair supports
    /// @param _price Price of the pair
    /// @param _time Last updated timestamp of the pair
    function packData(
        uint256 _pair,
        uint256 _round,
        uint256 _decimals,
        uint256 _time,
        uint256 _price
    ) internal {
         uint256 r = uint256(_round) << 192;
        r = r | _decimals << 184;
        r = r | _time << 120;
        r = r | _price << 24;
        supraSValueFeedStorage.restrictedSetSupraStorage(
            _pair,
            bytes32(r)
        );
    }

    /// @dev Requires the provided message to be verified using the contract's authority public key and BLS signature.
    /// @param _message The message to be verified.
    /// @param _signature The BLS signature of the message.
    /// @dev This function verifies the BLS signature by calling the BLS precompile contract and checks if the message matches the provided signature.
    /// @dev If the signature verification fails or if there is an issue with the BLS precompile contract call, the function reverts with an error.
    function requireHashVerified(
        bytes memory _message,
        uint256[2] calldata _signature
    ) public view {
        bool callSuccess;
        bool checkSuccess;
        (checkSuccess, callSuccess) = BLS.verifySingle(
            _signature,
            publicKey,
            BLS.hashToPoint(domain, _message),
            blsPrecompileGasCost
        );
        if (!callSuccess) {
            revert BLSInvalidPubllicKeyorSignaturePoints();
        }
        if (!checkSuccess) {
            revert BLSIncorrectInputMessaage();
        }
    }

    /// @notice Update the contract authority
    /// @dev WARN: The validity of the public key is not verified
    /// @param _publicKey The new contract authority (BN254 public key)
    // TODO: should be signed by old public key instead
    function updatePublicKey(uint256[4] memory _publicKey) public onlyOwner {
        publicKey = _publicKey;

        emit PublicKeyUpdated(_publicKey);
    }

    /// @notice get the current contract authority
    /// @dev The BN254 public key of the Oracle Committee
    /// @return The current contract authority
    function checkPublicKey() external view returns (uint256[4] memory) {
        return publicKey;
    }
}
