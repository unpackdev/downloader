// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Local References
import "./PixelPioneerArtworkBase.sol";

/**
 * @title PixelPioneerArtwork .
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
 *                                                On-Chain Artwork
 */
contract PixelPioneerArtwork is PixelPioneerArtworkBase {
    uint256 private constant maxNumberOfArtPieces = 5; // Capped at 5 total pieces.

    constructor() ArtDatastoreManager(maxNumberOfArtPieces) {
        // Implementation version: v1.0.0
    }
}
