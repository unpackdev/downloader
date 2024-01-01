// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NFTDrop {
    event ProxyCreated(address indexed proxyAddress);
    function deployMinimalProxy(address _logic) public returns (address) {
        bytes20 targetBytes = bytes20(_logic);
        address clone;
        assembly {
            let cloneAddress := mload(0x40)
            mstore(cloneAddress, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(cloneAddress, 0x14), targetBytes)
            mstore(add(cloneAddress, 0x28), 0x5af43d82803e903d91602b57fd5bf3)
            clone := create(0, cloneAddress, 0x37)
        }
        emit ProxyCreated(clone);
        return clone;
    }
}
