// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./CloneLibrary.sol";

/// @author Alchemy Team
/// @title AlchemizeFactory
contract AlchemizeFactory {
    using CloneLibrary for address;

    event NewAlchemize(address alchemize);
    event FactoryOwnerChanged(address newowner);
    event NewAlchemizeImplementation(address newAlchemizeFImplementation);

    address payable public factoryOwner;
    address public alchemizeImplementation;

    constructor(
        address _alchemizeImplementation
    )
    {
        require(_alchemizeImplementation != address(0), "No zero address for _alchemizeImplementation");

        factoryOwner = msg.sender;
        alchemizeImplementation = _alchemizeImplementation;

        emit FactoryOwnerChanged(factoryOwner);
        emit NewAlchemizeImplementation(alchemizeImplementation);
    }

    function alchemizeMint()
    external
    returns(address alchemize)
    {
        alchemize = alchemizeImplementation.createClone();
        emit NewAlchemize(alchemize);
    }

    /**
     * @dev lets the owner change the current alchemize Implementation
     *
     * @param alchemizeImplementation_ the address of the new implementation
    */
    function newAlchemizeImplementation(address alchemizeImplementation_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(alchemizeImplementation_ != address(0), "No zero address for alchemizeImplementation_");

        alchemizeImplementation = alchemizeImplementation_;
        emit NewAlchemizeImplementation(alchemizeImplementation);
    }

    /**
     * @dev lets the owner change the ownership to another address
     *
     * @param newOwner the address of the new owner
    */
    function newFactoryOwner(address payable newOwner) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(newOwner != address(0), "No zero address for newOwner");

        factoryOwner = newOwner;
        emit FactoryOwnerChanged(factoryOwner);
    }
}
