// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
@title L1Bridge Hop Interface
@notice L1 Hop Bridge, Used to transfer from L1 to L2s. 
*/
interface IHopL1Bridge {
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;
}
