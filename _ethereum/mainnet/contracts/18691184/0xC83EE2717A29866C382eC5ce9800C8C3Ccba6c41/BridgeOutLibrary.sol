pragma solidity 0.8.9;

import "./MerkleTreeInterface.sol";
import "./RegimentInterface.sol";
import "./ECDSA.sol";

/**
 * @dev String operations.
 */
library BridgeOutLibrary {
    using ECDSA for bytes32;

    function verifyMerkleTree(
        bytes32 spaceId,
        address merkleTree,
        uint256 leafNodeIndex,
        bytes32 _leafHash
    ) external view {
        bytes32[] memory _merkelTreePath;
        bool[] memory _isLeftNode;
        (, , _merkelTreePath, _isLeftNode) = IMerkleTree(merkleTree)
            .getMerklePath(spaceId, leafNodeIndex);
        require(
            IMerkleTree(merkleTree).merkleProof(
                spaceId,
                IMerkleTree(merkleTree).getLeafLocatedMerkleTreeIndex(
                    spaceId,
                    leafNodeIndex
                ),
                _leafHash,
                _merkelTreePath,
                _isLeftNode
            ),
            "failed to swap token"
        );
    }

    function verifySignature(
        bytes32 regimentId,
        bytes calldata _report,
        bytes32[] calldata _rs,
        bytes32[] calldata _ss,
        bytes32 _rawVs,
        address regiment
    ) external view returns (uint256, bytes32) {
        require(
            IRegiment(regiment).IsRegimentMember(regimentId, msg.sender),
            "no permission to transmit"
        );
        bytes32 messageDigest = keccak256(_report);
        address[] memory signers = new address[](_rs.length);
        for (uint256 i = 0; i < _rs.length; i++) {
            signers[i] = messageDigest.recover(
                uint8(_rawVs[i]) + 27,
                _rs[i],
                _ss[i]
            );
        }
        require(
            IRegiment(regiment).IsRegimentMembers(regimentId, signers),
            "no permission to sign"
        );
        (uint256 receiptIndex, bytes32 receiptHash) = decodeReport(_report);
        return (receiptIndex, receiptHash);
    }

    function decodeReport(
        bytes memory _report
    ) internal pure returns (uint256 receiptIndex, bytes32 receiptHash) {
        (, , receiptIndex, receiptHash) = abi.decode(
            _report,
            (uint256, uint256, uint256, bytes32)
        );
    }

    function generateTokenKey(
        address token,
        string memory chainId
    ) external pure returns (bytes32) {
        return sha256(abi.encodePacked(token, chainId));
    }

    function computeLeafHash(
        string memory _receiptId,
        uint256 _amount,
        address _receiverAddress
    ) external pure returns (bytes32 _leafHash) {
        bytes32 _receiptIdHash = sha256(abi.encodePacked(_receiptId));
        bytes32 _hashFromAmount = sha256(abi.encodePacked(_amount));
        bytes32 _hashFromAddress = sha256(abi.encodePacked(_receiverAddress));
        _leafHash = sha256(
            abi.encode(_receiptIdHash, _hashFromAmount, _hashFromAddress)
        );
    }
}
