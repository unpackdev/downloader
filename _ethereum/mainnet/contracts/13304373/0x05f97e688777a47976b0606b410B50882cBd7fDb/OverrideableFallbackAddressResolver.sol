pragma solidity ^0.5.16;

import "./IAddressResolver.sol";
import "./MixinResolver.sol";
import "./Owned.sol";

/// @dev AddressResolver that fallsback to an existing AddressResolver when no overridden entries exiset
contract OverrideableFallbackAddressResolver is IAddressResolver, Owned {
    IAddressResolver public fallbackResolver;
    mapping(bytes32 => address) public overriddenRepository;

    constructor(address _owner, IAddressResolver _fallbackResolver) public Owned(_owner) {
        fallbackResolver = _fallbackResolver;
    }

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    function overrideAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            overriddenRepository[name] = destination;
        }
    }

    function getAddress(bytes32 name) public view returns (address) {
        // Check any overrides before falling back
        address foundAddress = overriddenRepository[name];
        if (foundAddress == address(0)) {
            foundAddress = fallbackResolver.getAddress(name);
        }
        return foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        return fallbackResolver.getSynth(key);
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address foundAddress = getAddress(name);
        require(foundAddress != address(0), reason);
        return foundAddress;
    }
}
