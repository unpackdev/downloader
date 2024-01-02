// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IAdapter.sol";
import "./GasPricer.sol";

uint256 constant ZERO_BALANCE_INIT_GAS_COST = 20_000;

struct GasUsage {
    address targetContract;
    address tokenIn;
    address tokenOut;
    uint256 usage;
}

contract GasConsumer is Ownable {
    GasPricer immutable gasPricer;

    constructor(address _gasPricer) {
        gasPricer = GasPricer(_gasPricer);
    }

    function gasUsageByAdapterAndTokens(
        address adapter,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256) {
        return
            gasPricer.gasUsage(
                IAdapter(adapter).targetContract(),
                keccak256(abi.encodePacked(tokenIn, tokenOut))
            );
    }

    function gasUsageByAdapterAndKey(address adapter, bytes32 key)
        internal
        view
        returns (uint256)
    {
        return gasPricer.gasUsage(IAdapter(adapter).targetContract(), key);
    }
}
