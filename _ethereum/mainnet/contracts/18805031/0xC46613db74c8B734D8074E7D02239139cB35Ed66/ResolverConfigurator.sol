// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IRouterV3.sol";
import "./TokenType.sol";

/// @title  ResolverConfigurator
/// @notice Abstract contract which is respopnsible for router contracts updates in the system
/// It encapsulates the ACL logic and ability to change root Router for the contract
abstract contract ResolverConfigurator {
    IRouterV3 public router;

    event NewPathfinder(address indexed);

    error RouterOnlyException();
    error RouterOwnerOnlyException();
    error MigrationErrorException();

    constructor(address _router) {
        router = IRouterV3(_router);
        _updateRouterComponents();
    }

    modifier routerOwnerOnly() {
        if (!router.isRouterConfigurator(msg.sender)) {
            revert RouterOwnerOnlyException();
        }
        _;
    }

    modifier routerOnly() {
        if (msg.sender != address(router)) revert RouterOnlyException();
        _;
    }

    function updateComponents() external routerOnly {
        // [TODO]: Add events(?)
        _updateRouterComponents();
    }

    function updateRouter(address newRouter) external routerOwnerOnly {
        if (newRouter != address(router)) {
            if (!IRouterV3(newRouter).isRouterConfigurator(msg.sender)) {
                revert MigrationErrorException();
            }

            router = IRouterV3(newRouter);
            _updateRouterComponents();

            emit NewPathfinder(newRouter);
        }
    }

    function _updateRouterComponents() internal virtual;

    function tokenType(address token) internal view returns (uint8) {
        return router.tokenTypes(token);
    }

    function isAggregatorType(uint8 tokenType) internal pure returns (bool) {
        return tokenType == TT_NORMAL_TOKEN || tokenType == TT_WRAPPED_TOKEN;
    }
}
