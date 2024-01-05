// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IChainlinkOracle.sol";
import "./CTokens.sol";
import "./IOracleAggregator.sol";
import "./IGelato.sol";
import "./TaskData.sol";

function _getGelatoGasPrice(address _gasPriceOracle) view returns (uint256) {
    return uint256(IChainlinkOracle(_gasPriceOracle).latestAnswer());
}

// Gelato Oracle price aggregator
function _getExpectedReturnAmount(
    address _inToken,
    address _outToken,
    uint256 _amt,
    address _gelato
) view returns (uint256 buyAmt) {
    (buyAmt, ) = IOracleAggregator(IGelato(_gelato).getOracleAggregator())
        .getExpectedReturnAmount(_amt, _inToken, _outToken);
}

function _getGelatoFee(
    uint256 _gasOverhead,
    uint256 _gasStart,
    address _payToken,
    address _gelato
) view returns (uint256 gelatoFee) {
    gelatoFee =
        (_gasStart - gasleft() + _gasOverhead) *
        _getCappedGasPrice(IGelato(_gelato).getGasPriceOracle());

    if (_payToken == ETH) return gelatoFee;

    // returns purely the ethereum tx fee
    (gelatoFee, ) = IOracleAggregator(IGelato(_gelato).getOracleAggregator())
        .getExpectedReturnAmount(gelatoFee, ETH, _payToken);
}

function _getCappedGasPrice(address _gasPriceOracle) view returns (uint256) {
    uint256 oracleGasPrice = _getGelatoGasPrice(_gasPriceOracle);

    // Use tx.gasprice capped by 1.3x Chainlink Oracle
    return
        tx.gasprice <= ((oracleGasPrice * 130) / 100)
            ? tx.gasprice
            : ((oracleGasPrice * 130) / 100);
}

function _returnFuncSigs(bytes[] memory _datas)
    pure
    returns (bytes4[] memory funcSigs)
{
    funcSigs = new bytes4[](_datas.length);
    for (uint256 i = 0; i < _datas.length; i++) {
        bytes4 selector;
        bytes memory bytesToProcess = _datas[i];
        assembly {
            selector := mload(add(0x20, bytesToProcess))
        }
        funcSigs[i] = selector;
    }
}

function _convertActionDataToSubData(ExecutionData memory _executionData)
    pure
    returns (SubmissionData memory receipt)
{
    return
        SubmissionData(
            _executionData.targets,
            _returnFuncSigs(_executionData.datas),
            _executionData.preCondTargets,
            _executionData.preCondDatas,
            _executionData.postCondTargets,
            _executionData.postCondDatas,
            _executionData.paymentToken,
            _executionData.withFlashloan
        );
}

function _encodeSubmissionData(SubmissionData memory _submissionData)
    pure
    returns (bytes32)
{
    return keccak256(abi.encode(_submissionData));
}

function _computeRootHash(
    bytes32 _receiptHash,
    MerkleTreePath memory _merkleTreePath
) pure returns (bytes32) {
    if (_merkleTreePath.pathHash.length == 0) return _receiptHash;

    _merkleTreePath.pathHash[_merkleTreePath.index] = _receiptHash;

    bytes32 rootHash = _getRootHash(_merkleTreePath.pathHash);
    return rootHash;
}

function _getRootHash(bytes32[] memory _hashes) pure returns (bytes32) {
    bytes32 rootHash = _hashes[0];

    for (uint256 i = 1; i < _hashes.length; i++) {
        rootHash = keccak256(abi.encode(rootHash, _hashes[i]));
    }

    return rootHash;
}
