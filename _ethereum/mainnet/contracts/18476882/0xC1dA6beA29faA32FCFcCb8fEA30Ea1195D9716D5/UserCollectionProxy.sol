// SPDX-License-Identifier: MIT
// Proxy for Public Mintable User NFT Collection
pragma solidity 0.8.19;

import "Proxy.sol";

contract UserCollectionProxy is Proxy {

    struct AddressSlot {
        address value;
    }
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    constructor(
        address _implAddress, 
        address _creator,
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) 
    {
        getAddressSlot(_IMPLEMENTATION_SLOT).value = _implAddress;
        emit Upgraded(_implAddress);
        (bool success, ) = 
        _implAddress.delegatecall(
            abi.encodeWithSignature(
                "initialize(address,string,string,string)"
                , _creator, name_, symbol_, _baseurl
            )
        );
        require(success, "Construction failed");
    }


    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
} 