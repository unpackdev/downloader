// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

contract EFLM is Proxy {
    constructor(string memory name, string memory symbol, string memory baseURI) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x82DECdC495fcD7815F1e5EAd7510aB2bDa3E7CA8;
        (bool success, ) = 0x82DECdC495fcD7815F1e5EAd7510aB2bDa3E7CA8.delegatecall(abi.encodeWithSignature("initialize(string,string,string,address)", name, symbol, baseURI, 0xeA6b5147C353904D5faFA801422D268772F09512));
        require(success, "Initialization failed");
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}
