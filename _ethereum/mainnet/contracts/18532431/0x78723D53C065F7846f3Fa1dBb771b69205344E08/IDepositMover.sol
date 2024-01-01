// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IDepositAddressMaker.sol";

/**
 * @title IDepositMover
 * @notice Each DepositMover contract is a special deposit contract for a particular user.
 * During the transfer of tokens or native currency, the backend will catch the event and lock the tokens to the desired network.
 * The contract also provides logic for the output of the native currency and ERC20 tokens, which are on the contract
 */
interface IDepositMover {
    error DepositMoverZeroETHBalance();
    error DepositMoverFailedToSendETH();
    error DepositMoverEmptyTokensArray();
    error DepositMoverUnableToWithdrawFunds();
    error DepositMoverCallerIsNotTheOwnerOrWithdrawalManager();

    /**
     * @notice Function for setting the initial state of the DepositMover contract
     * @dev This function is used to initialize the DepositMover contract with the provided factory and executor address
     * @param factory_ The IDepositAddressMaker contract address
     * @param massDepositMoverAddr_ The address of the mass deposit mover contract
     * @param executorAddr_ The address of the executor
     */
    function __DepositMover_init(
        IDepositAddressMaker factory_,
        address massDepositMoverAddr_,
        address executorAddr_
    ) external;

    /**
     * @notice Function for updating mass deposit mover contract address
     * @dev This function allows the contract owner to update the address of the mass deposit mover
     * @param newMassDepositMoverAddr_ The address of the new mass deposit mover
     */
    function setMassDepositMover(address newMassDepositMoverAddr_) external;

    /**
     * @notice Withdraw ETH from the DepositMover contract
     * @dev This function allows the contract owner or the mass deposit mover to withdraw the available ETH balance from the DepositMover contract
     *
     * DepositMover contract must have ETH on its balance to withdraw successfully
     *
     * If the hotwallet address on the factory contract is zero, the withdrawal will not be allowed
     */
    function withdrawETH() external;

    /**
     * @notice Withdraw ERC20 tokens from the DepositMover contract
     * @dev This function allows the contract owner or the mass deposit mover to withdraw specified ERC20 tokens from the DepositMover contract
     *
     * If the hotwallet address on the factory contract is zero, the withdrawal will not be allowed
     * @param tokens_ The array of ERC20 token addresses to be withdrawn
     */
    function withdrawTokens(address[] calldata tokens_) external;

    /**
     * @notice Get the DepositAddressMaker contract address
     * @dev This function returns the address of the DepositAddressMaker contract associated with this DepositMover contract
     * @return The address of the DepositAddressMaker contract
     */
    function depositAddressMaker() external view returns (IDepositAddressMaker);

    /**
     * @notice Get the mass deposit mover contract address
     * @dev This function returns the address of the mass deposit mover contract associated with this DepositMover contract
     * @return The address of the mass deposit mover
     */
    function massDepositMoverAddr() external view returns (address);
}
