// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IModule
 * @notice Interface for a Module.
 */
interface IModule {

    /**	
     * @notice Adds a module to a vault. Cannot execute when vault is locked (or under recovery)	
     * @param _vault The target vault.	
     * @param _module The modules to authorise.	
     */	
    function addModule(address _vault, address _module, bytes memory _initData) external;

    /**
     * @notice Inits a Module for a vault by e.g. setting some vault specific parameters in storage.
     * @param _vault The target vault.
     * @param _initData - Data to be initialised specific to a module when it is authorized.
     */
    function init(address _vault, bytes calldata _initData) external;


    /**
     * @notice Returns whether the module implements a callback for a given static call method.
     * @param _methodId The method id.
     */
    function supportsStaticCall(bytes4 _methodId) external view returns (bool _isSupported);
}