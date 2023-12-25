// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./Structs.sol";

/**
 * @title IFxContractRegistry
 * @author fx(hash)
 * @notice Registry for managing fxhash smart contracts
 */
interface IFxContractRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when contract gets registered
     * @param _contractName Name of the contract
     * @param _hashedName Hashed name of the contract
     * @param _contractAddr Address of the contract
     */
    event ContractRegistered(string indexed _contractName, bytes32 indexed _hashedName, address indexed _contractAddr);

    /**
     * @notice Event emitted when the config information is updated
     * @param _owner Address of the registry owner
     * @param _configInfo Updated config information
     */
    event ConfigUpdated(address indexed _owner, ConfigInfo _configInfo);

    /*//////////////////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Error thrown when array lengths do not match
     */
    error LengthMismatch();

    /**
     * @notice Error thrown when array length is zero
     */
    error LengthZero();

    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the system config information
     */
    function configInfo() external view returns (address, uint32, uint32, uint32, uint64, string memory, string memory);

    /**
     * @notice Mapping of hashed contract name to contract address
     */
    function contracts(bytes32) external view returns (address);

    /**
     * @notice Registers deployed contract addresses based on hashed value of name
     * @param _names Array of contract names
     * @param _contracts Array of contract addresses
     */
    function register(string[] calldata _names, address[] calldata _contracts) external;

    /**
     * @notice Sets the system config information
     * @param _configInfo Config information (lock time, referrer share, default metadata)
     */
    function setConfig(ConfigInfo calldata _configInfo) external;
}
