// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./UniswapConfig.sol";

interface ICompoundOracle {
    function price(string memory symbol) external view returns (uint);
    function getUnderlyingPrice(address cToken) external view returns (uint);
    function getTokenConfigBySymbolHash(bytes32 symbolHash) external view returns (UniswapConfig.TokenConfig memory);
}