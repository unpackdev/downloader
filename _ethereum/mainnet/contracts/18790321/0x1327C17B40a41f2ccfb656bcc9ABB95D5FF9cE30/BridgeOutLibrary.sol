pragma solidity 0.8.9;

import "./MerkleTreeInterface.sol";
import "./RegimentInterface.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

/**
 * @dev String operations.
 */
library BridgeOutLibrary {
    using ECDSA for bytes32;
    using SafeMath for uint256;

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
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes32 rawVs,
        address regiment
    ) external view returns (uint8) {
        require(
            IRegiment(regiment).IsRegimentMember(regimentId, msg.sender),
            "no permission to transmit"
        );
        uint8 signersCount = 0;
        bytes32 messageDigest = keccak256(report);
        address[] memory signers = new address[](rs.length);
        for (uint256 i = 0; i < rs.length; i++) {
            address signer = messageDigest.recover(
                uint8(rawVs[i]) + 27,
                rs[i],
                ss[i]
            );
            require(!_contains(signers,signer), "non-unique signature");
            signers[i] = signer;
            signersCount = uint8(uint256(signersCount).add(1));
        }
        require(
            IRegiment(regiment).IsRegimentMembers(regimentId, signers),
            "no permission to sign"
        );   
        return signersCount;
    }

    function checkSignersThresholdAndDecodeReport(uint8 signersCount, uint8 threshold, bytes calldata report) external pure returns (uint256, bytes32){
        require(
            signersCount >= threshold, "not enough signers"
        );
        (uint256 receiptIndex, bytes32 receiptHash) = decodeReport(report);
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

    function _contains(address[] memory array, address target) internal pure returns(bool) {
        for (uint i = 0; i < array.length; i++) {
            if (target == array[i]) {
                return true;
            }
        }
        return false;
    }
}
