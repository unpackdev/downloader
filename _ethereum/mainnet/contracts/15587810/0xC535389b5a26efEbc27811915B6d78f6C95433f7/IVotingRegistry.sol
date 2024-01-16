// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

interface IVotingRegistry {
    
    /// @notice register a new voting contract
    /// @param contractAddress address of the new voting contract
    /// @param resolver address of the resolver contract
    function register(address contractAddress, address resolver) external;

    /// @notice change resolver
    /// @param contractAddress address of the new voting contract
    /// @param resolver new resolver contract address
    function changeResolver(address contractAddress, address resolver) external;

    /// @notice getter function for the registrar address
    /// @param votingContract address of the new voting contract
    /// @return registrar address of the registrar
    function getRegistrar(address votingContract) external view returns (address registrar);

    /// @notice getter function for the resolver address
    /// @param votingContract address of the new voting contract
    /// @return resolver address of the resolver
    function getResolver(address votingContract) external view returns(address resolver);

    /// @notice checks whether the voting contract is registered
    /// @param votingContract address of the new voting contract
    /// @return registrationStatus a boolean flag that yields true when the contract is registered
    function isRegistered(address votingContract) external view returns(bool registrationStatus);
}