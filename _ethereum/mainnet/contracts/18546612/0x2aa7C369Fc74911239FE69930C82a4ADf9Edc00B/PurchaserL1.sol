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

import "./Base.sol";
import "./Purchaser.sol";
import "./IPurchaserL1.sol";
import "./IZerionDNA.sol";
import "./Errors.sol";
import "./ERC721Holder.sol";

/**
 * @notice Ethereum-only version of Purchaser, additionally supports relaying requested purchases
 */
contract PurchaserL1 is IPurchaserL1, Purchaser, ERC721Holder {
    /// Zerion DNA token address
    address private constant DNA = 0x932261f9Fc8DA46C4a22e31B45c4De60623848bF;

    /**
     * @inheritdoc IPurchaserL1
     */
    function mintAndPurchasePremium(
        address receiver,
        uint256 premiumType,
        bytes32 salt,
        bytes memory signature
    ) external override onlyOwner nonReentrant whenNotPaused {
        if (salt == bytes32(0)) revert ZeroSalt();

        uint256 tokenId = mintDNA(receiver);

        emitPurchasePremium({
            tokenId: tokenId,
            premiumType: premiumType,
            token: address(0),
            amount: uint256(0),
            deadline: type(uint256).max,
            salt: salt,
            signature: signature
        });
    }

    /**
     * @dev Mints DNA token and sends it to the receiver
     * @param receiver Receiver of newly minted DNA token
     * @return tokenId ID of newly minted DNA token
     */
    function mintDNA(address receiver) internal returns (uint256 tokenId) {
        tokenId = IZerionDNA(DNA).totalSupply();

        IZerionDNA(DNA).mint();

        Base.safeTransferFrom(DNA, address(this), receiver, tokenId);
    }
}
