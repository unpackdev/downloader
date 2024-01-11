// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Burnable.sol";
import "./IERC721Metadata.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./NftTrustedConsumers.sol";

contract MintPass is
    Ownable,
    ERC721,
    NftTrustedConsumers {

    constructor(string memory name_, string memory symbol_) ERC721 (name_, symbol_) {}

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override(ERC721, NftTrustedConsumers) returns (bool) {
        return super._isApprovedOrOwner(spender, tokenId);
    }

}
