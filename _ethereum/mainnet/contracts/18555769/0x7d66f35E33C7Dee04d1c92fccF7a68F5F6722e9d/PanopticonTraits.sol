// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TraitsWithRarity.sol";

/*

    Token hash allocation:

    0x123456789ABCDEF123456789ABCDEF123456789ABCDEF123456789ABCDEF123456789ABCDEF12

                                                                              R_PAL (>> 0)
                                                                            ET      (>> 5)
                                                                          PT        (>> 7)
                                                                        SF          (>> 9)
                                                                      NT            (>> 11)
                                                                 LINED              (>> 13)
                                                               DT                   (>> 18)
                                                         BORDER                     (>> 20)
                                                     IC_M                           (>> 26)
                                                 EC_M                               (>> 30)
                                            C_SEL                                   (>> 33)

    [    Reserved for runtime variables    ]

*/

contract PanopticonTraits is TraitsWithRarity {
    constructor() TraitsWithRarity(1000) {
        _createPalette();
        _createEyeType();
        _createPupilType();
        _createSize();
        _createNoiseType();
        _createOutline();
        _createDistortion();
        _createBorder();
        _createIrisColorMode();
        _createEyeColorMode();
        _createColorSelectionMode();
    }

    function _createPalette() private {
        TraitValue[] storage values = _initTrait("R_PAL", "Palette", 0);
        values.push(TraitValue(300, "Metro"));
        values.push(TraitValue(260, "Sunset"));
        values.push(TraitValue(120, "Submarine"));
        values.push(TraitValue(90, "Pepe"));
        values.push(TraitValue(65, "Sorbet"));
        values.push(TraitValue(55, "Rainbow"));
        values.push(TraitValue(35, "Peach"));
        values.push(TraitValue(25, "Earth"));
        values.push(TraitValue(20, "Fire"));
        values.push(TraitValue(15, "Mono"));
        values.push(TraitValue(15, "Storm"));
    }

    function _createEyeType() private {
        TraitValue[] storage values = _initTrait("ET", "Eyes", 5);
        values.push(TraitValue(650, "Normal"));
        values.push(TraitValue(300, "Angled"));
        values.push(TraitValue(50, "Squared"));
    }

    function _createPupilType() private {
        TraitValue[] storage values = _initTrait("PT", "Pupils", 7);
        values.push(TraitValue(700, "Normal"));
        values.push(TraitValue(200, "Cats"));
        values.push(TraitValue(100, "Rectangles"));
    }

    function _createSize() private {
        TraitValue[] storage values = _initTrait("SF", "Size", 9);
        values.push(TraitValue(100, "Small"));
        values.push(TraitValue(300, "Medium"));
        values.push(TraitValue(450, "Large"));
        values.push(TraitValue(100, "Very Large"));
        values.push(TraitValue(50, "Outrageous"));
    }

    function _createNoiseType() private {
        TraitValue[] storage values = _initTrait("NT", "Noise", 11);
        values.push(TraitValue(430, "Simple"));
        values.push(TraitValue(160, "Flow"));
        values.push(TraitValue(160, "Wave"));
        values.push(TraitValue(250, "Spiral"));
    }

    function _createOutline() private {
        TraitValue[] storage values = _initTrait("LINED", "Outlined", 13);
        values.push(TraitValue(900, "No"));
        values.push(TraitValue(100, "Yes"));
    }

    function _createDistortion() private {
        TraitValue[] storage values = _initTrait("DT", "Distortion", 18);
        values.push(TraitValue(900, "None"));
        values.push(TraitValue(75, "Vertical"));
        values.push(TraitValue(25, "Both Ways"));
    }

    function _createBorder() private {
        TraitValue[] storage values = _initTrait("BORDER", "Border", 20);
        values.push(TraitValue(400, "Bottom"));
        values.push(TraitValue(600, "Top"));
    }

    function _createIrisColorMode() private {
        TraitValue[] storage values = _initTrait("IC_M", "Iris Color", 26);
        values.push(TraitValue(500, "Random"));
        values.push(TraitValue(400, "Fixed"));
        values.push(TraitValue(100, "Plain"));
    }

    function _createEyeColorMode() private {
        TraitValue[] storage values = _initTrait("EC_M", "Eye Color", 30);
        values.push(TraitValue(600, "Variable"));
        values.push(TraitValue(300, "Fixed"));
        values.push(TraitValue(100, "Monochromatic"));
    }

    function _createColorSelectionMode() private {
        TraitValue[] storage values = _initTrait("C_SEL", "Color Mode", 33);
        values.push(TraitValue(500, "Original"));
        values.push(TraitValue(500, "Alternate"));
    }
}
