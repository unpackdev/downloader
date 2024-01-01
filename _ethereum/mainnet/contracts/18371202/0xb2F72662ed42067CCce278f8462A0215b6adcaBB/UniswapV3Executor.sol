// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IUniswapV3Pool.sol";
import "./IUniswapV3SwapCallback.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./Errors.sol";

/**
 * @title UniswapV3Executor
 * @notice Base contract that contains Uniswap V3 specific logic.
 * Uniswap V3 requires specific interface to be implemented so we have to provide a compliant implementation
 */
abstract contract UniswapV3Executor is IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    bytes32 private constant SELECTORS = 0x0dfe1681d21220a7ddca3f430000000000000000000000000000000000000000;
    bytes32 private constant INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    bytes32 private constant PREFIXED_FACTORY_UNI3  = 0xff1F98431c8aD98523631AE4a59f267346ea31F9840000000000000000000000;
    bytes32 private constant PREFIXED_FACTORY_SUSHI = 0xffbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F0000000000000000000000;
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        bool isBadPool;
        uint256 amount;
        IERC20 token;

        assembly {
            function reRevert() {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }

            let workingAddress := mload(0x40) // EVM free memory pointer
            mstore(workingAddress, SELECTORS)

            // we need to write hash just after the address PREFIXED_FACTORY constant in place of its zeroes,
            // hence offset is 21 bytes
            let feeTokensAddress := add(workingAddress, 21)
            if iszero(staticcall(gas(), caller(), workingAddress, 0x4, feeTokensAddress, 0x20)) {
                reRevert()
            }
            if iszero(staticcall(gas(), caller(), add(workingAddress, 0x4), 0x4, add(feeTokensAddress, 32), 0x20)) {
                reRevert()
            }
            if iszero(staticcall(gas(), caller(), add(workingAddress, 0x8), 0x4, add(feeTokensAddress, 64), 0x20)) {
                reRevert()
            }

            switch sgt(amount0Delta, 0)
            case 1 {
                amount := amount0Delta
                token := mload(feeTokensAddress)
            }
            default {
                amount := amount1Delta
                token := mload(add(feeTokensAddress, 32))
            }

            let poolType := calldataload(data.offset)

            switch poolType
            case 0 {
                mstore(workingAddress, PREFIXED_FACTORY_UNI3)
            }
            case 1 {
                mstore(workingAddress, PREFIXED_FACTORY_SUSHI)
            }
            default {
                mstore(workingAddress, 0x0) // TODO: revert with proper message
            }

            mstore(feeTokensAddress, keccak256(feeTokensAddress, 96))
            mstore(add(feeTokensAddress, 32), INIT_CODE_HASH)
            let pool := and(keccak256(workingAddress, 85), ADDRESS_MASK)
            isBadPool := xor(pool, caller())
        }

        if (isBadPool) {
            revert BadUniswapV3LikePool(UniswapV3LikeProtocol.Uniswap);
        }

        token.safeTransfer(msg.sender, amount);
    }
}
