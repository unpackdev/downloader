// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IERC20.sol";
import "./IRounds.sol";

interface IPreSaleDop is IRounds {
    /// @notice Purchases Dop token with claim amount
    /// @param token The address of investment token
    /// @param tokenPrice The current price of token in 10 decimals
    /// @param referenceNormalizationFactor The value to handle decimals
    /// @param amount The investment amount
    /// @param minAmountDop The minimum amount of dop recipient will get
    /// @param recipient The address of the recipient
    /// @param round The round in which user will purchase
    function purchaseWithClaim(
        IERC20 token,
        uint256 tokenPrice,
        uint8 referenceNormalizationFactor,
        uint256 amount,
        uint256 minAmountDop,
        address recipient,
        uint32 round
    ) external payable;

    /// @notice The helper function which verifies signature, signed by signerWallet, reverts if invalidSignature
    function verifyPurchaseWithClaim(
        address recipient,
        uint32 round,
        uint256 deadline,
        uint256[] calldata tokenPrices,
        uint8[] calldata normalizationFactors,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
