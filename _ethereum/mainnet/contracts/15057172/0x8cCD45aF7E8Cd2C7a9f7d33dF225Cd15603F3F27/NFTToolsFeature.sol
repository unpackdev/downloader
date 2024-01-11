// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 TheOpenDAO

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "./FixinERC721Spender.sol";
import "./FixinERC1155Spender.sol";
import "./IFeature.sol";
import "./INFTToolsFeature.sol";
import "./FixinEIP712.sol";
import "./FixinCommon.sol";
import "./LibMigrate.sol";

/// @dev Feature for interacting with NFT auctions.
contract NFTToolsFeature is
    IFeature,
    FixinERC721Spender,
    FixinERC1155Spender,
    FixinEIP712,
    FixinCommon,
    INFTToolsFeature
{
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "NFTTools";

    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    constructor(address zeroExAddress) public FixinEIP712(zeroExAddress) { }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external virtual returns (bytes4 success) {
        _registerFeatureFunction(this.batchTransferNFTAssetsFrom.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Transfer multiple ERC721 and multiple ERC1155 NFTs to another account.
    /// @param erc721s The ERC721 NFTs are to be transferred.
    /// @param erc1155s The ERC1155 NFTs are to be transferred.
    function batchTransferNFTAssetsFrom(TransferERC721AsseetsParam[] calldata erc721s, TransferERC1155AsseetsParam[] calldata erc1155s) external override {
        uint256 len = erc721s.length;
        uint256 i = 0;
        for(; i < len; ++i) {
            _transferERC721AssetFrom(erc721s[i].token, msg.sender, erc721s[i].to, erc721s[i].tokenId);
        }
        len = erc1155s.length;
        i = 0;
        for(; i < len; ++i) {
            _transferERC1155AssetFrom(erc1155s[i].token, msg.sender, erc1155s[i].to, erc1155s[i].tokenId, erc1155s[i].amount);
        }
    }
}