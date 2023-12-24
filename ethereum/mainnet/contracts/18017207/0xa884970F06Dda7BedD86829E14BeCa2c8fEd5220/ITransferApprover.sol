// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ITransferApprover {
    function checkTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
