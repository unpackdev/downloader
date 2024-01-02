// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICrossmintFactory {
    /// @notice Deploys a contract to a deterministic address derived only from the deployer and salt
    /// @dev The provided salt is hashed together with msg.sender to create a deployer specific namespace
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @param creationCode The creation code of the contract to deploy
    /// @return deployed The address of the deployed contract
    function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed);

    /// @notice Deploys a contract to a deterministic address derived only from the deployer and salt
    /// @dev The provided salt is hashed together with msg.sender to create a deployer specific namespace
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @param creationCode The creation code of the contract to deploy
    /// @param data The data for calling the newly deployed contract
    /// @return deployed The address of the deployed contract
    function deployAndCall(bytes32 salt, bytes memory creationCode, bytes memory data)
        external
        payable
        returns (address deployed);

    /// @notice Predicts the address of a deployed contract
    /// @dev The provided salt is hashed together with msg.sender to create a deployer specific namespace
    /// @param deployer The account that will call deploy()
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @return deployed The address of the contract that will be deployed
    function getDeployed(address deployer, bytes32 salt) external view returns (address deployed);
}
