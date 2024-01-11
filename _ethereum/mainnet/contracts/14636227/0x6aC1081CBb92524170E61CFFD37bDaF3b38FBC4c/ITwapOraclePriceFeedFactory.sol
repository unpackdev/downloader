// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ITwapOraclePriceFeedFactory {
    function twapOraclePriceFeedList(address _pair) external view returns (address);

    function getTwapOraclePriceFeed(address _token0, address _token1) external view returns (address twapOraclePriceFeed);
}
