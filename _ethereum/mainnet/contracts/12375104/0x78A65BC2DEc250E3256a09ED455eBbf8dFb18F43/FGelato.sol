// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./CGelato.sol";
import "./IChainlinkOracle.sol";
import "./CTokens.sol";
import "./DSMath.sol";
import "./IOracleAggregator.sol";
import "./COracle.sol";
import "./IGelato.sol";

function _getGelatoGasPrice(address _gasPriceOracle) view returns (uint256) {
    return uint256(IChainlinkOracle(_gasPriceOracle).latestAnswer());
}

// Gelato Oracle price aggregator
function _getExpectedBuyAmountFromChainlink(
    address _buyAddr,
    address _sellAddr,
    uint256 _sellAmt
) view returns (uint256 buyAmt) {
    (buyAmt, ) = IOracleAggregator(ORACLE_AGGREGATOR).getExpectedReturnAmount(
        _sellAmt,
        _sellAddr,
        _buyAddr
    );
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