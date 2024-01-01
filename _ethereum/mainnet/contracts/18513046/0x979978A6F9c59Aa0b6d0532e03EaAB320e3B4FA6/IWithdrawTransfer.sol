// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct WithdrawRequest {
    string requestId;
    address tokenAddress;
    address fromHotWallet;
    address receiverAddress;
    uint256 amount;
}

interface IWithdrawTransfer {
    event Withdraws(WithdrawRequest[] withdrawRequests);
    event Withdraw(
        string[] requestIds,
        address[] tokenAddresses,
        address[] fromHotWallets,
        address[] receivers,
        uint256[] amounts
    );

    function withdrawTransfers(
        WithdrawRequest[] memory withdrawRequests
    ) external payable;
}
