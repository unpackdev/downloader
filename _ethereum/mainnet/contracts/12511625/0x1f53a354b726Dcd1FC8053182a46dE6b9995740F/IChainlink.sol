// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

// See https://etherscan.io/address/0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a#code
interface IChainLinkFeedsRegistry {
    function getPriceETH(address tokenIn) external view returns (uint256);

    function getPriceUSD(address tokenIn) external view returns (uint256);
}
