// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Not being used I think. Remove if unnecessary.
interface HopBridge {
    function send(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    ) external;
}
