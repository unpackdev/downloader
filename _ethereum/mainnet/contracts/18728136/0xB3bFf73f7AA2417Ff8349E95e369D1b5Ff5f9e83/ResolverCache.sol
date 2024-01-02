// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IAddressResolver.sol";

abstract contract ResolverCache is Initializable {
	IAddressResolver public resolver;
	mapping(bytes32 => address) private _addressCache;

	function __ResolverCache_init(address resolver_) internal onlyInitializing {
		resolver = IAddressResolver(resolver_);
	}

	function getAddress(bytes32 name_) public view returns (address) {
		return _addressCache[name_];
	}

	function getRequiredAddress(bytes32 name_, string memory reason_) public view returns (address) {
		address addr = getAddress(name_);
		require(addr != address(0), reason_);
		return addr;
	}

	function rebuildCache() public virtual {
		bytes32[] memory requiredAddresses = _resolverAddressesRequired();
		for (uint256 i = 0; i < requiredAddresses.length; i++) {
			bytes32 name = requiredAddresses[i];
			address addr = resolver.getRequiredAddress(name, "AddressCache: address not found");
			_addressCache[name] = addr;
		}
	}

	function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = _resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != _addressCache[name] || _addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    function _combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    function _resolverAddressesRequired() internal view virtual returns (bytes32[] memory addresses) {}

    uint256[48] private __gap;
}