// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UseRouter {
    address private _routerAddress;

    constructor(address routerAddress_) {
        _routerAddress = routerAddress_;
        _setupRouter(routerAddress_);
    }

    function _setupRouter(address routerAddress_) internal virtual {}

    modifier fromRouter() {
        require(
            msg.sender == _routerAddress,
            "Only the router can call this function!"
        );
        _;
    }
}
