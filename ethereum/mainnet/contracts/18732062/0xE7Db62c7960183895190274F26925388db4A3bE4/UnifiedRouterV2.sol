// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "./SafeERC20.sol";
import "./RouterV2.sol";
import "./IUnifiedPoolAdapter.sol";


contract UnifiedRouterV2 is RouterV2, IUnifiedRouter {

    event PoolAdapterSet(address pool, address poolAdapter);

    /// @dev add operation code
    bytes32 public constant ADD_CODE = keccak256(abi.encodePacked("A"));
    /// @dev remove operation code
    bytes32 public constant REMOVE_CODE = keccak256(abi.encodePacked("R"));
    /// @dev swap operation code
    bytes32 public constant SWAP_CODE = keccak256(abi.encodePacked("S"));

    /// @dev pool adapters
    mapping(address => address) public poolAdapter;

    constructor(address addressBook_) RouterV2(addressBook_) {}

    /**
     * @dev Sets pool adapter for given pool.
     *
     * Each supported pool must be set.
     *
     * @param pool_ The Curve pool;
     * @param poolAdapter_ The pool adapter for pool_. 
     */
    function setPoolAdapter(
        address pool_,
        address poolAdapter_
    ) external onlyRole(OPERATOR_ROLE) {
        require(pool_ != address(0), "UnifiedRouterV2: zero address");
        poolAdapter[pool_] = poolAdapter_;
    }

    /**
     * @dev Should be implemented for each router.
     *
     * Each implementation must:
     * Revert execution if op is not supported;
     * Return chainId, destination router (if current op is cross-chain) and execution result.
     *
     * @param op operation hash;
     * @param params serialized params corresponding to op.
     */
    function _executeOp(
        bool isOpHalfDone,
        bytes32 op,
        bytes32 nextOp,
        bytes memory params,
        MaskedParams memory prevMaskedParams
    ) internal virtual override returns (uint64 chainIdTo, bytes memory updatedParams, MaskedParams memory maskedParams, ExecutionResult result) {
        (chainIdTo, updatedParams, maskedParams, result) = super._executeOp(isOpHalfDone, op, nextOp, params, prevMaskedParams);
        if (result == ExecutionResult.Failed) {
            result = ExecutionResult.Succeeded;
            if (ADD_CODE == op) {
                AddParams memory p = abi.decode(params, (AddParams));
                address adapter = _getPoolAdapter(p.pool);
                (p.amountIn, p.from, p.emergencyTo) = _checkMaskedParams(p.amountIn, p.from, p.emergencyTo, maskedParams);
                p.to = _checkTo(p.to, p.emergencyTo, uint64(block.chainid), nextOp);

                _transferToAdapter(p.tokenIn, p.from, adapter, p.amountIn);

                maskedParams.amountOut = IUnifiedPoolAdapter(adapter).addLiquidity(
                    p.tokenIn,
                    p.amountIn,
                    p.to,
                    p.pool,
                    p.minAmountOut,
                    p.i,
                    p.emergencyTo
                );
                maskedParams.to = p.to;
                maskedParams.emergencyTo = p.emergencyTo;
                if (maskedParams.amountOut == 0) {
                    if (isOriginNetwork) {
                        revert("UnifiedRouterV2: slippage");
                    }
                    result = ExecutionResult.Interrupted;
                }
            } else if (REMOVE_CODE == op) {
                RemoveParams memory p = abi.decode(params, (RemoveParams));
                address adapter = _getPoolAdapter(p.pool);
                (p.amountIn, p.from, p.emergencyTo) = _checkMaskedParams(p.amountIn, p.from, p.emergencyTo, maskedParams);
                p.to = _checkTo(p.to, p.emergencyTo, uint64(block.chainid), nextOp);

                _transferToAdapter(p.tokenIn, p.from, adapter, p.amountIn);

                maskedParams.amountOut = IUnifiedPoolAdapter(adapter).removeLiquidity(
                    p.tokenIn,
                    p.amountIn,
                    p.to,
                    p.pool,
                    p.minAmountOut,
                    p.j,
                    p.emergencyTo
                );

                maskedParams.to = p.to;
                maskedParams.emergencyTo = p.emergencyTo;
                if (maskedParams.amountOut == 0) {
                    if (isOriginNetwork) {
                        revert("UnifiedRouterV2: slippage");
                    }
                    result = ExecutionResult.Interrupted;
                }
            } else if (SWAP_CODE == op) {
                SwapParams memory p = abi.decode(params, (SwapParams));
                address adapter = _getPoolAdapter(p.pool);
                (p.amountIn, p.from, p.emergencyTo) = _checkMaskedParams(p.amountIn, p.from, p.emergencyTo, maskedParams);
                p.to = _checkTo(p.to, p.emergencyTo, uint64(block.chainid), nextOp);

                _transferToAdapter(p.tokenIn, p.from, adapter, p.amountIn);

                maskedParams.amountOut = IUnifiedPoolAdapter(adapter).swap(
                    p.tokenIn,
                    p.amountIn,
                    p.to,
                    p.pool,
                    p.minAmountOut,
                    p.i,
                    p.j,
                    p.emergencyTo
                );
                maskedParams.to = p.to;
                maskedParams.emergencyTo = p.emergencyTo;
                if (maskedParams.amountOut == 0) {
                    if (isOriginNetwork) {
                        revert("UnifiedRouterV2: slippage");
                    }
                    result = ExecutionResult.Interrupted;
                }
            } else {
                result = ExecutionResult.Failed;
            }
        }
    }

    function _checkTo(address to, address emergencyTo, uint64 chainId, bytes32 nextOp) internal view virtual override returns (address correctTo) {
        correctTo = super._checkTo(to, emergencyTo, chainId, nextOp);
        if (correctTo == address(0)) {
            if (nextOp == ADD_CODE || nextOp == REMOVE_CODE || nextOp == SWAP_CODE) {
                correctTo = IAddressBook(addressBook).router(chainId);
            }
        }
    }

    function _getPoolAdapter(address pool) private view returns (address adapter) {
        adapter = poolAdapter[pool];
        require(adapter != address(0), "UnifiedRouterV2: pool adapter not set");
    }

    function _transferToAdapter(address tokenIn, address from, address adapter, uint256 amountIn) private {
        if (from == address(this)) {
            SafeERC20.safeTransfer(IERC20(tokenIn), adapter, amountIn);
        } else {
            SafeERC20.safeTransferFrom(IERC20(tokenIn), from, adapter, amountIn);
        }
    }
}
