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

import "./IInputHandler.sol";
import "./Base.sol";
import "./Ownable.sol";
import "./Errors.sol";

abstract contract InputHandler is IInputHandler, Ownable {
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address private beneficiary;

    /**
     * @inheritdoc IInputHandler
     */
    function setBeneficiary(
        address newBeneficiary
    ) external override onlyOwner {
        if (newBeneficiary == address(0)) revert ZeroBeneficiary();
        emit NewBeneficiary(beneficiary, newBeneficiary);

        beneficiary = newBeneficiary;
    }

    /**
     * @notice Returns current beneficiary address
     * @return currentBeneficiary New beneficiary address
     */
    function getBeneficiary()
        external
        view
        override
        returns (address currentBeneficiary)
    {
        return beneficiary;
    }

    /**
     * @dev In ERC20 token case, transfers input token from the accound address to the beneficiary
     * @dev Checks `msg.value` and transfers it to beneficiary in Ether case
     * @dev Does nothing in zero input token address case
     * @param token Input token address (may be any ERC20 token, Ether, or zero)
     * @param amount Input token amount
     * @param account Address of the account to take tokens from
     */
    function handleInput(
        address token,
        uint256 amount,
        address account
    ) internal {
        if (token == address(0)) return;

        if (token == ETH) return handleETHInput(amount);

        handleTokenInput(token, amount, account);
    }

    /**
     * @dev Transfers Ether amount to the beneficiary
     * @param amount Ether amount to be sent
     */
    function handleETHInput(uint256 amount) private {
        Base.transfer(ETH, beneficiary, amount);
    }

    /**
     * @dev Transfers input token from the account address to the beneficiary
     * @param token Token to be taken from the account address
     * @param amount Input token amount to be taken from the account
     * @param account Address of the account to take tokens from
     */
    function handleTokenInput(
        address token,
        uint256 amount,
        address account
    ) private {
        Base.transferFrom(token, account, beneficiary, amount);
    }
}
