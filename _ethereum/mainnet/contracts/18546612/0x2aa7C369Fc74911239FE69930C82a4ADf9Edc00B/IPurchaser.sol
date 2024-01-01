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

interface IPurchaser {
    /**
     * @notice Indicates Premium purchase
     * @param tokenId DNA token ID Premium is purchased for
     * @param premiumType Type of premium subscription
     * @param hash The rest of parameters encoded and hashed
     * @param signature Signature verifying the validity of function arguments
     */
    event PurchasePremium(
        uint256 indexed tokenId,
        uint256 indexed premiumType,
        bytes32 indexed hash,
        bytes signature
    );

    /**
     * @notice Indicates DNA mint and Premium purchase request
     * @param receiver Receiver of new DNA token
     * @param premiumType Type of premium subscription
     * @param hash The rest of parameters encoded and hashed
     * @param signature Signature verifying the validity of function arguments
     */
    event RequestPremium(
        address indexed receiver,
        uint256 indexed premiumType,
        bytes32 indexed hash,
        bytes signature
    );

    /**
     * @notice Purchase Premium for certain DNA token
     * @param tokenId DNA token ID to purchase Premium for
     * @param premiumType Type of premium subscription
     * @param token Input token address (may be any ERC20 token, Ether, or zero)
     * @param amount Input token amount
     * @param deadline Deadline timestamp, ehich shouldn't be exceeded
     * @param signature Signature verifying the validity of function arguments
     * @dev Emits PurchasePremium event, can be paused, throws DeadlineExceeded error
     */
    function purchasePremium(
        uint256 tokenId,
        uint256 premiumType,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external payable;

    /**
     * @notice Request DNA mint and Premium purchase for certain receiver
     * @param receiver Receiver of new DNA token
     * @param premiumType Type of premium subscription
     * @param token Input token address (may be any ERC20 token, Ether, or zero)
     * @param amount Input token amount
     * @param deadline Deadline timestamp, ehich shouldn't be exceeded
     * @param signature Signature verifying the validity of function arguments
     * @dev Emits RequestPremium event, can be paused, throws DeadlineExceeded error
     */
    function requestPremium(
        address receiver,
        uint256 premiumType,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external payable;
}
