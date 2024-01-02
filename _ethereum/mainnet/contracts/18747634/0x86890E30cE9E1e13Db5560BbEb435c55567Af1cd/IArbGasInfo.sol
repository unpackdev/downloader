pragma solidity ^0.8.18;

/// Precompiled contract that exists in every Arbitrum Nitro chain at 0x000000000000000000000000000000000000006c.
interface IArbGasInfo {
    // get ArbOS's estimate of the L1 gas price in wei
    function getL1BaseFeeEstimate() external view returns (uint256);
}
