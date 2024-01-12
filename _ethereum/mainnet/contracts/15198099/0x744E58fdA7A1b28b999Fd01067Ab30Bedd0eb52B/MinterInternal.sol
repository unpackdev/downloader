/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TokenStoreLib.sol";
import "./RoyaltyManagerLib.sol";
import "./PaymentHandlerLib.sol";
import "./MinterStorage.sol";

library MinterInternal {

    event PreMint(uint256 nrOfTokens);

    function _getMintSettings()
      internal view returns (bool, bool, uint256, uint256, uint256) {
        return (
            __s().publicMinting,
            __s().directMintingAllowed,
            __s().mintFeeWei,
            __s().mintPriceWeiPerToken,
            __s().maxTokenId
        );
    }

    function _setMintSettings(
        bool publicMinting,
        bool directMintingAllowed,
        uint256 mintFeeWei,
        uint256 mintPriceWeiPerToken,
        uint256 maxTokenId
    ) internal {
        __s().publicMinting = publicMinting;
        __s().directMintingAllowed = directMintingAllowed;
        __s().mintFeeWei = mintFeeWei;
        __s().mintPriceWeiPerToken = mintPriceWeiPerToken;
        __s().maxTokenId = maxTokenId;
    }

    function _burn(uint256 tokenId) internal {
        ERC721Lib._burn(tokenId);
        TokenStoreLib._deleteTokenInfo(tokenId);
    }

    function _getTokenIdCounter() internal view returns (uint256) {
        return __s().tokenIdCounter;
    }

    function _justMintTo(
        address owner
    ) internal returns (uint256) {
        uint256 tokenId = __s().tokenIdCounter;
        require(__s().maxTokenId == 0 ||
                tokenId <= __s().maxTokenId, "M:MAX");
        __s().tokenIdCounter += 1;
        if (owner == address(this)) {
            ERC721Lib._safeMint(msg.sender, tokenId);
            ERC721Lib._transfer(msg.sender, address(this), tokenId);
        } else {
            ERC721Lib._safeMint(address(this), tokenId);
            ERC721Lib._transfer(address(this), owner, tokenId);
        }
        return tokenId;
    }

    function _preMint(uint256 nrOfTokens) internal {
        require(nrOfTokens > 0, "M:ZT");
        for (uint256 i = 0; i < nrOfTokens; i++) {
            _justMintTo(address(this));
        }
        emit PreMint(nrOfTokens);
    }

    function _mint(
        address owner,
        string[] memory uris,
        string[] memory datas,
        address[] memory royaltyWallets,
        uint256[] memory royaltyPercentages,
        bool handlePayment,
        string memory paymentMethodName
    ) internal {
        require(__s().directMintingAllowed, "M:DMNA");
        require(uris.length > 0, "M:NTM");
        require(datas.length == 0 ||
                uris.length == datas.length, "M:IL");
        require(royaltyWallets.length == 0 ||
                uris.length == royaltyWallets.length, "M:IL2");
        require(royaltyPercentages.length == 0 ||
                uris.length == royaltyPercentages.length, "M:IL3");
        if (handlePayment) {
            PaymentHandlerLib._handlePayment(
                1, __s().mintFeeWei,
                uris.length, __s().mintPriceWeiPerToken,
                paymentMethodName
            );
        }
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = _mintTo(owner, uris[i]);
            // Both royalty wallet and percentage must have sane values otherwise
            // the operator can always call other methods to set them.
            if (
                royaltyWallets.length > 0 &&
                royaltyPercentages.length > 0 &&
                royaltyWallets[i] != address(0) &&
                royaltyPercentages[i] > 0
            ) {
                RoyaltyManagerLib._setTokenRoyaltyInfo(tokenId, royaltyWallets[i], royaltyPercentages[i]);
            }
            if (datas.length > 0) {
                TokenStoreLib._setTokenData(tokenId, datas[i]);
            }
        }
    }

    // TODO(kam): This function can be moved to TokenStroe facet
    function _updateTokens(
        uint256[] memory tokenIds,
        string[] memory uris,
        string[] memory datas
    ) internal {
        require(tokenIds.length > 0, "M:NTU");
        require(tokenIds.length == uris.length, "M:IL");
        require(tokenIds.length == datas.length, "M:IL2");
        for (uint256 i = 0; i < uris.length; i++) {
            TokenStoreLib._setTokenURI(tokenIds[i], uris[i]);
            TokenStoreLib._setTokenData(tokenIds[i], datas[i]);
        }
    }

    function _mintTo(
        address owner,
        string memory uri
    ) private returns (uint256) {
        uint256 tokenId = _justMintTo(owner);
        TokenStoreLib._setTokenURI(tokenId, uri);
        return tokenId;
    }

    function __s() private pure returns (MinterStorage.Layout storage) {
        return MinterStorage.layout();
    }
}
