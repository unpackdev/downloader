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

import "./PausableOwnable.sol";
import "./InputHandler.sol";
import "./LostTokensHandler.sol";
import "./IPurchaser.sol";
import "./ReentrancyGuard.sol";
import "./Errors.sol";

/**
 * @notice Abstract contract with main logic of Premium purchases
 */
abstract contract Purchaser is
    IPurchaser,
    InputHandler,
    LostTokensHandler,
    PausableOwnable,
    ReentrancyGuard
{
    /**
     * @inheritdoc IPurchaser
     */
    function purchasePremium(
        uint256 tokenId,
        uint256 premiumType,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external payable override nonReentrant whenNotPaused {
        verifyDeadline(deadline);
        handleInput(token, amount, msg.sender);

        emitPurchasePremium({
            tokenId: tokenId,
            premiumType: premiumType,
            token: token,
            amount: amount,
            deadline: deadline,
            salt: bytes32(0),
            signature: signature
        });
    }

    /**
     * @inheritdoc IPurchaser
     */
    function requestPremium(
        address receiver,
        uint256 premiumType,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external payable override nonReentrant whenNotPaused {
        verifyDeadline(deadline);
        handleInput(token, amount, msg.sender);

        emitRequestPremium({
            receiver: receiver,
            premiumType: premiumType,
            token: token,
            amount: amount,
            deadline: deadline,
            signature: signature
        });
    }

    /**
     * @dev Emits purchase Premium event
     */
    function emitPurchasePremium(
        uint256 tokenId,
        uint256 premiumType,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes32 salt,
        bytes memory signature
    ) internal {
        emit PurchasePremium(
            tokenId,
            premiumType,
            keccak256(abi.encode(token, amount, deadline, salt)),
            signature
        );
    }

    /**
     * @dev Emits request Premium event
     */
    function emitRequestPremium(
        address receiver,
        uint256 premiumType,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) internal {
        emit RequestPremium(
            receiver,
            premiumType,
            keccak256(abi.encode(token, amount, deadline)),
            signature
        );
    }

    /**
     * @dev Checks that `block.timestamp` does not exceed the deadline
     * @param deadline Deadline timestamp
     */
    function verifyDeadline(uint256 deadline) private view {
        // solhint-disable not-rely-on-time
        if (block.timestamp > deadline) {
            revert DeadlineExceeded(block.timestamp, deadline);
        }
        // solhint-enable not-rely-on-time
    }
}
