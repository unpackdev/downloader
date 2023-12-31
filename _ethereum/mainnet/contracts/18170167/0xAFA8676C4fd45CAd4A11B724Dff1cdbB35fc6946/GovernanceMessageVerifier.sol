// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RLPReader.sol";
import "./IGovernanceMessageVerifier.sol";
import "./IRootChain.sol";
import "./ITelepathyRouter.sol";
import "./Merkle.sol";
import "./MerklePatriciaProof.sol";

error InvalidGovernanceMessageEmitter(address governanceMessageEmitter, address expecteGovernanceMessageEmitter);
error InvalidTopic(bytes32 topic, bytes32 expectedTopic);
error InvalidReceiptsRootMerkleProof();
error InvalidRootHashMerkleProof();
error InvalidHeaderBlock();
error MessageAlreadyProcessed(IGovernanceMessageVerifier.GovernanceMessageProof proof);
error InvalidNonce(uint256 nonce, uint256 expectedNonce);

contract GovernanceMessageVerifier is IGovernanceMessageVerifier {
    address public constant TELEPATHY_ROUTER = 0x41EA857C32c8Cb42EEFa00AF67862eCFf4eB795a;
    address public constant ROOT_CHAIN_ADDRESS = 0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287;
    bytes32 public constant EVENT_SIGNATURE_TOPIC = 0x85aab78efe4e39fd3b313a465f645990e6a1b923f5f5b979957c176e632c5a07; //keccak256(GovernanceMessage(bytes));

    address public immutable governanceMessageEmitter;

    uint256 public totalNumberOfProcessedMessages;
    mapping(bytes32 => bool) _messagesProcessed;

    constructor(address governanceMessageEmitter_) {
        governanceMessageEmitter = governanceMessageEmitter_;
    }

    /// @inheritdoc IGovernanceMessageVerifier
    function isProcessed(GovernanceMessageProof calldata proof) external view returns (bool) {
        return _messagesProcessed[proofIdOf(proof)];
    }

    /// @inheritdoc IGovernanceMessageVerifier
    function proofIdOf(GovernanceMessageProof calldata proof) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    proof.rootHashProof,
                    proof.rootHashProofIndex,
                    proof.receiptsRoot,
                    proof.blockNumber,
                    proof.blockTimestamp,
                    proof.transactionsRoot,
                    proof.receiptsRootProofPath,
                    proof.receiptsRootProofParentNodes,
                    proof.receipt,
                    proof.logIndex,
                    proof.transactionType,
                    proof.headerBlock
                )
            );
    }

    /// @inheritdoc IGovernanceMessageVerifier
    function verifyAndPropagateMessage(GovernanceMessageProof calldata proof) external {
        bytes32 id = proofIdOf(proof);
        if (_messagesProcessed[id]) {
            revert MessageAlreadyProcessed(proof);
        }
        _messagesProcessed[id] = true;

        // NOTE: handle legacy and eip2718
        RLPReader.RLPItem[] memory receiptData = RLPReader.toList(
            RLPReader.toRlpItem(proof.transactionType == 2 ? proof.receipt[1:] : proof.receipt)
        );
        RLPReader.RLPItem[] memory logs = RLPReader.toList(receiptData[3]);
        RLPReader.RLPItem[] memory log = RLPReader.toList(logs[proof.logIndex]);

        // NOTE: only events emitted from the GovernanceMessageEmitter will be propagated
        address proofGovernanceMessageEmitter = RLPReader.toAddress(log[0]);
        if (governanceMessageEmitter != proofGovernanceMessageEmitter) {
            revert InvalidGovernanceMessageEmitter(proofGovernanceMessageEmitter, governanceMessageEmitter);
        }

        RLPReader.RLPItem[] memory topics = RLPReader.toList(log[1]);
        bytes32 proofTopic = bytes32(RLPReader.toBytes(topics[0]));
        if (EVENT_SIGNATURE_TOPIC != proofTopic) {
            revert InvalidTopic(proofTopic, EVENT_SIGNATURE_TOPIC);
        }

        if (
            !MerklePatriciaProof.verify(
                proof.receipt,
                proof.receiptsRootProofPath,
                proof.receiptsRootProofParentNodes,
                proof.receiptsRoot
            )
        ) {
            revert InvalidReceiptsRootMerkleProof();
        }

        bytes32 blockHash = keccak256(
            abi.encodePacked(proof.blockNumber, proof.blockTimestamp, proof.transactionsRoot, proof.receiptsRoot)
        );

        (bytes32 rootHash, , , , ) = IRootChain(ROOT_CHAIN_ADDRESS).headerBlocks(proof.headerBlock);
        if (rootHash == bytes32(0)) {
            revert InvalidHeaderBlock();
        }

        if (!Merkle.checkMembership(blockHash, proof.rootHashProofIndex, rootHash, proof.rootHashProof)) {
            revert InvalidRootHashMerkleProof();
        }

        bytes memory message = RLPReader.toBytes(log[2]);
        (uint256 nonce, uint32[] memory chainIds, address[] memory hubs, bytes memory data) = abi.decode(
            message,
            (uint256, uint32[], address[], bytes)
        );
        if (nonce != totalNumberOfProcessedMessages) {
            revert InvalidNonce(nonce, totalNumberOfProcessedMessages);
        }
        unchecked {
            ++totalNumberOfProcessedMessages;
        }

        for (uint256 index = 0; index < chainIds.length; ) {
            ITelepathyRouter(TELEPATHY_ROUTER).send(chainIds[index], hubs[index], data);

            unchecked {
                ++index;
            }
        }

        emit GovernanceMessagePropagated(data);
    }
}
