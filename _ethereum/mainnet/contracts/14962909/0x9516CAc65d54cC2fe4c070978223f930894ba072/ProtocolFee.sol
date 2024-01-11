//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./IBPool.sol";
import "./IProtocolFee.sol";

/**
 * @title ProtocolFee
 * @author Protofire
 * @dev Module for protocol swap fee calculations.
 *
 */
contract ProtocolFee is Ownable, IProtocolFee {
    using SafeMath for uint256;

    uint256 public constant ONE = 10**18;
    uint256 public constant MIN_FEE = ONE / 10**6; // 0.0001%
    uint256 public constant MAX_FEE = ONE / 2; // 50%

    /// @dev Protocol fee % - 10^18 = 100%
    uint256 public protocolFee;
    /// @dev Minimum Protocol fee % - 10^18 = 100%
    uint256 public minProtocolFee;

    /**
     * @dev Emitted when `protocolFee` is set.
     */
    event ProtocolFeeSet(uint256 protocolFee);

    /**
     * @dev Emitted when `minProtocolFee` is set.
     */
    event MinProtocolFeeSet(uint256 minProtocolFee);

    /**
     * @dev Sets the values for {protocolFee} and {minProtocolFee}.
     *
     * Sets ownership to the account that deploys the contract.
     *
     */
    constructor(uint256 _protocolFee, uint256 _minProtocolFee) {
        _setProtocolFee(_protocolFee);
        _setMinProtocolFee(_minProtocolFee);
    }

    /**
     * @dev Sets `_protocolFee` as the new protocolFee.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_protocolFee` should not be the greater than or equal to MIN_FEE and lower than or equal to MAX_FEE.
     *
     * @param _protocolFee The address of the registry.
     */
    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        _setProtocolFee(_protocolFee);
    }

    /**
     * @dev Sets `_minProtocolFee` as the new minProtocolFee.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_minProtocolFee` should not be the greater than or equal to MIN_FEE and lower than or equal to MAX_FEE.
     *
     * @param _minProtocolFee The address of the registry.
     */
    function setMinProtocolFee(uint256 _minProtocolFee) external onlyOwner {
        _setMinProtocolFee(_minProtocolFee);
    }

    /**
     * @dev Sets `_protocolFee` as the new protocolFee.
     *
     * Requirements:
     *
     * - `_protocolFee` should not be the greater than or equal to MIN_FEE and lower than or equal to MAX_FEE.
     *
     * @param _protocolFee The address of the registry.
     */
    function _setProtocolFee(uint256 _protocolFee) internal {
        require(_protocolFee >= MIN_FEE, "ERR_MIN_FEE");
        require(_protocolFee <= MAX_FEE, "ERR_MAX_FEE");
        emit ProtocolFeeSet(_protocolFee);
        protocolFee = _protocolFee;
    }

    /**
     * @dev Sets `_minProtocolFee` as the new minProtocolFee.
     *
     * Requirements:
     *
     * - `_minProtocolFee` should not be the greater than or equal to MIN_FEE and lower than or equal to MAX_FEE.
     *
     * @param _minProtocolFee The address of the registry.
     */
    function _setMinProtocolFee(uint256 _minProtocolFee) internal {
        require(_minProtocolFee >= MIN_FEE, "ERR_MIN_MIN_FEE");
        require(_minProtocolFee <= MAX_FEE, "ERR_MAX_MIN_FEE");
        emit MinProtocolFeeSet(_minProtocolFee);
        minProtocolFee = _minProtocolFee;
    }

    /**
     * @dev Calculates protocol swap fee for single-hop swaps.
     *
     * @param swaps Array of single-hop swaps.
     * @param totalAmountIn Total amount in.
     */
    function batchFee(Swap[] memory swaps, uint256 totalAmountIn) external view override returns (uint256) {
        uint256 totalSwapsFee = 0;

        uint256 totalSwapAmount = 0;
        for (uint256 i = 0; i < swaps.length; i++) {
            totalSwapAmount = totalSwapAmount.add(swaps[i].swapAmount);
        }

        uint256 swapAmountIn = 0;
        for (uint256 i = 0; i < swaps.length; i++) {
            swapAmountIn = totalAmountIn.mul(swaps[i].swapAmount).div(totalSwapAmount);
            totalSwapsFee = totalSwapsFee.add(getPoolFeeAmount(swaps[i].pool, swapAmountIn));
        }

        uint256 feeAmount = getProtocolFeeAmount(totalSwapsFee);

        return Math.max(feeAmount, minProtocolFee.mul(totalAmountIn).div(ONE));
    }

    /**
     * @dev Calculates protocol swap fee for multi-hop swaps.
     *
     * @param swapSequences multi-hop swaps sequence.
     * @param totalAmountIn Total amount in.
     */
    function multihopBatch(Swap[][] memory swapSequences, uint256 totalAmountIn)
        external
        view
        override
        returns (uint256)
    {
        uint256 totalSwapFeeAmount;
        uint256 amountIn = 0;

        for (uint256 i = 0; i < swapSequences.length; i++) {
            amountIn = amountIn.add(swapSequences[i][0].swapAmount);
        }

        // if the summary of incoming amounts of each swap sequence
        // equals to totalAmountIn it means that the swap type is exactIn
        if (totalAmountIn == amountIn) {
            totalSwapFeeAmount = getMultihopSwapFeeExactIn(swapSequences);
        } else {
            totalSwapFeeAmount = getMultihopSwapFeeExactOut(swapSequences, totalAmountIn);
        }

        return Math.max(getProtocolFeeAmount(totalSwapFeeAmount), minProtocolFee.mul(totalAmountIn).div(ONE));
    }

    /**
     * @dev Calculates swap fee for exactIn multi-hop swaps.
     *
     * @param swapSequences multi-hop swaps sequence.
     */
    function getMultihopSwapFeeExactIn(Swap[][] memory swapSequences) internal view returns (uint256) {
        uint256 sequenceIn;
        uint256 singlePoolFeeAmount;
        uint256 totalSwapFeeAmount = 0;

        for (uint256 i = 0; i < swapSequences.length; i++) {
            // Considering that the outgoing value is equivalent to the incoming less the pool fee,
            // all the amounts are expressed in A to be able to calculate the equivalent total fee.
            // So the swapAmount[i][k] = swapAmount[i][k-1] - swapFee[i][k-1]
            sequenceIn = swapSequences[i][0].swapAmount;

            for (uint256 k = 0; k < swapSequences[i].length; k++) {
                singlePoolFeeAmount = getPoolFeeAmount(swapSequences[i][k].pool, sequenceIn);
                totalSwapFeeAmount = totalSwapFeeAmount.add(singlePoolFeeAmount);
                sequenceIn = sequenceIn.sub(singlePoolFeeAmount);
            }
        }

        return totalSwapFeeAmount;
    }

    /**
     * @dev Calculates swap fee for exactOut multi-hop swaps.
     *
     * @param swapSequences multi-hop swaps sequence.
     * @param totalAmountIn Total amount in.
     */
    function getMultihopSwapFeeExactOut(Swap[][] memory swapSequences, uint256 totalAmountIn)
        internal
        view
        returns (uint256)
    {
        uint256 sequenceIn;
        uint256 singlePoolFeeAmount;
        uint256 totalAmountOut = 0;
        uint256 totalSwapFeeAmount = 0;

        for (uint256 k = 0; k < swapSequences.length; k++) {
            totalAmountOut = totalAmountOut.add(swapSequences[k][swapSequences[k].length - 1].swapAmount);
        }

        for (uint256 i = 0; i < swapSequences.length; i++) {
            sequenceIn = totalAmountIn.mul(swapSequences[i][swapSequences[i].length - 1].swapAmount).div(
                totalAmountOut
            );

            for (uint256 j = 0; j < swapSequences[i].length; j++) {
                singlePoolFeeAmount = getPoolFeeAmount(swapSequences[i][j].pool, sequenceIn);
                totalSwapFeeAmount = totalSwapFeeAmount.add(singlePoolFeeAmount);
                sequenceIn = sequenceIn.sub(singlePoolFeeAmount);
            }
        }

        return totalSwapFeeAmount;
    }

    /**
     * @dev Retives protocol fee amount out of the pool fee amount.
     *
     * @param poolFeeAmount Pool fee ammount.
     */
    function getProtocolFeeAmount(uint256 poolFeeAmount) internal view returns (uint256) {
        return protocolFee.mul(poolFeeAmount).div(ONE);
    }

    /**
     * @dev Retives pool swap fee amount.
     *
     * @param pool Pool address.
     * @param swapAmount Total amount in.
     */
    function getPoolFeeAmount(address pool, uint256 swapAmount) internal view returns (uint256) {
        IBPool bPool = IBPool(pool);
        uint256 swapFee = bPool.getSwapFee();
        return swapFee.mul(swapAmount).div(ONE);
    }
}
