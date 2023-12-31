// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStakingWallet {
    function doEth2Deposit(bytes calldata pubkey, bytes calldata signature, bytes32 deposit_data_root) external;

    function withdraw(address user, uint256 ethAmount, uint256 profit) external;
}
