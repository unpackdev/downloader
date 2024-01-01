// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IModuleRegistry
 * @notice Interface for the registry of authorised modules.
 */
interface IKresusRegistry {
    /**
     * @notice Registers a module.
     * @param _module The module.
     * @param _name The unique name of the module.
     */
    function registerModule(address _module, string calldata _name) external;

    /**
     * @notice Deregisters a module.
     * @param _module The module.
     */
    function deregisterModule(address _module) external;

    /**
     * @notice Registers contract addresses with their selectors.
     * @param _contracts Contract addresses to be whitelisted.
     * @param _selectors List of corresponding method ids to be whitelisted.
     */
    function registerContract(address[] memory _contracts, bytes4[] memory _selectors) external;
    
    /**
     * @notice Deregisters contract addresses with their selectors.
     * @param _contracts Contract addresses to be whitelisted.
     * @param _selectors List of corresponding method ids to be whitelisted.
     */
    function deregisterContract(address[] memory _contracts, bytes4[] memory _selectors) external;

    /**
     * @notice Function to set the time delay for remove guardian operation.
     * @param _td New time delay for removing guardian.
     */
    function setRemoveGuardianTd(uint256 _td) external;

    /**
     * @notice Function to set the time delay for unlock operation.
     * @param _td New time delay for unlocking a vault.
     */
    function setUnlockTd(uint256 _td) external;

    /**
     * @notice Gets the name of a module from its address.
     * @param _module The module address.
     * @return the name.
     */
    function moduleInfo(address _module) external view returns (string memory);

    /**
     * @notice Checks if a module is registered.
     * @param _module The module address.
     * @return true if the module is registered.
     */
    function isRegisteredModule(address _module) external view returns (bool);

    /**
     * @notice Checks if given modules are registered.
     * @param _modules The module addresses.
     * @return true if modules are registered.
     */
    function isRegisteredModule(address[] calldata _modules) external view returns (bool);

    /**
     * @notice Checks if given list of contracts addresses and corresponsing method ids are whitelisted.
     * @param _contracts List of contract addresses.
     * @param _sigs List of corresponding method ids.
     * @return true if all the contract addresses and method ids are whitelisted else false.
     */
    function isRegisteredCalls(address[] memory _contracts, bytes4[] memory _sigs) external view returns (bool);

    /**
     * @notice Function to get the time delay for unlock.
     * @return Time delay for unlocking a vault.
     */
    function getUnlockTd() external view returns(uint256); 


    /**
     * @notice Function to get the time delay for remove guardian.
     * @return Time delay for remove guardian.
     */
    function getRemoveGuardianTd() external view returns(uint256); 
}