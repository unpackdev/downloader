//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

import "./LibErrors.sol";

contract AutoProxy is Proxy {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    address public immutable beacon;
    bytes32 private immutable _implKey;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(
        address beacon_,
        bytes32 implKey_,
        bytes memory data
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        if (!Address.isContract(beacon_)) revert IsNotContract(beacon_);

        beacon = beacon_;
        _implKey = implKey_;

        address impl = _implementation();
        _setImplementation(impl);
        if (data.length > 0) Address.functionDelegateCall(impl, data);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address impl) {
        (bool success, bytes memory ret) = beacon.staticcall(abi.encodeWithSignature("getAddress(bytes32)", _implKey));
        require(success, "call becaon failed");
        impl = abi.decode(ret, (address));
        require(impl != address(0), "impl is zero");
    }

    function _setImplementation(address newImplementation) private {
        if (!Address.isContract(newImplementation)) revert IsNotContract(newImplementation);
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
        emit Upgraded(newImplementation);
    }

    function _beforeFallback() internal override {
        //check and update
        address implStorage = StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
        address implTrue = _implementation();
        if (implTrue != implStorage) {
            _setImplementation(implTrue);
        }
    }
}
