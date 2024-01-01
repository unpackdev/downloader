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

/**
 * @notice Error thrown when block timestamp exceeds deadline
 * @param blockTimestamp Current block timestamp
 * @param deadline Deadline timestamp
 */
error DeadlineExceeded(uint256 blockTimestamp, uint256 deadline);

/**
 * @notice Error thrown when `mintAndPurchasePremium()` function is called with zero `salt` parameter
 */
error ZeroSalt();

/**
 * @notice Error thrown when `transfer()` or `transferFrom()` functions was called with zero `receiver` address
 */
error ZeroReceiver();

/**
 * @notice Error thrown when beneficiary address is set to zero
 */
error ZeroBeneficiary();

/**
 * @notice Error thrown when `transferFrom()` function is called with insufficient allowance
 * @param currentAllowance Current allowance
 * @param requiredAllowance Required allowance
 */
error InsufficientAllowance(
    uint256 currentAllowance,
    uint256 requiredAllowance
);

/**
 * @notice Error thrown when `transfer()` or `transferFrom()` function is called with insufficient allowance
 * @param currentBalance Current balance
 * @param requiredBalance Required balance
 */
error InsufficientBalance(uint256 currentBalance, uint256 requiredBalance);

/**
 * @notice Error thrown when `transferFrom()` function is called with ETH address instead ERC20 token
 */
error TransferFromEther();

/**
 * @notice Error thrown when `msg.sender` differs from the required one
 * @param currentMsgSender Current `msg.sender`
 * @param requiredMsgSender Required `msg.sender`
 */
error BadMsgSender(address currentMsgSender, address requiredMsgSender);
