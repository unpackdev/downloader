//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ISwap.sol";

/**
 * @title IProtocolFee
 * @author Protofire
 * @dev ProtocolFee interface.
 *
 */
interface IProtocolFee is ISwap {
    function batchFee(Swap[] memory swaps, uint256 amountIn) external view returns (uint256);

    function multihopBatch(Swap[][] memory swapSequences, uint256 amountIn) external view returns (uint256);
}
