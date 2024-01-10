//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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
