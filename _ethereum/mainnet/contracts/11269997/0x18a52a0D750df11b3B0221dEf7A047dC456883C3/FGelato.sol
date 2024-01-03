// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./CGelato.sol";
import "./DSMath.sol";

function _getGelatoGasPrice() view returns (uint256) {
    return uint256(GELATO_GAS_PRICE_ORACLE.latestAnswer());
}

function _getGelatoProviderFees(uint256 _gas) view returns (uint256) {
    return mul(_gas, _getGelatoGasPrice());
}
