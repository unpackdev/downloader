// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./Address.sol";

// File: contracts/libs/UniversalERC20.sol
/**
 * @notice Library for wrapping ERC20 token and ETH
 * @dev It uses msg.sender directly so only use in normal contract, not in GSN-like contract
 */
library UniversalERC20 {
    using SafeERC20 for IERC20;
    using Address for address payable;

    IERC20 internal constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        if (isETH(token)) {
            payable(address(uint160(to))).sendValue(amount);
            return amount;
        }
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransfer(to, amount);
        return token.balanceOf(to) - balanceBefore;
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        if (isETH(token)) {
            require(msg.value >= amount, "Insufficient msg.value");
            if (to != address(this))
                payable(address(uint160(to))).sendValue(amount);

            // refund redundant amount
            if (msg.value > amount)
                payable(address(uint160(from))).sendValue(msg.value - amount);

            return amount;
        }
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, amount);
        return token.balanceOf(to) - balanceBefore;
    }

    function universalTransferFromSenderToThis(
        IERC20 token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        if (isETH(token)) {
            require(msg.value >= amount, "Insufficient msg.value");
            // Return remainder if exist
            if (msg.value > amount)
                payable(msg.sender).sendValue(msg.value - amount);
            return amount;
        }
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        return token.balanceOf(address(this)) - balanceBefore;
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(
        IERC20 token,
        address who
    ) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return address(token) == address(ETH_ADDRESS);
    }
}
