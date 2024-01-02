pragma solidity ^0.8.17;

interface ChoreoLibraryConfig {

    struct ChoreographyParams {
        uint8[] tokenHashArray;
        uint8[] sequence;
        uint8[] pauseFrames;
        uint8[] tempo;
        uint8[] params;
    }

    struct TextOverlay {
        bytes svg;
        uint16 width;
        uint16 height;
    }

    struct MovementStruct {
        uint16 width;
        bytes svg;
    }

    struct CanvasStruct {
        uint16 scale;
        uint16 maxWidth;
    }

    enum AttributesEnum {
        Stamp,
        Header,
        FooterTitle,
        FooterSubtitle,
        FooterStage,
        FooterSequenceLength,
        FooterPerformers,
        FooterShare,
        FooterClimate,
        FooterABHash,
        FooterSigBone,
        FooterVuln,
        FooterHeartDist,
        FooterChoreoHash,
        TempoDouble,
        TempoHalf,
        SideView,
        Pause,
        VulnerableStamp
    }
    enum AttributeValuesEnum {
        Numeric,
        Alphabetic,
        Symbolic,
        StageOptions,
        ShareOptions,
        ClimateOptions,
        SigBoneOptions,
        VulnOptions,
        NumericSmall,
        SequenceOptions,
        MovementOverlayOptions
    }
}
