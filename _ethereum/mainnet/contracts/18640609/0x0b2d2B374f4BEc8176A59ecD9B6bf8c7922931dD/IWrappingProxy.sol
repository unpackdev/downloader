// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWrappingProxy {
    function unwrapAndTransfer(address receiver, uint256 amount) external;

    function wrapAndAddToDCSDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external;
}
