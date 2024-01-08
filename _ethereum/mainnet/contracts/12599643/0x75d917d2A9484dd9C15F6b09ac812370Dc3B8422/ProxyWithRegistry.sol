pragma solidity ^0.7.6;

import "./RegistryInterface.sol";

contract ProxyWithRegistryStorage {

    /**
     * @notice Address of the registry contract
     */
    address public registry;
}

abstract contract ProxyWithRegistryInterface is ProxyWithRegistryStorage {
    function _setRegistry(address _registry) internal virtual;
    function _pTokenImplementation() internal view virtual returns (address);
}

contract ProxyWithRegistry is ProxyWithRegistryInterface {
    /**
     *  Returns actual address of the implementation contract from current registry
     *  @return registry Address of the registry
     */
    function _pTokenImplementation() internal view override returns (address) {
        return RegistryInterface(registry).pTokenImplementation();
    }

    function _setRegistry(address _registry) internal override {
        registry = _registry;
    }
}

contract ImplementationStorage {

    address public implementation;

    function _setImplementation(address implementation_) internal {
        implementation = implementation_;
    }
}