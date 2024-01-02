// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import "./Module.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./Relayer.sol";
import "./MotivatorV2.sol";

/**
 * @title Nouns Relayer Factory
 * @author Federation - https://x.com/FederationWTF
 */
contract NounsRelayerFactory is Ownable {
    /**
     * @notice A new relayer has been created
     * @param _address The address of the new relayer
     * @param _config The relayer config
    */
    event Created(address _address, Relayer.Config _config);

    /// The address of the relayer implementation
    address public implementation;

    /**
     * @notice Initializes the factory
     * @param _implementation The address of the implementation
     */
    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @notice Deploys a new relayer
     * @param _config The contract config
     * @param _motivatorConfig The motivator config
     * @return _address The address of the new relayer
     */
    function clone(
        Relayer.Config calldata _config,
        MotivatorV2.MotivatorConfig calldata _motivatorConfig
    ) external returns (address _address) {
        address instance = Clones.clone(implementation);

        Module(instance).init(abi.encode(_config, _motivatorConfig));

        emit Created(instance, _config);

        return instance;
    }

    /**
     * @notice Sets the implementation address
     * @param _implementation The new implementation address
     */
    function setImplementation(address _implementation) external onlyOwner {
        implementation = _implementation;
    }
}
