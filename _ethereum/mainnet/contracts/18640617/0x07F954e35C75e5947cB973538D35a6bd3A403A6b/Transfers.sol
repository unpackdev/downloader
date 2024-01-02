// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./SafeERC20.sol";
import "./Errors.sol";

library Transfers {
    using SafeERC20 for IERC20;

    function receiveTo(
        address asset,
        address to,
        uint256 amount
    ) internal returns (uint256 nativeValueReceived) {
        if (asset == address(0)) {
            require(msg.value >= amount, Errors.VALUE_TOO_SMALL);
            (bool success, ) = to.call{ value: amount }("");
            if (!success) {
                revert(Errors.TRANSFER_FAILED);
            }
            return amount;
        } else {
            IERC20(asset).safeTransferFrom(msg.sender, to, amount);
            return 0;
        }
    }

    function transfer(
        address asset,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (asset == address(0)) {
            (bool success, ) = payable(to).call{ value: amount }("");
            return success;
        } else {
            (bool success, bytes memory returndata) = asset.call(
                abi.encodeCall(IERC20.transfer, (to, amount))
            );
            if (!success || asset.code.length == 0) {
                return false;
            }
            return returndata.length == 0 || abi.decode(returndata, (bool));
        }
    }

    /// @notice Adds if needed, and returns required value to pass
    /// @param asset Asset to ensure
    /// @param to Spender
    /// @param amount Amount to ensure
    /// @return Native value to pass
    function ensureApproval(
        address asset,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (asset != address(0)) {
            uint256 allowance = IERC20(asset).allowance(address(this), to);
            if (allowance < amount) {
                IERC20(asset).safeIncreaseAllowance(to, amount);
            }
            return 0;
        } else {
            return amount;
        }
    }
}
