// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0;

/// @title Factory for deploying contracts to deterministic addresses via CREATE3
/// @author zefram.eth
/// @author dinngo
interface ICREATE3Factory {
    /// @notice Deploys a contract using CREATE3
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @param creationCode The creation code of the contract to deploy
    /// @return deployed The address of the deployed contract
    function deploy(
        bytes32 salt,
        bytes memory creationCode
    ) external payable returns (address deployed);

    /// @notice Predicts the address of a deployed contract
    /// @dev The provided salt is hashed to generate the final salt
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @return deployed The address of the contract that will be deployed
    function getDeployed(bytes32 salt) external view returns (address deployed);
}
