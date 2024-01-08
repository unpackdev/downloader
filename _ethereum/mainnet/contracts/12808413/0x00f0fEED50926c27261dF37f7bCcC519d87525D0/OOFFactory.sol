// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./CloneLibrary.sol";

/// @author Conjure Finance Team
/// @title ConjureFactory
contract OOFFactory {
    using CloneLibrary for address;

    event NewOOF(address oof);
    event FactoryOwnerChanged(address newowner);
    event NewConjureRouter(address newConjureRouter);
    event NewOOFImplementation(address newOOFImplementation);

    address payable public factoryOwner;
    address public oofImplementation;
    address payable public conjureRouter;

    constructor(
        address _oofImplementation,
        address payable _conjureRouter
    )
    {
        require(_oofImplementation != address(0), "No zero address for _oofImplementation");
        require(_conjureRouter != address(0), "No zero address for conjureRouter");

        factoryOwner = msg.sender;
        oofImplementation = _oofImplementation;
        conjureRouter = _conjureRouter;

        emit FactoryOwnerChanged(factoryOwner);
        emit NewOOFImplementation(oofImplementation);
        emit NewConjureRouter(conjureRouter);
    }

    function oofMint(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_
    )
    external
    returns(address oof)
    {
        oof = oofImplementation.createClone();

        emit NewOOF(oof);

        IOOF(oof).initialize(
            signers_,
            signerThreshold_,
            payoutAddress_,
            subscriptionPassPrice_,
            address(this)
        );
    }

    /**
     * @dev gets the address of the current factory owner
     *
     * @return the address of the conjure router
    */
    function getConjureRouter() external view returns (address payable) {
        return conjureRouter;
    }

    /**
     * @dev lets the owner change the current conjure implementation
     *
     * @param oofImplementation_ the address of the new implementation
    */
    function newOOFImplementation(address oofImplementation_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(oofImplementation_ != address(0), "No zero address for oofImplementation_");

        oofImplementation = oofImplementation_;
        emit NewOOFImplementation(oofImplementation);
    }

    /**
     * @dev lets the owner change the current conjure router
     *
     * @param conjureRouter_ the address of the new router
    */
    function newConjureRouter(address payable conjureRouter_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(conjureRouter_ != address(0), "No zero address for conjureRouter_");

        conjureRouter = conjureRouter_;
        emit NewConjureRouter(conjureRouter);
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

    /**
     * receive function to receive funds
    */
    receive() external payable {}
}

interface IOOF {
    function initialize(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_,
        address factoryContract_
    ) external;
}

