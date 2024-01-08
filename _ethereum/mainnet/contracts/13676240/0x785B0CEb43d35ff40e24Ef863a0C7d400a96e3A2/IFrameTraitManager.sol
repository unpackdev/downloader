// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IFrameTraitManager {
    /**
    frame style 
    frame colour 
    accent 
    frame corner variation
    frame condition (cracked, weathered, scratched, pristine, shimmering, pixelate)
    frame effect (electrified, fiery, watery/wet, abandoned/plant life growing-vines,) 
    barcode/wave/generated thing from hash (1/1)
    top decorations (e.g. cat, gun, spray can etc)
    top variation (e.g. cat glowing eyes, laser eyes legendary, weighted so legendary harder to get)
    top colour (if not legendary, if legendary, pick from range instead)
    top offset (percent within range from 30% to 70%)
    x 4 (bottom, left, right)
     */
    /**
     Get the frame style
     Choice of: Denim, kintsugi, cyberpunk, 
     */

    enum TraitParameter {
        STYLE,
        MAIN_COLOUR,
        ACCENT_COLOUR,
        ACCENT_SECONDARY_COLOR,
        CORNER,
        CONDITION,
        RIMS,
        TOP_DAMAGE,
        TOP_VARIATION,
        TOP_OFFSET,
        BOTTOM_DAMAGE,
        BOTTOM_VARIATION,
        BOTTOM_OFFSET,
        LEFT_DAMAGE,
        LEFT_VARIATION,
        LEFT_OFFSET,
        RIGHT_DAMAGE,
        RIGHT_VARIATION,
        RIGHT_OFFSET,
        SIGNATURE
    }

    function getTrait(TraitParameter traitParameter, uint256 traitHash) external view returns (uint256);
}
