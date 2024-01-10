// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";

library LibTradingFee {
    function _divCeil(uint128 _numerator, uint128 _denominator) internal pure returns (uint128 _out) {
        _out = (_numerator + _denominator - 1) / _denominator;
    }

    function _calculateFee(uint128 _value, uint128 _feeNumerator) internal pure returns (uint128 _fee) {
        _fee = _divCeil(_value, 1000) * _feeNumerator;
    }

    function _calculateFeeInverse(uint128 _value, uint128 _feeNumerator) internal pure returns (uint128 _feeInverse) {
        _feeInverse = _divCeil(_value, 1000 - _feeNumerator) * _feeNumerator;
    }

    function _calculateBaseFee(uint128 _value) internal view returns (uint128 _fee) {
        _fee = _calculateFee(_value, LibAppStorage._diamondStorage().baseFeeNumerator);
    }

    function _calculateBaseFeeInverse(uint128 _value) internal view returns (uint128 _feeInverse) {
        _feeInverse = _calculateFeeInverse(_value, LibAppStorage._diamondStorage().baseFeeNumerator);
    }

    function _calculateRoundFee(uint128 _value) internal view returns (uint128 _fee) {
        _fee = _calculateFee(_value, LibAppStorage._diamondStorage().roundFeeNumerator);
    }

    function _calculateRoundFeeInverse(uint128 _value) internal view returns (uint128 _feeInverse) {
        _feeInverse = _calculateFeeInverse(_value, LibAppStorage._diamondStorage().roundFeeNumerator);
    }

    function _calculateNftFee(uint128 _value) internal view returns (uint128 _fee) {
        _fee = _calculateFee(_value, LibAppStorage._diamondStorage().nftFeeNumerator);
    }

    function _calculateNftFeeInverse(uint128 _value) internal view returns (uint128 _fee) {
        _fee = _calculateFeeInverse(_value, LibAppStorage._diamondStorage().nftFeeNumerator);
    }
}
