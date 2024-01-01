// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

library LogosTypes {
    struct TraitChoice {
        string name;
        bool isBonus;
    }

    struct CharacterInfo {
        string name;
        TraitChoice[] bodies;
        TraitChoice[] heads;
        string[] slotNames;
        uint8[] slotOffsets;
        TraitChoice[] slotOptions;
        bool enabled;
    }

    struct ShapeInfo {
        string name;
        string companyName;
        uint8 numVariants; // number of ADDITIONAL variants, not including the base
        bool enabled;
    }

    struct ColorPalette {
        string name;
        bool isBonus;
        string colorA;
        string colorB;
        bool enabled;
    }

    struct CharacterSelections {
        uint8 characterID;
        uint8 body;
        uint8 head;
        uint8[] slotSelections;
    }

    struct ShapeSelections {
        uint8 primaryShape;
        uint8 primaryShapeVariant;
        uint8 secondaryShape;
        uint8 secondaryShapeVariant;
    }

    struct Logo {
        bool enabled;
        CharacterSelections characterSelections;
        ShapeSelections shapeSelections;
        uint16 colorPalette;
    }
}