// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.21;

contract PancakeV2Callback {
    bytes4 private constant _UNISWAP_PAIR_RESERVES_CALL_SELECTOR = 0x0902f1ac; // getReserves()

    /// @notice Pancake swap callback
    /// @param amount0 - The change in token0 reserves from the swap.
    /// @param amount1 - The change in token1 reserves from the swap.
    /// @param data - The data packed into the swap.
    function pancakeCall(address, uint256 amount0, uint256 amount1, bytes calldata data) external {
        assembly {
            // Start at fmp
            let freeMemoryPointer := mload(0x40)
            let token := calldataload(data.offset)
            let fee := calldataload(add(data.offset, 0x20))
            mstore(freeMemoryPointer, _UNISWAP_PAIR_RESERVES_CALL_SELECTOR) // getReserves()
            if iszero(staticcall(gas(), caller(), freeMemoryPointer, 0x4, freeMemoryPointer, 0x40)) {
                // Revert if the call failed.
                revert(0, 0)
            }

            if iszero(eq(returndatasize(), 0x60)) {
                mstore(0, 0x85cd58dc00000000000000000000000000000000000000000000000000000000) // ReservesCallFailed()
                revert(0, 4)
            }

            let reserve0 := mload(freeMemoryPointer)
            let reserve1 := mload(add(freeMemoryPointer, 0x20))

            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            switch eq(amount1, 0)
            case 0 {
                mstore(
                    add(freeMemoryPointer, 36),
                    add(div(mul(mul(reserve0, amount1), 100000), mul(sub(reserve1, amount1), sub(100000, fee))), 1)
                )
            }
            default {
                mstore(
                    add(freeMemoryPointer, 36),
                    add(div(mul(mul(reserve1, amount0), 100000), mul(sub(reserve0, amount0), sub(100000, fee))), 1)
                )
            }
            if iszero(
                and(
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
                )
            ) {
                // Revert if the call failed.
                revert(0, 0)
            }
        }
    }
}
