// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

struct SubmissionData {
    address[] targets;
    bytes4[] selectors;
    address[] preCondTargets;
    bytes[] preCondDatas;
    address[] postCondTargets;
    bytes[] postCondDatas;
    address paymentToken;
    bool withFlashloan;
}

struct MerkleTreePath {
    bytes32[] pathHash;
    uint256 index;
}

struct Routes {
    address[] targets;
    bytes4[] selectors;
    address[] preCondTargets;
    bytes4[] preCondDatasSelectors;
    address[] postCondTargets;
    bytes4[] postCondDatasSelectors;
}

struct ExecutionData {
    address[] targets;
    bytes[] datas;
    address[] preCondTargets;
    bytes[] preCondDatas;
    address[] postCondTargets;
    bytes[] postCondDatas;
    address paymentToken;
    bool withFlashloan;
    uint256 execFee;
}
