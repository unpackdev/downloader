// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./TransparentUpgradeableProxy.sol";

contract InitializedProxy is TransparentUpgradeableProxy {
    address public factory;

    constructor(
        address _implementationAddress, 
        address _factoryAddress,
        bytes memory _initializationCallData
    ) TransparentUpgradeableProxy(
        _implementationAddress,
        _factoryAddress,
        _initializationCallData
    ) {
        factory = _factoryAddress;
    }
    receive() external payable override {}

    modifier isFactory() {
        require (msg.sender == factory, "InitializedProxy::isFactory(): Must be calling as factory");
        _;
    }
    
    function getProxyImplementation() external view returns(address){
        return _implementation();
    }
}