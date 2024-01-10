// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface DegenFetcherInterface{
	function fetchPriceDataForFeed(address feedAddress, uint fromTimestamp, uint80 daysToFetch, uint dataPointsToFetchPerDay) external view returns (int32[] memory);
}