pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "./NativeOrdersFeature.sol";

contract TestNativeOrdersFeature is
    NativeOrdersFeature
{
    constructor(
        address zeroExAddress,
        IEtherTokenV06 weth,
        IStaking staking,
        uint32 protocolFeeMultiplier,
        bytes32 greedyTokensBloomFilter
    )
        public
        NativeOrdersFeature(
            zeroExAddress,
            weth,
            staking,
            protocolFeeMultiplier,
            greedyTokensBloomFilter
        )
    {
        // solhint-disable no-empty-blocks
    }

    modifier onlySelf() override {
        _;
    }
}
