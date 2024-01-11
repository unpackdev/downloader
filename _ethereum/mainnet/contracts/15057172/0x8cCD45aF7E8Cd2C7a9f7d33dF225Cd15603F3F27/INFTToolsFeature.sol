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

import "./IERC721Token.sol";
import "./IERC1155Token.sol";

/// @dev Feature for interacting with NFT tools.
interface INFTToolsFeature {
    /// @dev Param struct for batchTransferNFTAssetsFrom()
    struct TransferERC721AsseetsParam {
        IERC721Token token;
        address to;
        uint256 tokenId;
    }

    /// @dev Param struct for batchTransferNFTAssetsFrom()
    struct TransferERC1155AsseetsParam {
        IERC1155Token token;
        address to;
        uint256 tokenId;
        uint256 amount;
    }

    /// @dev Transfer multiple ERC721 and multiple ERC1155 NFTs to another account.
    /// @param erc721s The ERC721 NFTs are to be transferred.
    /// @param erc1155s The ERC1155 NFTs are to be transferred.
    function batchTransferNFTAssetsFrom(TransferERC721AsseetsParam[] calldata erc721s, TransferERC1155AsseetsParam[] calldata erc1155s) external;
}
