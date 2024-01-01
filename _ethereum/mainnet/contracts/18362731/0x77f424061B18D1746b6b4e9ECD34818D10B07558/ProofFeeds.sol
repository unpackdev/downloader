// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./MerkleProof.sol";

import "./IProofFeeds.sol";
import "./ICoreMultidataFeedsReader.sol";
import "./NonProxiedOwnerMultipartyCommons.sol";
import "./AbstractFeedsWithMetrics.sol";


contract ProofFeeds is IProofFeeds, ICoreMultidataFeedsReader, NonProxiedOwnerMultipartyCommons, AbstractFeedsWithMetrics {

    /**
     * @notice Contract version, using SemVer version scheme.
     */
    string public constant override VERSION = "0.1.0";

    bytes32 public constant override MERKLE_TREE_ROOT_TYPE_HASH = keccak256("MerkleTreeRoot(uint32 epoch,bytes32 root)");

    mapping(uint => uint) internal _values;
    mapping(uint => uint) internal _updateTSsPacked;

    ////////////////////////

    constructor (address sourceContractAddr_, uint sourceChainId_)
        NonProxiedOwnerMultipartyCommons(sourceContractAddr_, sourceChainId_) {

    }

    ///////////////////////

    function requireValidProof(
        SignedMerkleTreeRoot calldata signedMerkleTreeRoot_,
        CheckedData calldata checkedData_
    ) public view override {
        require(isProofValid(signedMerkleTreeRoot_, checkedData_), "MultidataFeeds: INVALID_PROOF");
    }

    function isProofValid(
        SignedMerkleTreeRoot calldata signedMerkleTreeRoot_,
        CheckedData calldata checkedData_
    ) public view override returns (bool) {
        return isSignedMerkleTreeRootValid(signedMerkleTreeRoot_)
            && isCheckedDataValid(signedMerkleTreeRoot_, checkedData_);
    }

    function isSignedMerkleTreeRootValid(SignedMerkleTreeRoot calldata signedMerkleTreeRoot_) internal view returns (bool) {
        return isMessageSignatureValid(
            keccak256(
                abi.encode(MERKLE_TREE_ROOT_TYPE_HASH, signedMerkleTreeRoot_.epoch, signedMerkleTreeRoot_.root)
            ),
            signedMerkleTreeRoot_.v, signedMerkleTreeRoot_.r, signedMerkleTreeRoot_.s
        );
    }

    function isCheckedDataValid(SignedMerkleTreeRoot calldata signedMerkleTreeRoot_, CheckedData calldata checkedData_) internal pure returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(
            signedMerkleTreeRoot_.epoch,
            checkedData_.metricData.name,
            checkedData_.metricData.value,
            checkedData_.metricData.updateTs
        ))));

        return MerkleProof.verifyCalldata(checkedData_.merkleTreeProof, signedMerkleTreeRoot_.root, leaf);
    }

    ////////////////////////////

    function quoteMetrics(string[] calldata names) external view override returns (Quote[] memory quotes) {
        uint length = names.length;
        quotes = new Quote[](length);

        for (uint i; i < length; i++) {
            (bool has, uint id) = hasMetric(names[i]);
            require(has, "MultidataFeeds: INVALID_METRIC_NAME");
            quotes[i] = Quote(_values[id], unpackUpdateTs(id));
        }
    }

    function quoteMetrics(uint256[] calldata ids) external view override returns (Quote[] memory quotes) {
        uint length = ids.length;
        quotes = new Quote[](length);

        uint metricsCount = getMetricsCount();
        for (uint i; i < length; i++) {
            uint id = ids[i];
            require(id < metricsCount, "MultidataFeeds: INVALID_METRIC");
            quotes[i] = Quote(_values[id], unpackUpdateTs(id));
        }
    }

    ////////////////////////////

    /**
     * @notice Upload signed value
     * @dev metric in this instance is created if it is not exists. Important: metric id is different from metric ids from other
     *      instances of ProofFeeds and MedianFeed
     */
    function setValue(SignedMerkleTreeRoot calldata signedMerkleTreeRoot_, CheckedData calldata data_) external {
        requireValidProof(signedMerkleTreeRoot_, data_);

        setMetricValue(data_.metricData);
    }

    /**
     * @notice Upload signed values
     * @dev metric in this instance is created if it is not exists. Important: metric id is different from metric ids from other
     *      instances of ProofFeeds and MedianFeed
     */
    function setValues(SignedMerkleTreeRoot calldata signedMerkleTreeRoot_, CheckedData[] calldata data_) external {
        require(isSignedMerkleTreeRootValid(signedMerkleTreeRoot_), "MultidataFeeds: INVALID_ROOT");

        uint count = data_.length;
        for (uint i = 0; i < count; i++) {
            require(isCheckedDataValid(signedMerkleTreeRoot_, data_[i]), "MultidataFeeds: INVALID_PROOF");

            setMetricValue(data_[i].metricData);
        }
    }

    function setMetricValue(MetricData calldata metricData_) internal {
        (bool has, uint metricId) = hasMetric(metricData_.name);
        if (!has) {
            metricId = addMetric(Metric(metricData_.name, "", "", new string[](0)));
        }

        require(metricData_.updateTs > unpackUpdateTs(metricId), "MultidataFeeds: STALE_UPDATE");

        _values[metricId] = metricData_.value;

        uint tempTsPacked = _updateTSsPacked[metricId / 8];
        uint shift = (metricId % 8) * 32;
        tempTsPacked &= ~(uint(type(uint32).max) << shift);
        tempTsPacked |= (uint(metricData_.updateTs) << shift);
        _updateTSsPacked[metricId / 8] = tempTsPacked;
    }

    function unpackUpdateTs(uint metricId_) internal view returns (uint32) {
        return uint32(
            _updateTSsPacked[metricId_ / 8] >> ((metricId_ % 8) * 32)
        );
    }
}
