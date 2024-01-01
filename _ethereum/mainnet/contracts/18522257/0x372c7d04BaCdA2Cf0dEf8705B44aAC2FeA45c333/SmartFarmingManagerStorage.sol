// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ISmartFarmingManager.sol";

// solhint-disable var-name-mixedcase, max-states-count
abstract contract SmartFarmingManagerStorageV1 is ISmartFarmingManager {
    /**
     * @notice Cross-chain Leverage request data
     */
    struct CrossChainLeverage {
        uint16 dstChainId;
        IERC20 bridgeToken;
        IDepositToken depositToken;
        ISyntheticToken syntheticToken;
        uint256 amountIn;
        uint256 debtAmount;
        uint256 depositAmountMin;
        address account;
        bool finished;
        IERC20 tokenIn;
    }

    /**
     * @notice Cross-chain Flash repay request data
     */
    struct CrossChainFlashRepay {
        uint16 dstChainId;
        ISyntheticToken syntheticToken;
        uint256 repayAmountMin;
        address account;
        bool finished;
    }

    /**
     * @notice Cross-chain requests counter
     */
    uint256 public crossChainRequestsLength;

    /**
     * @notice Cross-chain leverage requests
     */
    mapping(uint256 => CrossChainLeverage) public crossChainLeverages;

    /**
     * @notice Cross-chain flash repay requests
     */
    mapping(uint256 => CrossChainFlashRepay) public crossChainFlashRepays;
}
