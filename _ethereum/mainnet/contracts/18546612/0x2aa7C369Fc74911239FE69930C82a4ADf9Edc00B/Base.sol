// Copyright (C) 2023 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.21;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Address.sol";

import "./Errors.sol";

/**
 * @title Library unifying transfer, approval, and getting balance for ERC20 tokens and Ether
 */
library Base {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Transfers tokens or Ether
     * @param token Address of the token or `ETH` in case of Ether transfer
     * @param receiver Address of the account that will receive funds
     * @param amount Amount to be transferred
     * @dev This function is compatible only with ERC20 tokens and Ether, not ERC721/ERC1155 tokens
     * @dev Reverts on zero `receiver` and insufficient balance, does nothing for zero amount
     * @dev Should not be used with zero token address
     */
    function transfer(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == uint256(0)) return;
        if (receiver == address(0)) revert ZeroReceiver();

        uint256 currentBalance = getBalance(token);
        if (currentBalance < amount)
            revert InsufficientBalance(currentBalance, amount);

        if (token == ETH) {
            Address.sendValue(payable(receiver), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(token), receiver, amount);
        }
    }

    /**
     * @notice Transfers tokens or Ether from sender to the receiver
     * @param token Address of the token or `ETH` in case of Ether transfer
     * @param receiver Address of the account that will send funds
     * @param receiver Address of the account that will receive funds
     * @param amount Amount to be transferred
     * @dev This function is compatible only with ERC20 tokens and Ether, not ERC721/ERC1155 tokens
     * @dev Reverts on zero `receiver` and insufficient balance/allowance, does nothing for zero amount
     * @dev Should not be used with zero token address
     * @dev It is unsafe to use this function with sender address different from `msg.sender`
     */
    function transferFrom(
        address token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == uint256(0)) return;
        if (receiver == address(0)) revert ZeroReceiver();

        if (token == ETH) {
            revert TransferFromEther();
        } else {
            uint256 balance = getBalance(token, sender);
            if (balance < amount) revert InsufficientBalance(balance, amount);

            uint256 currentAllowance = IERC20(token).allowance(
                sender,
                address(this)
            );
            if (currentAllowance < amount) {
                revert InsufficientAllowance(currentAllowance, amount);
            }

            SafeERC20.safeTransferFrom(IERC20(token), sender, receiver, amount);
        }
    }

    /**
     * @notice Transfers ERC721 tokens from sender to the receiver
     * @param token Address of ERC721 token
     * @param receiver Address of the account that will send ERC721 token
     * @param receiver Address of the account that will receive ERC721 token
     * @param tokenId TokenId to be transferred
     * @dev This function is compatible only with ERC20 tokens and Ether, not ERC721/ERC1155 tokens
     * @dev Reverts on zero `receiver` and insufficient balance/allowance, does nothing for zero amount
     * @dev Should not be used with zero token address
     * @dev It is unsafe to use this function with sender address different from `msg.sender`
     */
    function safeTransferFrom(
        address token,
        address sender,
        address receiver,
        uint256 tokenId
    ) internal {
        if (receiver == address(0)) revert ZeroReceiver();

        address owner = getOwnerOf(token, tokenId);
        if (sender != owner) {
            revert InsufficientBalance(0, 1);
        }

        if (sender != address(this)) {
            bool isApprovedForAll = IERC721(token).isApprovedForAll(
                sender,
                address(this)
            );
            if (!isApprovedForAll) {
                address operator = IERC721(token).getApproved(tokenId);
                if (operator != address(this))
                    revert InsufficientAllowance(0, 1);
            }
        }

        IERC721(token).safeTransferFrom(sender, receiver, tokenId);
    }

    /**
     * @notice Calculates the token balance of the given account
     * @param token Address of the token
     * @param tokenId TokenId of the token
     * @return owner Owner of the token with given tokenId
     * @dev Should not be used with zero token address
     */
    function getOwnerOf(
        address token,
        uint256 tokenId
    ) internal view returns (address owner) {
        return IERC721(token).ownerOf(tokenId);
    }

    /**
     * @notice Calculates the token balance of the given account
     * @param token Address of the token
     * @param account Address of the account
     * @return balance The token balance of the given account
     * @dev Should not be used with zero token address
     */
    function getBalance(
        address token,
        address account
    ) internal view returns (uint256 balance) {
        if (token == ETH) return account.balance;

        return IERC20(token).balanceOf(account);
    }

    /**
     * @notice Calculates the token balance of `this` contract address
     * @param token Address of the token
     * @return balance The token balance of `this` contract address
     * @dev Returns `0` for zero token address in order to handle empty token case
     */
    function getBalance(address token) internal view returns (uint256 balance) {
        if (token == address(0)) return uint256(0);

        return Base.getBalance(token, address(this));
    }
}
