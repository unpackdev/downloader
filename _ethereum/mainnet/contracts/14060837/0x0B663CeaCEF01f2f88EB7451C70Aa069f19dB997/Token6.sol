// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./UFixed18.sol";

/// @dev Token6
type Token6 is address;

/**
 * @title Token6Lib
 * @notice Library to manage 6-decimal ERC20s that is compliant with the fixed-decimal types.
 * @dev Automatically converts from Base-6 token amounts to Base-18 UFixed18 amounts, with optional rounding
 */
library Token6Lib {
    using UFixed18Lib for UFixed18;
    using SafeERC20 for IERC20;

    uint256 private constant DECIMALS = 6;
    uint256 private constant OFFSET = 1e12;

    /**
     * @notice Approves `grantee` to spend infinite tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     */
    function approve(Token6 self, address grantee) internal {
        IERC20(Token6.unwrap(self)).safeApprove(grantee, type(uint256).max);
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     */
    function approve(Token6 self, address grantee, UFixed18 amount) internal {
        IERC20(Token6.unwrap(self)).safeApprove(grantee, toTokenAmount(amount, false));
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function approve(Token6 self, address grantee, UFixed18 amount, bool roundUp) internal {
        IERC20(Token6.unwrap(self)).safeApprove(grantee, toTokenAmount(amount, roundUp));
    }

    /**
     * @notice Transfers all held tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to receive the tokens
     */
    function push(Token6 self, address recipient) internal {
        push(self, recipient, balanceOf(self, address(this)));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function push(Token6 self, address recipient, UFixed18 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransfer(recipient, toTokenAmount(amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function push(Token6 self, address recipient, UFixed18 amount, bool roundUp) internal {
        IERC20(Token6.unwrap(self)).safeTransfer(recipient, toTokenAmount(amount, roundUp));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     */
    function pull(Token6 self, address benefactor, UFixed18 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, address(this), toTokenAmount(amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function pull(Token6 self, address benefactor, UFixed18 amount, bool roundUp) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, address(this), toTokenAmount(amount, roundUp));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function pullTo(Token6 self, address benefactor, address recipient, UFixed18 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, recipient, toTokenAmount(amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function pullTo(Token6 self, address benefactor, address recipient, UFixed18 amount, bool roundUp) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, recipient, toTokenAmount(amount, roundUp));
    }

    /**
     * @notice Returns the name of the token
     * @param self Token to check for
     * @return Token name
     */
    function name(Token6 self) internal view returns (string memory) {
        return IERC20Metadata(Token6.unwrap(self)).name();
    }

    /**
     * @notice Returns the symbol of the token
     * @param self Token to check for
     * @return Token symbol
     */
    function symbol(Token6 self) internal view returns (string memory) {
        return IERC20Metadata(Token6.unwrap(self)).symbol();
    }

    /**
     * @notice Returns the decimals of the token
     * @param self Token to check for
     * @return Token decimals
     */
    function decimals(Token6 self) internal pure returns (uint256) {
        return DECIMALS;
    }

    /**
     * @notice Returns the `self` token balance of the caller
     * @param self Token to check for
     * @return Token balance of the caller
     */
    function balanceOf(Token6 self) internal view returns (UFixed18) {
        return balanceOf(self, address(this));
    }

    /**
     * @notice Returns the `self` token balance of `account`
     * @param self Token to check for
     * @param account Account to check
     * @return Token balance of the account
     */
    function balanceOf(Token6 self, address account) internal view returns (UFixed18) {
        return fromTokenAmount(IERC20(Token6.unwrap(self)).balanceOf(account));
    }

    /**
     * @notice Converts the unsigned fixed-decimal amount into the token amount according to
     *         it's defined decimals
     * @dev Provides the ability to "round up" the token amount which is useful in situations where
     *      are swapping one token for another and don't want to give away "free" units due to rounding
     *      errors in the favor of the user.
     * @param amount Amount to convert
     * @param roundUp Whether to round decimal token amount up to the next unit
     * @return Normalized token amount
     */
    function toTokenAmount(UFixed18 amount, bool roundUp) private pure returns (uint256) {
        return roundUp ? Math.ceilDiv(UFixed18.unwrap(amount), OFFSET) : UFixed18.unwrap(amount) / OFFSET;
    }

    /**
     * @notice Converts the token amount into the unsigned fixed-decimal amount according to
     *         it's defined decimals
     * @param amount Token amount to convert
     * @return Normalized unsigned fixed-decimal amount
     */
    function fromTokenAmount(uint256 amount) private pure returns (UFixed18) {
        return UFixed18.wrap(amount * OFFSET);
    }
}