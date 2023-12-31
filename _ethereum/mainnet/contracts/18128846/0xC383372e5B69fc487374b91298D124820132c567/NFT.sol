// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LazyMintAdventureERC721CMetadataInitializable.sol";
import "./AccessControlledMinters.sol";
import "./BasicRoyalties.sol";

contract NFT is 
    AccessControlledMintersInitializable,
    LazyMintAdventureERC721CMetadataInitializable, 
    BasicRoyaltiesInitializable {

    constructor() {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, LazyMintAdventureERC721CInitializable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function _requireCallerIsMinterOrContractOwner() internal view override {
        _requireCallerIsAllowedToMint();
    }
}