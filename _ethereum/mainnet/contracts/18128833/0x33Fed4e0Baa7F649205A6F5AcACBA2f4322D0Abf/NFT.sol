// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LazyMintERC721CMetadataInitializable.sol";
import "./AccessControlledMinters.sol";
import "./MutableMinterRoyalties.sol";

contract NFT is 
    AccessControlledMintersInitializable,
    LazyMintERC721CMetadataInitializable, 
    MutableMinterRoyaltiesInitializable {

    constructor() {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, LazyMintERC721CInitializable, MutableMinterRoyaltiesBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _postValidateTransfer(
        address /*caller*/, 
        address /*from*/, 
        address to, 
        uint256 tokenId, 
        uint256 /*value*/) internal virtual override {
        (, TokenOwner storage tokenOwner_) = _ownerOf(tokenId);
        if (tokenOwner_.transferCount == 1) {
            _onMinted(to, tokenId);
        }
    }

    function _requireCallerIsMinterOrContractOwner() internal view override {
        _requireCallerIsAllowedToMint();
    }
}