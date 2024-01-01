// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./IVersioned.sol";
import "./IProofFeedsCommons.sol";


interface IProofFeeds is IVersioned, IProofFeedsCommons {

    struct MetricData {
        string name;
        uint256 value;
        uint32 updateTs;
    }

    struct CheckedData {
        bytes32[] merkleTreeProof;
        MetricData metricData;
    }

    function requireValidProof(
        SignedMerkleTreeRoot calldata signedMerkleTreeRoot_,
        CheckedData calldata checkedData_
    ) external view;

    function isProofValid(
        SignedMerkleTreeRoot calldata signedMerkleTreeRoot_,
        CheckedData calldata checkedData_
    ) external view returns (bool);
}
