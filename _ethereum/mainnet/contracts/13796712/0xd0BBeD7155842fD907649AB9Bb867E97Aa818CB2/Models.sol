// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "./Initializable.sol";

interface Models {

    enum PartTypes { EXHAUST, SPOILER, HOOD, FRONT_BUMPER, STICKER }
    enum WheelLayers { TIRE_OUTLINE, TIRE, RIM_OUTLINE, RIM_BACKGROUND, RIM_DETAILS }

    struct Part {
        ColoredPaths paths;
        PartTypes enumType;
    }

    struct PartWithPos {
        uint partIndex;
        string pos;
        bool installed;
        uint partId;
    }

    struct ColoredPaths {
        string[] paths;
        string[] colors;
    }
    
    struct Path {
        string d;
        string pos;
    }

    struct DoublePath {
        string d;
        string fPos;
        string rPos;
    }

    struct Base {
        uint16 fTireIndex;
        uint16 rTireIndex;
        string fTirePos;
        string rTirePos;
        string[] rim;
        Path background;
        ColoredPaths outline;
        string punkPos;
        bool registered;
    }

    struct Car {
        uint baseId;
        string baseColor;
        uint punkId;
        uint[] partsIndexes;
        bool created;
        bool isRolling;
        bool hasPunk;
    }

}