// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Address.sol";

abstract contract CoinageFactorySLOT {
    // bytes32(uint256(keccak256('eip1967.proxy.coinagefactory')) ))
    bytes32 internal constant COINAGEFACTORY_SLOT =
        0xc7786c8b03ed9d3280cb3993e8a3aa05e40c849d7d1560c7764528bab63ba0ea;

    /// @dev Sets the implementation address of the proxy.
    /// @param newAddress Address of the new coinageFactory.
    function _setCoinageFactory(address newAddress) internal {
        require(
            Address.isContract(newAddress),
            "CoinageFactorySLOT: Cannot set a proxy coinage factory to a non-contract address"
        );

        bytes32 slot = COINAGEFACTORY_SLOT;

        assembly {
            sstore(slot, newAddress)
        }
    }

    function _coinageFactory() internal view returns (address cf) {
        bytes32 slot = COINAGEFACTORY_SLOT;
        assembly {
            cf := sload(slot)
        }
    }
}
