// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./ITributaryRegistry.sol";
import "./Governable.sol";

/**
 * Allows a registrar contract to register a new proxy as a block
 * that directs Mirror Token distribution to a tributary.
 * Ensures that the tributary is an Mirror DAO, and that only a valid
 * "Mirror Economic Block" created by a registered registrar, can contribute ETH
 * to the treasury. Otherwise, anyone could send ETH to the treasury to mint Mirror tokens.
 * @author MirrorXYZ
 */
contract TributaryRegistry is Governable, ITributaryRegistry {
    // ============ Mutable Storage ============

    // E.g. crowdfund factory. Can register producer => tributary.
    mapping(address => bool) allowedRegistrar;
    // E.g. crowdfund proxy => Mirror DAO.
    mapping(address => address) public override producerToTributary;
    // E.g. auctions house. Can send funds and specify tributary directly.
    mapping(address => bool) public override singletonProducer;

    // ============ Modifiers ============

    modifier onlyRegistrar() {
        require(allowedRegistrar[msg.sender], "sender not registered");
        _;
    }

    constructor(address owner_) Governable(owner_) {}

    // ============ Configuration ============

    function addRegistrar(address registrar) public override onlyGovernance {
        allowedRegistrar[registrar] = true;
    }

    function removeRegistrar(address registrar) public override onlyGovernance {
        delete allowedRegistrar[registrar];
    }

    function addSingletonProducer(address producer)
        public
        override
        onlyGovernance
    {
        singletonProducer[producer] = true;
    }

    function removeSingletonProducer(address producer)
        public
        override
        onlyGovernance
    {
        delete singletonProducer[producer];
    }

    // ============ Tributary Configuration ============

    /**
     * Register a producer's (crowdfund, edition etc) tributary. Can only be called
     * by an allowed registrar.
     */
    function registerTributary(address producer, address tributary)
        public
        override
        onlyRegistrar
    {
        producerToTributary[producer] = tributary;
    }

    /**
     * Allows the current tributary to update to a new tributary.
     */
    function changeTributary(address producer, address newTributary)
        public
        override
        onlyRegistrar
    {
        // Check that the sender of the transaction is the current tributary.
        require(
            msg.sender == producerToTributary[producer],
            "only for current tributary"
        );

        // Allow the current tributary to update to a new tributary.
        producerToTributary[producer] = newTributary;
    }
}
