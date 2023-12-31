// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LazyMintAdventureERC721CMetadataInitializable.sol";
import "./AccessControlledMinters.sol";
import "./MinterCreatorSharedRoyalties.sol";

contract NFT is 
    AccessControlledMintersInitializable,
    LazyMintAdventureERC721CMetadataInitializable, 
    MinterCreatorSharedRoyaltiesInitializable {

    constructor() {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, LazyMintAdventureERC721CInitializable, MinterCreatorSharedRoyaltiesBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(address owner_, uint256 tokenId) internal virtual override {
        super._burn(owner_, tokenId);
        _onBurned(tokenId);
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