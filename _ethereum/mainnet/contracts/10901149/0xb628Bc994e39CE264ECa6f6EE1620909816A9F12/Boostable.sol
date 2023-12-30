// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ProtectedBoostable.sol";

/**
 * @dev Purpose Boostable primitives using the EIP712 standard
 */
abstract contract Boostable is ProtectedBoostable {
    // "Purpose", "Dubi" and "Hodl" are all under the "Purpose" umbrella
    constructor(address optIn)
        public
        ProtectedBoostable(
            optIn,
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256("Purpose"),
                    keccak256("1"),
                    _getChainId(),
                    address(this)
                )
            )
        )
    {}

    // Fuel alias constants - used when fuel is burned from external contract calls
    uint8 internal constant TOKEN_FUEL_ALIAS_UNLOCKED_PRPS = 0;
    uint8 internal constant TOKEN_FUEL_ALIAS_LOCKED_PRPS = 1;
    uint8 internal constant TOKEN_FUEL_ALIAS_DUBI = 2;
}
