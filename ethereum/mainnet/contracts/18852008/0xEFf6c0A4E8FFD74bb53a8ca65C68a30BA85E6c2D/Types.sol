// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum AntennaStatus {
    Off,
    On,
    ConnectedToSatellite
}

enum AntennaModification {
    TurnedAntennaOff,
    TurnedAntennaOn,
    TunedToCapturedSatelliteConnection,
    CapturedSatelliteConnection
}

enum Activation {
    Cascade,
    Plague
}

enum Status {
    Terrain,
    Daydream,
    Terraformed,
    OriginDaydream,
    OriginTerraformed
}

struct SVGParams {
    uint256[32][32] heightmapIndices;
    uint256 level;
    uint256 tile;
    uint256 resourceLvl;
    uint256 resourceDirection;
    uint256 status;
    uint256 font;
    uint256 fontSize;
    uint256 biome;
    int attunement;
    AntennaStatus antenna;
    string zoneName;
    string script;
    string[9] chars;
    string[10] zoneColors;
}

struct AnimParams {
    Activation activation; // Token's animation type
    uint256 classesAnimated; // Classes animated
    uint256 duration; // Base animation duration for first class
    uint256 durationInc; // Duration increment for each class
    uint256 delay; // Base delay for first class
    uint256 delayInc; // Delay increment for each class
    uint256 bgDuration; // Animation duration for background
    uint256 bgDelay; // Delay for background
    string easing; // Animation mode, e.g. steps(), linear, ease-in-out
    string[2] altColors;
}
