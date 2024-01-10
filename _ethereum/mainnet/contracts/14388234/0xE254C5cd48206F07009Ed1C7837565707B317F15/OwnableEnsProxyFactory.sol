//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Clones.sol";
import "./OwnableEnsProxy.sol";

contract OwnableEnsProxyFactory {
    address private immutable _prototype;

    event OwnableEnsProxyCreated(
        address indexed owner,
        address ensProxyAddress
    );

    constructor(address ensRegistry) {
        OwnableEnsProxy ownableEnsProxy = new OwnableEnsProxy(
            ensRegistry,
            address(this)
        );
        _prototype = address(ownableEnsProxy);
    }

    function createEnsProxy() public {
        address contractAddress = Clones.clone(_prototype);
        emit OwnableEnsProxyCreated(msg.sender, contractAddress);
        OwnableEnsProxy(contractAddress).initializeFromFactory(msg.sender);
    }

    function ensProxyPrototype() public view returns (address) {
        return _prototype;
    }
}
