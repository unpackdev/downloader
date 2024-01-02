// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IMapleWithdrawalManagerInitializer {

    /**
     *  @dev               Emitted when the withdrawal manager proxy contract is initialized.
     *  @param pool        Address of the pool contract.
     *  @param poolManager Address of the pool manager contract.
     */
    event Initialized(address indexed pool, address indexed poolManager);

}
