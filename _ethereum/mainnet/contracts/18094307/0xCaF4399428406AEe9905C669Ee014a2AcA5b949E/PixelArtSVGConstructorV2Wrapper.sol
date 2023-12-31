// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// NFTC Prerelease Contracts
import "./PixelArtSVGConstructorV2.sol";

/**
 * @title PixelArtSVGConstructorV2Wrapper
 * __________.__              .__       _____          __    .__         _________               .__
 * \______   \__|__  ___ ____ |  |     /  _  \________/  |_  |__| ______ \_   ___ \  ____   ____ |  |
 *  |     ___/  \  \/  // __ \|  |    /  /_\  \_  __ \   __\ |  |/  ___/ /    \  \/ /  _ \ /  _ \|  |
 *  |    |   |  |>    <\  ___/|  |__ /    |    \  | \/|  |   |  |\___ \  \     \___(  <_> |  <_> )  |__
 *  |____|   |__/__/\_ \\___  >____/ \____|__  /__|   |__|   |__/____  >  \______  /\____/ \____/|____/
 *                    \/    \/               \/                      \/          \/
 *                                     But not as cool as Ascii Art!
 *
 * @dev Thanks to Patrick Gillespie (@patorjk) for Text to ASCII Art Generator (TAAG).
 * 
 * This contract wraps PixelArtSVGConstructorV2, which builds SVGs using the <foreignObject>/<img> approach.
 */
contract PixelArtSVGConstructorV2Wrapper is PixelArtSVGConstructorV2 {
    constructor() {
        // Deployment wrapper for PixelArtSVGConstructorV2.
    }
}
