// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IJanusRegistry.sol";
import "./IFactory.sol";

/// @title NextgemStakingPool
/// @notice implements a staking pool for nextgem. Intakes a token and issues another token over time
contract Service {

    address internal _serviceOwner;

    // the service registry controls everything. It tells all objects
    // what service address they are registered to, who the owner is,
    // and all other things that are good in the world.
    address internal _serviceRegistry;

    function _setRegistry(address registry) internal {

        _serviceRegistry = registry;

    }

}
