// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ISnxAddressResolver.sol";

contract SnxConfig {
    bytes32 public immutable trackingCode;
    ISnxAddressResolver public immutable addressResolver;
    address public immutable perpsV2MarketData;
    uint8 public immutable maxPerpPositions;

    constructor(
        address _addressResolver,
        address _perpsV2MarketData,
        bytes32 _snxTrackingCode,
        uint8 _maxPerpPositions
    ) {
        addressResolver = ISnxAddressResolver(_addressResolver);
        // https://github.com/Synthetixio/synthetix/blob/master/contracts/PerpsV2MarketData.sol
        perpsV2MarketData = _perpsV2MarketData;
        trackingCode = _snxTrackingCode;
        maxPerpPositions = _maxPerpPositions;
    }
}
