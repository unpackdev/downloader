// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// OZ Libraries
import "./Ownable.sol";

// Local References
import "./PixelPioneerBase.sol";
import "./PixelPioneerSplitsAndRoyalties.sol";

// Error Codes
error CallerIsNotOwner();

/**
 * @title PixelPioneer        .
 *                            .+.
 *             -:       .:    :+.
 *    --      :=.       :+    -=                                         .     ..                     .:-:
 *    .+.    --         :+    =-   .:.                                 :++-.  .++=: ..              :==:-++==:
 *     =-  .=:          :=    +.  -=::.:.               -.        .==..+=-+=  =+:+-.=====:         -+:  =+:.-+.
 *     =-:=-       :.   ==----+  :+   =+:.-+-   ..                 ++..++++:  =++=-+:   -+:      .++=--=++=-++.
 *     -=--==-.    :.   +-::.=-  +- .=-+:=::+. -+=     .:-.        =+.  .+=   :+=.=+:   -+:       +=:::=+..-+:
 *     --    .--       .+.  .+:  ==-=: -+:  ===:.======-::+-       =+.  :+:   =+:-+-   :+=       .+=  .+--+-.
 *     .-              .+.  :+.   :.                      :+.      .-    .    .-=-.    =+.        :==-=+=:.
 *                      +:  .+                            :-                           ..            ..
 *
 *                                                K. Haring 1987 ⊕︀
 *
 *
 * @dev                       Ascii art tribute to Keith Haring's distinctive signature
 * @dev          Thanks to Herman Schechkin for https://github.com/hermanTenuki/ASCII-Generator.site
 */
contract PixelPioneer is PixelPioneerSplitsAndRoyalties, PixelPioneerBase, Ownable {
    // NFT License path subject to change, see getContractURI() for latest file.
    string private constant NFT_LICENSE_URL = 'https://www.haring.com/!/nft-ownership-license';
    address private constant METADATA_CONTRACT = 0xCD17e53ceA841FF9bE6cFc99d285DB754A6175F1; // PixelPioneerMetadata V1

    constructor()
        ERC721('PixelPioneer', 'KH87')
        SafetyLatch(18253700) // Oct 1 2023
        PixelPioneerBase(NFT_LICENSE_URL)
        ChainNativeMetadataConsumer(METADATA_CONTRACT)
    {
        // Implementation version: v1.0.0
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Fulfill isOwner() modifier implementation
     *
     * @dev see OwnableDeferred for more explanation on this.
     */
    modifier isOwner() override {
        _isOwner();
        _;
    }

    /**
     * Fulfill _isOwner() implementation, backed by OZ Ownable.
     *
     * @dev see OwnableDeferred for more explanation on this.
     */
    function _isOwner() internal view override(NFTCSplitsAndRoyalties, OwnableDeferral) {
        // Same as _checkOwner() but using error code instead of a require statement.
        if (owner() != _msgSender()) revert CallerIsNotOwner();
    }
}
