// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ProxyBeacon.sol";

/**
 * @title IDepositAddressMaker
 * @notice The DepositAddressMaker contract is needed to deploy proxy contracts for the DepositMover contract implementation.
 * Only the owner of the factory contract can deploy new proxy contracts
 */
interface IDepositAddressMaker {
    /**
     * @notice Emitted when a DepositMover contract is deployed
     * @param proxyAddr The address of the deployed DepositMover contract
     * @param executorAddr The address of the executor associated with the DepositMover contract
     * @param massDepositMover The address of the mass deposit mover contract associated with the DepositMover
     */
    event DepositMoverDeployed(address proxyAddr, address executorAddr, address massDepositMover);

    error DepositAddressMakerZeroExecutorAddress();

    /**
     * @notice Initialize the DepositAddressMaker contract
     * @dev This function is used to initialize the DepositAddressMaker contract with the provided hot wallet address and DepositMover implementation address
     * @param hotwallet_ The address of the hot wallet associated with the DepositMover contracts
     * @param depositMoverImplAddr_ The address of the DepositMover implementation contract
     */
    function __DepositAddressMaker_init(
        address hotwallet_,
        address depositMoverImplAddr_
    ) external;

    /**
     * @notice Set a new implementation address for the DepositMover contract
     * @dev This function allows the contract owner to set a new implementation address for the DepositMover contract
     * @param newImplementation_ The address of the new implementation contract
     */
    function setNewImplementation(address newImplementation_) external;

    /**
     * @notice Set a new hot wallet address
     * @dev This function allows the contract owner to set a new hot wallet address
     * @param newHotwallet_ The address of the new hot wallet
     */
    function setHotwallet(address newHotwallet_) external;

    /**
     * @notice Deploy a new DepositMover contract
     * @dev This function deploys a new DepositMover contract proxy with the provided executor address
     * Emits a `DepositMoverDeployed` event upon successful deployment
     * @param executorAddr_ The address of the executor
     * @param massDepositMoverAddr_ The address of the mass deposit mover contract
     */
    function deployDepositMover(address executorAddr_, address massDepositMoverAddr_) external;

    /**
     * @notice Get the ProxyBeacon for the DepositMover contracts
     * @return The ProxyBeacon contract
     */
    function depositMoverBeacon() external view returns (ProxyBeacon);

    /**
     * @notice Get the hot wallet address
     * @dev This function returns the address of the hot wallet
     * @return The hot wallet address
     */
    function hotwallet() external view returns (address);

    /**
     * @notice Get the DepositMover contract at the specified index
     * @dev This function returns the address of the DepositMover contract at the specified index in the list of deployed contracts
     * @param index_ The index of the DepositMover contract
     * @return The address of the DepositMover contract
     */
    function depositMoverContracts(uint256 index_) external view returns (address);

    /**
     * @notice Get the number of deployed DepositMover contracts
     * @dev This function returns the total number of deployed DepositMover contracts
     * @return The count of DepositMover contracts
     */
    function getDepositMoverContractsCount() external view returns (uint256);

    /**
     * @notice Get the implementation address of the DepositMover contract
     * @dev This function returns the address of the implementation contract used for deploying DepositMover proxy contracts
     * @return The implementation address of the DepositMover contract
     */
    function getDepositMoverImpl() external view returns (address);
}
