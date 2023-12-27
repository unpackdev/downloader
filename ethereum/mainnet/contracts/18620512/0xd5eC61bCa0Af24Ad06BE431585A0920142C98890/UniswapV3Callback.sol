// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.21;

contract UniswapV3Callback {
    ///@notice Uniswap V3 callback function called during a swap on a v3 liqudity pool.
    ///@param amount0Delta - The change in token0 reserves from the swap.
    ///@param amount1Delta - The change in token1 reserves from the swap.
    ///@param data - The data packed into the swap.
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        assembly {
            // Start at fmp
            let freeMemoryPointer := mload(0x40)
            let token := calldataload(data.offset)
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            switch slt(amount0Delta, 0)
            case 0 { mstore(add(freeMemoryPointer, 36), amount0Delta) }
            // Append the "amount" argument. Masking not required as it's a full 32 byte type.
            default { mstore(add(freeMemoryPointer, 36), amount1Delta) } // Append the "amount" argument. Masking not required as it's a full 32 byte type.

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
