// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./MapleProxyFactory.sol";

import "./IMapleLoanFactory.sol";
import { IGlobalsLike }      from "./interfaces/Interfaces.sol";

/// @title MapleLoanFactory deploys Loan instances.
contract MapleLoanFactory is IMapleLoanFactory, MapleProxyFactory {

    address public immutable override oldFactory;

    mapping(address => bool) internal _isLoan;

    constructor(address mapleGlobals_, address oldFactory_) MapleProxyFactory(mapleGlobals_) {
        oldFactory = oldFactory_;
    }

    function createInstance(bytes calldata arguments_, bytes32 salt_)
        override(IMapleProxyFactory, MapleProxyFactory) public returns (
            address instance_
        )
    {
        require(IGlobalsLike(mapleGlobals).canDeploy(msg.sender), "MLF:CI:CANNOT_DEPLOY");

        _isLoan[instance_ = super.createInstance(arguments_, salt_)] = true;
    }

    function isLoan(address instance_) external view override returns (bool) {
        return (_isLoan[instance_] || IMapleLoanFactory(oldFactory).isLoan(instance_));
    }

}
