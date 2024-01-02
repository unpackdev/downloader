// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./ProxiedInternals.sol";

import "./Interfaces.sol";

import "./MapleLoanStorage.sol";

/// @title MapleLoanV502Migrator is to update the factory address for each deployed loan.
contract MapleLoanV502Migrator is ProxiedInternals, MapleLoanStorage  {

    fallback() external {
        ( address newFactory_ ) = abi.decode(msg.data, (address));

        require(_factory() != newFactory_, "MLV502M:INVALID_NO_OP");

        address globals = IMapleProxyFactoryLike(_factory()).mapleGlobals();

        require(IGlobalsLike(globals).isInstanceOf("FT_LOAN_FACTORY", newFactory_), "MLV502M:INVALID_FACTORY");

        _setFactory(newFactory_);
    }

}
