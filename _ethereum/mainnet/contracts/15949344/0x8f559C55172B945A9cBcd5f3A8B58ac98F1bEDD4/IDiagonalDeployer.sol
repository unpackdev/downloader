// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title IDiagonalDeployer contract interface
 * @author Diagonal Finance
 * @notice DiagonalDeployer handles the deployment of all Diagonal contracts
 */
interface IDiagonalDeployer {
    /**
     * @notice Emitted when contract deployed
     * @param addr The address of the deployed contract
     * @param salt The salt used
     */
    event Deployed(address addr, uint256 salt);

    /**
     * @notice Deploys contract using CREATE2
     * @param code The bytecode of the contract
     * @param salt The salt used
     * @return addr The address of the contract
     */
    function deploy(bytes memory code, uint256 salt) external returns (address addr);

    /**
     * @notice Returns the address from `deploy(code, salt)`, without deploying
     * @param code The bytecode of the contract
     * @param salt The salt used
     * @return addr The address of the contract
     */
    function getAddress(bytes memory code, uint256 salt) external view returns (address addr);
}
