// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./SupraErrors.sol";
import "./Smr.sol";
import "./ISupraSValueFeed.sol";
import "./ISupraSValueFeedVerifier.sol";
import {Ownable2StepUpgradeable} from
"../lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/// @title Supra Oracle Pull Model Contract
/// @notice This contract verifies SMR transactions and returns the price data to the caller
/// @notice The contract does not make assumptions about its owner, but its recommended to be a multisig wallet
contract SupraOraclePull is Ownable2StepUpgradeable, UUPSUpgradeable {
    /// @notice Push Based Supra Svalue Feed Storage contract
    /// @dev This is used to check if a pair is stale
    ISupraSValueFeed internal supraSValueFeedStorage;
    ISupraSValueFeedVerifier internal supraSValueVerifier;

    event SupraSValueFeedUpdated(address supraSValueFeedStorage);
    event SupraSValueVerifierUpdated(address supraSValueVerifier);
    event PriceUpdate(uint256[] pairs,uint256[] prices,uint256[] updateMask);

    /// @notice Proof for verifying and extracting pairs from SMR transactions
    struct OracleProof {
        // list of SMR votes
        Smr.Vote[] votes;
        // List of BLS signatures of the votes
        // votes[i] is verified by sigs[i]
        uint256[2][] sigs;
        // List of SMR batches
        Smr.MinBatch[] smrBatches;
        // List of SMR transactions
        Smr.MinTxn[] smrTxns;
        // Abi Encoded Signed Coherent Clusters containing the pairs
        bytes[] clustersRaw;
        // Index of each batch corresponding vote
        // votes[voteIndexes[i]] should correspond to vote of smrBatches[i]
        uint256[] batchToVote;
        // Index of each transaction's corresponding batch
        // smrBatches[txnToBatch[i]] should correspond to batch of smrTxns[i]
        uint256[] txnToBatch;
        // Index to each cluster's corresponding transaction
        // txn = smrTxns[clusterToTxn[i]] should correspond to txn of clustersRaw[i]
        uint256[] clusterToTxn;
        // Index of the cluster's hash in its corresponding transaction
        // txn.clusterHashes[clusterToHash[i]] should correspond to the hash of clustersRaw[i]
        uint256[] clusterToHash;
        // whether to include n'th pair or not
        // n is the position of the pair considering all pairs in all clusters
        // i.e consider 2 clusters with 2 pairs each
        // n for clusters[0].pairs[0] = 0
        // n for clusters[0].pairs[1] = 1
        // n for clusters[1].pairs[0] = 2
        // n for clusters[1].pairs[1] = 3
        bool[] pairMask;
        // Total number of pairs to return
        // i.e number of true values in pairMasks
        // This is for opts
        uint256 pairCnt;
    }

    /// @notice Verified price data
    struct PriceData {
        // List of pairs
        uint256[] pairs;
        // List of prices
        // prices[i] is the price of pairs[i]
        uint256[] prices;
        // List of decimals
        // decimals[i] is the decimals of pairs[i]
        uint256[] decimals;

    }

    /// @notice Helper function for upgradability
    /// @dev While upgrading using UUPS proxy interface, when we call upgradeTo(address) function
    /// @dev we need to check that only owner can upgrade
    /// @param newImplementation address of the new implementation contract

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function initialize(address _supraSValueFeedStorage, address _supraSValueVerifier) public initializer {
        Ownable2StepUpgradeable.__Ownable2Step_init();
        updateSupraSValueFeedInitLevel(ISupraSValueFeed(_supraSValueFeedStorage));
        updateSupraSValueVerifierInitLevel(ISupraSValueFeedVerifier(_supraSValueVerifier));
    }

    /// @notice Verify Oracle Pairs
    /// @dev throws error if proof is invalid
    /// @dev Stale price data is marked
    /// @param _bytesProof The oracle proof to extract the pairs from
    function verifyOracleProof(bytes calldata _bytesProof) external returns (PriceData memory) {

        OracleProof memory proof = abi.decode(_bytesProof, (OracleProof));
        requireVotesVerified(proof.votes, proof.sigs);
        requireBatchesVerified(proof.votes, proof.smrBatches, proof.batchToVote);

        Smr.MinTxn[] memory smrTxns = proof.smrTxns;
        requireTxnsVerfified(proof.smrBatches, smrTxns, proof.txnToBatch);

        bytes[] memory clusters = proof.clustersRaw;
        uint256[] memory clusterToTxn = proof.clusterToTxn;
        uint256[] memory clusterToHash = proof.clusterToHash;
        uint256[] memory updateMask= new uint256[](proof.pairCnt);

        PriceData memory priceData = PriceData(
            new uint256[](proof.pairCnt),
            new uint256[](proof.pairCnt),
            new uint256[](proof.pairCnt)
        );

        uint256 pair = 0;
        uint256 flaggedPairs = 0;

        for (uint256 i = 0; i < clusters.length; ++i) {
            bytes32 clusterHash = keccak256(clusters[i]);
            if (smrTxns[clusterToTxn[i]].clusterHashes[clusterToHash[i]] != clusterHash) {
                revert ClusterNotVerified();
            }

            Smr.SignedCoherentCluster memory scc = abi.decode(clusters[i], (Smr.SignedCoherentCluster));
            for (uint256 j = 0; j < scc.cc.pair.length; ++j) {
                pair += 1;
                if (!proof.pairMask[pair - 1]) {
                    continue;
                }
                priceData.pairs[flaggedPairs] = scc.cc.pair[j];

                priceData.decimals[flaggedPairs] = scc.cc.decimals[j];

                if(scc.cc.timestamp[j] > supraSValueFeedStorage.getTimestamp(scc.cc.pair[j])){
                    packData(scc.cc.pair[j],scc.round,scc.cc.decimals[j],scc.cc.timestamp[j],scc.cc.prices[j]);
                    priceData.prices[flaggedPairs] =scc.cc.prices[j];
                    updateMask[flaggedPairs]=1;
                }
                else if(scc.cc.timestamp[j] < supraSValueFeedStorage.getTimestamp(scc.cc.pair[j]) ) {
                    priceData.prices[flaggedPairs] = supraSValueFeedStorage.getSvalue(scc.cc.pair[j]).price;
                    updateMask[flaggedPairs]=0;
                }
                else {
                    priceData.prices[flaggedPairs] =scc.cc.prices[j];
                    updateMask[flaggedPairs]=0;
                }
                flaggedPairs += 1;
            }
        }
        emit PriceUpdate(priceData.pairs,priceData.prices,updateMask);
        return priceData;
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


    /// @notice Internal Function to check for zero address
    function _ensureNonZeroAddress (address contract_) pure private {
        if (contract_ == address(0)) {
            revert ZeroAddress();
        }
    }

    /// @notice Helper Function to update the supraSValueFeedStorage Contract address during contract initialization
    /// @param supraSValueFeed_ new supraSValueFeed
    function updateSupraSValueFeedInitLevel(ISupraSValueFeed supraSValueFeed_) private {
        _ensureNonZeroAddress(address(supraSValueFeed_));
        supraSValueFeedStorage = supraSValueFeed_;

        emit SupraSValueFeedUpdated(address(supraSValueFeed_));
    }

    /// @notice Helper Function to update the supraSvalueVerifier Contract address during contract initialization
    /// @param supraSvalueVerifier_ new supraSvalueVerifier Contract address
    function updateSupraSValueVerifierInitLevel(ISupraSValueFeedVerifier supraSvalueVerifier_) private {
        _ensureNonZeroAddress(address(supraSvalueVerifier_));
        supraSValueVerifier = supraSvalueVerifier_;

        emit SupraSValueVerifierUpdated(address(supraSvalueVerifier_));
    }


    /// @notice Helper Function to update the supraSValueFeedStorage Contract address in future
    /// @param supraSValueFeed_ new supraSValueFeedStorage Contract address
    function updateSupraSValueFeed(ISupraSValueFeed supraSValueFeed_) external onlyOwner {
        _ensureNonZeroAddress(address(supraSValueFeed_));
        supraSValueFeedStorage = supraSValueFeed_;

        emit SupraSValueFeedUpdated(address(supraSValueFeed_));
    }


    /// @notice Helper Function to check for the address of SupraSValueFeedVerifier contract    
    function checkSupraSValueVerifier() external view returns(address){
        return (address(supraSValueVerifier));
    }

    ///@notice Helper function to check for the address of SupraSValueFeed contract
    function checkSupraSValueFeed() external view returns(address){
        return (address(supraSValueFeedStorage));
    }


    /// @notice Helper Function to update the supraSvalueVerifier Contract address in future
    /// @param supraSvalueVerifier_ new supraSvalueVerifier Contract address
    function updateSupraSValueVerifier(ISupraSValueFeedVerifier supraSvalueVerifier_) external onlyOwner {
        _ensureNonZeroAddress(address(supraSvalueVerifier_));
        supraSValueVerifier = supraSvalueVerifier_;

        emit SupraSValueVerifierUpdated(address(supraSvalueVerifier_));
    }

    /// @notice Verify SMR Txns
    function requireTxnsVerfified(
        Smr.MinBatch[] memory smrBatches,
        Smr.MinTxn[] memory smrTxns,
        uint256[] memory txnToBatch
    ) internal pure {
        if(smrBatches.length!=smrTxns.length || smrTxns.length!=txnToBatch.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < smrTxns.length; ++i) {
            Smr.MinTxn memory smrTxn = smrTxns[i];
            bytes32 txnHash = Smr.hashTxn(smrTxn);
            if (smrBatches[txnToBatch[i]].txnHashes[smrTxn.txnIdx] != txnHash) {
                revert InvalidTransaction();
            }
        }
    }

    /// @notice Verify batches
    function requireBatchesVerified(
        Smr.Vote[] memory votes,
        Smr.MinBatch[] memory smrBatches,
        uint256[] memory batchToVote
    ) internal pure {
        if(votes.length != smrBatches.length || smrBatches.length != batchToVote.length){
            revert ArrayLengthMismatch();
        }
        for (uint256 i = 0; i < smrBatches.length; ++i) {
            Smr.MinBatch memory smrBatch = smrBatches[i];
            bytes32 batchHash = Smr.hashBatch(smrBatch);
            if (votes[batchToVote[i]].smrBlock.batchHashes[smrBatch.batchIdx] != batchHash) {
                revert InvalidBatch();
            }
        }
    }

    /// @notice Verify votes
    /// @dev Requires the provided votes to be verified using SupraSValueFeedVerifierContract contract's authority public key and BLS signature.
    /// @param votes The array of data on which the signature is to be verified.
    /// @param sigs The BLS signature of the array of data in the form of Votes.
    /// @dev This function verifies the BLS signature by calling the SupraSValueFeedVerifierContract that uses BLS precompile contract and checks if the message matches the provided signature.
    /// @dev If the signature verification fails or if there is an issue with the BLS precompile contract call, the function reverts with an error.
    function requireVotesVerified(Smr.Vote[] memory votes, uint256[2][] memory sigs) internal view {
        if( votes.length != sigs.length){
            revert ArrayLengthMismatch();
        }
        for (uint256 i = 0; i < votes.length; ++i) {
            bytes32 smrVoteHash = Smr.hashVote(votes[i]);
            (bool status,)=address(supraSValueVerifier).staticcall(abi.encodeCall(ISupraSValueFeedVerifier.requireHashVerified,(bytes.concat(smrVoteHash), sigs[i])));
            if(!status){
                revert DataNotVerified();
            }
        }
    }
}
