// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./console.sol";

import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./FixedPointMath.sol";
import "./IDetailedERC20.sol";
import "./IVaultAdapter.sol";
import "./IyVaultV2.sol";
import "./YearnVaultAdapter.sol";

/// @title YearnVaultAdapter
///
/// @dev A vault adapter implementation which wraps a yEarn vault.
contract YearnVaultAdapterWithIndirection is YearnVaultAdapter {
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using SafeERC20 for IDetailedERC20;
    using SafeERC20 for IyVaultV2;
    using SafeMath for uint256;

    constructor(IyVaultV2 _vault, address _admin) YearnVaultAdapter(_vault, _admin) public {
    }

    /// @dev Sends vault tokens to the recipient
    ///
    /// This function reverts if the caller is not the admin.
    ///
    /// @param _recipient the account to send the tokens to.
    /// @param _amount    the amount of tokens to send.
    function indirectWithdraw(address _recipient, uint256 _amount) external onlyAdmin {
        vault.safeTransfer(_recipient, _tokensToShares(_amount));
    }
}