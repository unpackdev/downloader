pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Base64.sol";
import "./ChoreoLibrary.sol";
import "./ChoreoLibraryConfig.sol";
import "./LibZip.sol";
import "./IChoreoScore.sol";

contract ChoreoScoreV2 is IChoreoScore, Ownable {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    using LibZip for bytes;

    enum ChoreoParamsEnum {
        Climate,
        Stage,
        Performers,
        Share,
        SignatureBone,
        Vulnerability,
        HeartTravel,
        HeartTravelMantissa,
        Invert
    }

    address public choreoNft;

    uint256 public safeRenderGas = 350000000; // Most tokens are less but use this to default to backup

    string private _backupBaseUri;

    function setBackupBaseURI(string memory uri) external onlyOwner {
        _backupBaseUri = uri;
    }

    function setChoreoNft(address choreoNft_) external onlyOwner {
        choreoNft = choreoNft_;
    }

    function setDescriptions(string[] memory _descriptions) external onlyOwner {
        require(_descriptions.length == 2);
        descriptions[0] = _descriptions[0];
        descriptions[1] = _descriptions[1];
    }

    function setSafeRenderGas(uint256 _safeRenderGas) external onlyOwner {
        safeRenderGas = _safeRenderGas;
    }

    string[2] public descriptions = [
        "Choreographic score detailing the underlying movement sequence that created Human Unreadable #",
        unicode". The score should be read from top to bottom and left to right. The uncovering of this choreographic score is part of Act II of Human Unreadable, an experiential journey of slowly recovering within Operator’s Privacy Collection. Human Unreadable unfolds in three acts while merging performance, cryptography, blockchain, and generative art into an experience that began on Art Blocks and ends in a live performance. Lot 03 (2023). operator.la/human-unreadable"
    ];

    string[6] public climateNames = [
        "Just heard bad news",
        "Relaxed",
        "Some clouds",
        "On edge",
        "Current",
        "Your crush responded"
    ];

    string[3] public vulnerabilityNames = [
        "Guarded",
        "Door cracked open",
        "Vulnerable"
    ];

    string[5] public orientationNames = [
        "",
        "North", // Starts at 1
        "South",
        "East",
        "West"
    ];

    string[11] public boneNames = [
        "", // Don't show N/A
        "Head",
        "L_Ankle",
        "L_Elbow",
        "L_Foot",
        "L_Knee",
        "L_Shoulder",
        "L_Wrist",
        "R_Ankle",
        "R_Shoulder",
        "R_Wrist"
    ];

    uint8 constant _DECIMAL_SYMBOL = 17;
    uint8 constant _OCTOTHORPE_SYMBOL = 19;
    uint8 constant _METERS_SYMBOL = 18;
    uint8 constant _PAUSE_SYMBOL = 3;

    /** Render Constants**/
    uint256 constant _SEQUENCE_CANVAS_WIDTH_BASE = 915;
    uint256 constant _BASE_MOVEMENT_HEIGHT = 142;
    uint256 constant _MOVEMENT_CANVAS_HEIGHT = 980;

    uint256 constant _SCALE_RES = 1000;
    uint256 constant _SCALE_MIN = 700;

    /** Render Configuration**/
    ChoreoLibrary _choreoLibrary;

    constructor(ChoreoLibrary choreoLibrary_) {
        _choreoLibrary = choreoLibrary_;
    }

    function _renderBackupSvgUri(
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(_backupBaseUri, tokenId.toString(), ".svg")
            );
    }

    function renderTokenURI(
        uint256 tokenId,
        ChoreographyParams memory choreoToRender
    ) public view returns (string memory) {
        require(msg.sender == choreoNft, "Only ChoreoNFT can render");
        uint256 gasStart = gasleft();
        string memory name = string(
            abi.encodePacked(
                "Human Unreadable: Choreographic Score ",
                (tokenId % 1000).toString()
            )
        );
        string memory image;
        if (gasStart >= safeRenderGas) {
            image = string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(_generateSVG(tokenId, choreoToRender)))
                )
            );
        } else {
            // If caller has not supplied enough gas return external render reference
            image = _renderBackupSvgUri(tokenId);
        }

        string memory render = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description": "',
                            descriptions[0],
                            (tokenId % 1000).toString(),
                            descriptions[1],
                            '","external_url":"https://www.operator.la/human-unreadable", "attributes": ',
                            _getAttributes(choreoToRender),
                            ', "image": "',
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
        return render;
    }

    function _formatHeartDistance(
        ChoreographyParams memory choreoToRender
    ) internal pure returns (string memory) {
        uint8 mantissa = choreoToRender.params[
            uint8(ChoreoParamsEnum.HeartTravelMantissa)
        ];
        string memory mantissaStr = mantissa < 10
            ? string(abi.encodePacked("0", mantissa.toString()))
            : mantissa.toString();

        return
            string(
                abi.encodePacked(
                    choreoToRender
                        .params[uint8(ChoreoParamsEnum.HeartTravel)]
                        .toString(),
                    ".",
                    mantissaStr
                )
            );
    }

    function _hasShare(
        ChoreographyParams memory choreoToRender
    ) internal pure returns (bool) {
        return
            choreoToRender.params[uint8(ChoreoParamsEnum.Performers)] > 0 &&
            choreoToRender.params[uint8(ChoreoParamsEnum.Share)] == 1;
    }

    function _hasPause(
        ChoreographyParams memory choreoToRender
    ) internal pure returns (bool) {
        for (uint i = 0; i < choreoToRender.pauseFrames.length; i++) {
            if (choreoToRender.pauseFrames[i] != 0) {
                return true;
            }
        }
        return false;
    }

    function _hasImprovisation(
        ChoreographyParams memory choreoToRender
    ) internal pure returns (bool) {
        for (uint i = 0; i < choreoToRender.sequence.length; i++) {
            if (choreoToRender.sequence[i] == 0) {
                return true;
            }
        }
        return false;
    }

    function _getAttributes(
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        string[] memory parts = new string[](25);

        parts[
            0
        ] = '[{"trait_type": "Sequence Length", "display_type": "number", "value": ';
        parts[1] = choreoToRender.sequence.length.toString();
        parts[2] = '},{"trait_type": "Emotional Climate", "value": "';
        parts[3] = climateNames[
            choreoToRender.params[uint8(ChoreoParamsEnum.Climate)]
        ];
        parts[4] = '"},{"trait_type": "Improv", "value": "';
        parts[5] = _hasImprovisation(choreoToRender) ? "Present" : "Absent";
        parts[6] = '"},{"trait_type": "Pause", "value": "';
        parts[7] = _hasPause(choreoToRender) ? "Yes" : "No";
        if (choreoToRender.params[uint8(ChoreoParamsEnum.SignatureBone)] != 0) {
            parts[8] = '"},{"trait_type": "Signature Bone", "value": "';
            parts[9] = boneNames[
                choreoToRender.params[uint8(ChoreoParamsEnum.SignatureBone)]
            ];
        } else {
            parts[8] = "";
            parts[9] = "";
        }
        parts[10] = '"},{"trait_type": "Vulnerability", "value": "';

        parts[11] = vulnerabilityNames[
            choreoToRender.params[uint8(ChoreoParamsEnum.Vulnerability)]
        ];
        parts[12] = '"},{"trait_type": "Stage Front", "value": "';
        parts[13] = orientationNames[
            choreoToRender.params[uint8(ChoreoParamsEnum.Stage)]
        ];
        parts[
            14
        ] = '"},{"trait_type": "Simultaneous Performers", "display_type": "number", "value": ';
        parts[15] = choreoToRender
            .params[uint8(ChoreoParamsEnum.Performers)]
            .toString();
        parts[16] = '},{"trait_type": "Share Sequence", "value": "';
        parts[17] = _hasShare(choreoToRender) ? "Yes" : "No";
        parts[
            18
        ] = '"},{"trait_type": "Distance of Heart Travel", "display_type": "number", "value": ';
        parts[19] = _formatHeartDistance(choreoToRender);
        parts[20] = '},{"trait_type": "Privacy Enabled", "value": "';
        parts[21] = choreoToRender.params[uint8(ChoreoParamsEnum.Invert)] == 1
            ? "Yes"
            : "No";
        parts[22] = '"},{"trait_type": "Choreographic Hash", "value": "';
        parts[23] = _joinSequence(choreoToRender.sequence);
        parts[24] = '"}]';
        string memory result = parts[0];
        for (uint i = 1; i < parts.length; i++) {
            result = string(abi.encodePacked(result, parts[i]));
        }

        return result;
    }

    function _joinSequence(
        uint8[] memory arr
    ) internal pure returns (string memory tmp) {
        for (uint256 index = 0; index < arr.length; index++) {
            string memory value = arr[index] == 0 ? "i" : arr[index].toString();
            tmp = index < (arr.length - 1)
                ? string(abi.encodePacked(tmp, value, "-"))
                : string(abi.encodePacked(tmp, value));
        }
    }

    function _generateSVG(
        uint256 tokenId,
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        bool invert = _isInverted(choreoToRender);
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="915" height="1220"> <rect width="100%" height="100%" fill=',
                invert ? '"black"/>' : '"white"/>',
                "<defs> <style> .difference { mix-blend-mode: difference; } ",
                invert // half tempo classes
                    ? '.st0{stroke:#fff;stroke-width:0.2;stroke-miterlimit:10;}.st1{fill:#000;stroke:#fff;stroke-width:0.2;stroke-miterlimit:10;} </style> </defs> <svg style="stroke:#fff;stroke-width:0;fill:#fff;">'
                    : '.st0{stroke:#000;stroke-width:0.2;stroke-miterlimit:10;}.st1{fill:#fff;stroke:#000;stroke-width:0.2;stroke-miterlimit:10;} </style> </defs> <svg style="stroke:#000;stroke-width:0;fill:#000;">',
                _renderBackground(choreoToRender),
                _renderHeader(choreoToRender),
                _renderFooters(tokenId, choreoToRender),
                _renderToken(choreoToRender),
                "</svg> </svg>"
            )
        );

        return svg;
    }

    function _renderFooters(
        uint256 tokenId,
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _renderFooterA(tokenId, choreoToRender),
                    _renderFooterB(choreoToRender),
                    _renderFooterC(choreoToRender)
                )
            );
    }

    function _isInverted(
        ChoreographyParams memory choreoToRender
    ) internal pure returns (bool) {
        bool invert = choreoToRender.params[uint8(ChoreoParamsEnum.Invert)] ==
            1;
        return invert;
    }

    function _isVulnerable(
        ChoreographyParams memory choreoToRender
    ) internal pure returns (bool) {
        uint8 vulnerability = choreoToRender.params[
            uint8(ChoreoParamsEnum.Vulnerability)
        ];
        return vulnerability == 2;
    }

    function _renderBackground(
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        return
            _isVulnerable(choreoToRender)
                ? string(
                    abi.encodePacked(
                        "<svg> <defs> <style> .stv{fill:",
                        _isInverted(choreoToRender) ? "#fff" : "#ec1e24",
                        "} </style> </defs>",
                        _renderAttribute(AttributesEnum.VulnerableStamp, 0, 0),
                        "</svg>"
                    )
                )
                : "";
    }

    function _renderHeader(
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        string memory render = _renderAttribute(AttributesEnum.Header, 20, 20);

        return
            _isInverted(choreoToRender) && _isVulnerable(choreoToRender)
                ? _withDifference(render)
                : render;
    }

    function _renderAttributeWithValue(
        AttributesEnum attributeId,
        AttributeValuesEnum attributeValueId,
        uint8[] memory attributeValueOptions,
        uint8 x,
        uint8 y
    ) internal view returns (string memory) {
        (bytes memory svg, uint256 width, uint256 height) = _choreoLibrary
            .attributes(attributeId);

        uint256 offsetX = x + width;
        uint256 offsetY = y; // Total y offset
        string memory render = _placeSvg(
            string(svg.flzDecompress()),
            x,
            y,
            width,
            height
        );
        for (uint8 index = 0; index < attributeValueOptions.length; index++) {
            (render, offsetX, offsetY) = _renderAttributeValue(
                render,
                attributeValueId,
                attributeValueOptions[index],
                offsetX,
                offsetY
            );
        }
        return render;
    }

    function _renderAttributeValues(
        AttributeValuesEnum attributeValueId,
        uint8[] memory attributeValueOptions,
        uint256 x,
        uint256 y
    ) internal view returns (string memory) {
        uint256 offsetX = x;
        uint256 offsetY = y;
        string memory render;
        for (uint8 index = 0; index < attributeValueOptions.length; index++) {
            (render, offsetX, offsetY) = _renderAttributeValue(
                render,
                attributeValueId,
                attributeValueOptions[index],
                offsetX,
                offsetY
            );
        }
        return render;
    }

    function _renderAttributeValue(
        string memory render,
        AttributeValuesEnum attributeValueId,
        uint8 attributeOption,
        uint256 offsetX,
        uint256 offsetY
    ) internal view returns (string memory, uint256, uint256) {
        (bytes memory valueSvg, uint256 width, uint256 height) = _choreoLibrary
            .attributeValues(attributeValueId, attributeOption);

        render = string(
            abi.encodePacked(
                render,
                _placeSvg(
                    string(valueSvg.flzDecompress()),
                    offsetX,
                    offsetY,
                    width,
                    height
                )
            )
        );

        offsetX += width;

        return (render, offsetX, offsetY);
    }

    function _renderMultilineAttributeValues(
        AttributeValuesEnum attributeValueId,
        uint8[] memory attributeValueOptions,
        uint256 maxWidth,
        uint256 lineHeight,
        uint256 x,
        uint256 y
    ) internal view returns (string memory) {
        uint256 offsetX = x;
        uint256 offsetY = y; // Total y offset
        string memory render;
        for (uint8 index = 0; index < attributeValueOptions.length; index++) {
            (render, offsetX, offsetY) = _renderMultilineAttributeValue(
                render,
                attributeValueId,
                attributeValueOptions[index],
                maxWidth,
                lineHeight,
                offsetX,
                offsetY
            );
        }
        return render;
    }

    function _renderMultilineAttributeValue(
        string memory render,
        AttributeValuesEnum attributeValueId,
        uint8 attributeOption,
        uint256 maxWidth,
        uint256 lineHeight,
        uint256 offsetX,
        uint256 offsetY
    ) internal view returns (string memory, uint256, uint256) {
        (bytes memory valueSvg, uint256 width, uint256 height) = _choreoLibrary
            .attributeValues(attributeValueId, attributeOption);

        if (offsetX + width > maxWidth) {
            offsetX = 0;
            offsetY += lineHeight;
        }

        render = string(
            abi.encodePacked(
                render,
                _placeSvg(
                    string(valueSvg.flzDecompress()),
                    offsetX,
                    offsetY,
                    width,
                    height
                )
            )
        );

        offsetX += width;

        return (render, offsetX, offsetY);
    }

    function _renderAttributeWithJitter(
        AttributesEnum attributeId,
        uint256[2][2] memory range,
        bytes32 seed,
        bool withDifference
    ) internal view returns (string memory) {
        // Split the seed into two halves
        bytes16 xSeed = bytes16(seed);
        bytes16 ySeed = bytes16(uint128(uint256(seed)));

        // Generate pseudo-random x and y within the provided range using the seed halves
        uint256 x = (uint256(keccak256(abi.encodePacked(xSeed))) %
            (range[0][1] - range[0][0] + 1)) + range[0][0];
        uint256 y = (uint256(keccak256(abi.encodePacked(ySeed))) %
            (range[1][1] - range[1][0] + 1)) + range[1][0];

        // Call _renderAttribute with the generated x and y
        return
            withDifference
                ? _withDifference(_renderAttribute(attributeId, x, y))
                : _renderAttribute(attributeId, x, y);
    }

    function _renderAttribute(
        AttributesEnum attributeId,
        uint256 x,
        uint256 y
    ) internal view returns (string memory) {
        (bytes memory svg, uint256 width, uint256 height) = _choreoLibrary
            .attributes(attributeId);
        return _placeSvg(string(svg.flzDecompress()), x, y, width, height);
    }

    function _optionId(uint8 optionId) internal pure returns (uint8[] memory) {
        uint8[] memory optionIds = new uint8[](1);
        optionIds[0] = optionId;
        return optionIds;
    }

    function _climateOptionIds(
        uint8 optionId
    ) internal pure returns (uint8[] memory) {
        uint8[] memory optionIds = new uint8[](2);
        optionIds[0] = optionId;

        if (optionId == 0) {
            optionIds[1] = 6;
        } else if (optionId == 5) {
            optionIds[1] = 7;
        } else {
            optionIds[1] = type(uint8).max; // Empty
        }

        return optionIds;
    }

    function _numericOptionIds(
        uint16 numericValue,
        bool withOctothorpe
    ) internal pure returns (uint8[] memory) {
        uint8 hundreds = uint8(numericValue / 100);
        uint8 tens = uint8((numericValue % 100) / 10);
        uint8 ones = uint8(numericValue % 10);

        if (hundreds != 0) {
            uint8[] memory optionIds = new uint8[](withOctothorpe ? 4 : 3);
            if (withOctothorpe) optionIds[0] = _OCTOTHORPE_SYMBOL;
            optionIds[withOctothorpe ? 1 : 0] = hundreds;
            optionIds[withOctothorpe ? 2 : 1] = tens;
            optionIds[withOctothorpe ? 3 : 2] = ones;
            return optionIds;
        } else if (tens != 0) {
            uint8[] memory optionIds = new uint8[](withOctothorpe ? 3 : 2);
            if (withOctothorpe) optionIds[0] = _OCTOTHORPE_SYMBOL;
            optionIds[withOctothorpe ? 1 : 0] = tens;
            optionIds[withOctothorpe ? 2 : 1] = ones;
            return optionIds;
        } else {
            uint8[] memory optionIds = new uint8[](withOctothorpe ? 2 : 1);
            if (withOctothorpe) optionIds[0] = _OCTOTHORPE_SYMBOL;
            optionIds[withOctothorpe ? 1 : 0] = ones;
            return optionIds;
        }
    }

    function _distanceOptionIds(
        uint8 numericValueInteger,
        uint8 numericValueMantissa
    ) internal pure returns (uint8[] memory) {
        uint8 tens = uint8((numericValueInteger % 100) / 10);
        uint8 ones = uint8(numericValueInteger % 10);
        uint8 mantissaTens = uint8((numericValueMantissa % 100) / 10);
        uint8 mantissaOnes = uint8(numericValueMantissa % 10);

        if (tens != 0) {
            uint8[] memory optionIds = new uint8[](6);
            optionIds[0] = tens;
            optionIds[1] = ones;
            optionIds[2] = _DECIMAL_SYMBOL;
            optionIds[3] = mantissaTens;
            optionIds[4] = mantissaOnes;
            optionIds[5] = _METERS_SYMBOL;
            return optionIds;
        } else {
            uint8[] memory optionIds = new uint8[](5);
            optionIds[0] = ones;
            optionIds[1] = _DECIMAL_SYMBOL;
            optionIds[2] = mantissaTens;
            optionIds[3] = mantissaOnes;
            optionIds[4] = _METERS_SYMBOL;
            return optionIds;
        }
    }

    function _renderFooterA(
        uint256 tokenId,
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                '<svg x="20" y="1050" viewBox="0 0 260 154" width="260" height="154">',
                _renderAttributeWithValue(
                    AttributesEnum.FooterTitle,
                    AttributeValuesEnum.Numeric,
                    _numericOptionIds(uint16(tokenId % 1000), true),
                    0,
                    0
                ),
                _renderAttribute(AttributesEnum.FooterSubtitle, 0, 29),
                _renderAttributeWithValue(
                    AttributesEnum.FooterVuln,
                    AttributeValuesEnum.VulnOptions,
                    _optionId(
                        choreoToRender.params[
                            uint8(ChoreoParamsEnum.Vulnerability)
                        ]
                    ),
                    0,
                    51
                ),
                _renderAttributeWithValue(
                    AttributesEnum.FooterPerformers,
                    AttributeValuesEnum.NumericSmall,
                    _numericOptionIds(
                        uint16(
                            choreoToRender.params[
                                uint8(ChoreoParamsEnum.Performers)
                            ]
                        ),
                        false
                    ),
                    0,
                    73
                ),
                _renderAttribute(AttributesEnum.FooterABHash, 0, 95),
                _renderMultilineAttributeValues(
                    AttributeValuesEnum.NumericSmall,
                    choreoToRender.tokenHashArray,
                    261,
                    22,
                    118,
                    95
                ),
                "</svg>"
            )
        );

        return render;
    }

    function _renderFooterB(
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                '<svg x="320" y="1078" viewBox="0 0 257 126" width="257" height="126">',
                _renderAttributeWithValue(
                    AttributesEnum.FooterShare,
                    AttributeValuesEnum.ShareOptions,
                    _optionId(_hasShare(choreoToRender) ? 1 : 0),
                    0,
                    0
                ),
                _renderAttributeWithValue(
                    AttributesEnum.FooterHeartDist,
                    AttributeValuesEnum.NumericSmall,
                    _distanceOptionIds(
                        choreoToRender.params[
                            uint8(ChoreoParamsEnum.HeartTravel)
                        ],
                        choreoToRender.params[
                            uint8(ChoreoParamsEnum.HeartTravelMantissa)
                        ]
                    ),
                    0,
                    22
                ),
                _renderAttributeWithValue(
                    AttributesEnum.FooterStage,
                    AttributeValuesEnum.StageOptions,
                    _optionId(
                        choreoToRender.params[uint8(ChoreoParamsEnum.Stage)]
                    ),
                    0,
                    44
                ),
                _renderAttributeWithValue(
                    AttributesEnum.FooterSigBone,
                    AttributeValuesEnum.SigBoneOptions,
                    _optionId(
                        choreoToRender.params[
                            uint8(ChoreoParamsEnum.SignatureBone)
                        ]
                    ),
                    0,
                    66
                ),
                _renderAttribute(AttributesEnum.FooterClimate, 0, 88),
                _renderMultilineAttributeValues(
                    AttributeValuesEnum.ClimateOptions,
                    _climateOptionIds(
                        choreoToRender.params[uint8(ChoreoParamsEnum.Climate)]
                    ),
                    279,
                    22,
                    145,
                    88
                ),
                "</svg>"
            )
        );

        return
            _isInverted(choreoToRender) && _isVulnerable(choreoToRender)
                ? _withDifference(render)
                : render;
    }

    function _renderFooterC(
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                '<svg x="617" y="1078" viewBox="0 0 278 126" width="278" height="126">',
                _renderAttribute(AttributesEnum.FooterChoreoHash, 0, 0),
                _renderMultilineAttributeValues(
                    AttributeValuesEnum.SequenceOptions,
                    choreoToRender.sequence,
                    297, // 278 + padding
                    35,
                    0,
                    20
                ),
                "</svg>"
            )
        );

        return
            _isInverted(choreoToRender) && _isVulnerable(choreoToRender)
                ? _withDifference(render)
                : render;
    }

    function _withDifference(
        string memory svg
    ) internal pure returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                "<svg",
                ' class="difference"',
                ' style="stroke:#fff;stroke-width:0;fill:#fff;"',
                ">",
                svg,
                "</svg>"
            )
        );

        return render;
    }

    function _placeSvg(
        string memory svg,
        uint256 x,
        uint256 y,
        uint256 width,
        uint256 height
    ) internal pure returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                "<svg",
                ' x="',
                x.toString(),
                '" y="',
                y.toString(),
                '" width="',
                width.toString(),
                '" height="',
                height.toString(),
                '">',
                svg,
                "</svg>"
            )
        );

        return render;
    }

    function _transformFigure(
        string memory path,
        string memory offsetX,
        string memory offsetY,
        string memory scaleX,
        string memory scaleY
    ) internal pure returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                "<g ",
                'transform="translate(',
                (offsetX),
                ",",
                (offsetY),
                ") scale(",
                (scaleX),
                ",",
                (scaleY),
                ')">',
                path,
                "</g>"
            )
        );

        return render;
    }

    function _getSequenceWidth(
        uint8[] memory sequence
    ) internal view returns (uint256[] memory) {
        uint256[] memory imageWidths = new uint256[](sequence.length);
        for (uint8 index = 0; index < sequence.length; index++) {
            (uint256 width, ) = _choreoLibrary.movements(sequence[index]);
            imageWidths[index] = width;
        }
        return imageWidths;
    }

    function _renderToken(
        ChoreographyParams memory choreoToRender
    ) internal view returns (string memory) {
        uint256[] memory imageWidths = _getSequenceWidth(
            choreoToRender.sequence
        );

        (uint256 canvasScale, uint256 rows) = _calculateScale(imageWidths);
        uint256 scaledHeight = _scaleParam(_BASE_MOVEMENT_HEIGHT, canvasScale);
        string memory scaledString = _scaleString(canvasScale);

        uint256 totalHeight = rows * scaledHeight;

        uint256 offsetX; // Current x offset for this row
        uint256 offsetY; // Total y offset
        uint256 lastScaledWidth;

        string memory render;
        for (uint8 index = 0; index < choreoToRender.sequence.length; index++) {
            (render, offsetX, offsetY, lastScaledWidth) = _renderMovement(
                render,
                choreoToRender,
                index,
                offsetX,
                offsetY,
                canvasScale,
                scaledString
            );
        }

        uint256 sectionYOffset = _MOVEMENT_CANVAS_HEIGHT - totalHeight;

        render = _layoutToken(
            choreoToRender,
            render,
            canvasScale,
            sectionYOffset,
            lastScaledWidth + offsetX
        );

        return
            _isInverted(choreoToRender) && _isVulnerable(choreoToRender)
                ? _withDifference(render)
                : render;
    }

    function _calculateCanvasOffsets(
        uint256 canvasScale
    )
        internal
        pure
        returns (uint256 scaledBaseOffset, uint256 scaledCanvasWidth)
    {
        uint256 desiredMargin = 20;
        uint256 baseMargin = 33;
        uint256 scaledBaseMargin = _scaleParam(baseMargin, canvasScale);
        scaledBaseOffset = scaledBaseMargin - desiredMargin;
        scaledCanvasWidth = _SEQUENCE_CANVAS_WIDTH_BASE + scaledBaseOffset * 2;
    }

    function _layoutToken(
        ChoreographyParams memory choreoToRender,
        string memory render,
        uint256 canvasScale,
        uint256 sectionYOffset,
        uint256 lastXPosition
    ) internal view returns (string memory) {
        (
            uint256 scaledBaseOffset,
            uint256 scaledCanvasWidth
        ) = _calculateCanvasOffsets(canvasScale);
        return
            string(
                abi.encodePacked(
                    '<svg x="0" y="54" viewBox="0 0 915 980" width="915" height="980"> <svg x="-',
                    scaledBaseOffset.toString(),
                    '" y="',
                    sectionYOffset.toString(),
                    '" viewBox="0 0 ',
                    scaledCanvasWidth.toString(),
                    ' 980" width="',
                    scaledCanvasWidth.toString(),
                    '" height="980">',
                    render,
                    '</svg></svg><svg x="0" y="-50">',
                    _renderStamp(
                        choreoToRender,
                        sectionYOffset,
                        lastXPosition,
                        canvasScale
                    ),
                    "</svg>"
                )
            );
    }

    function _getRangeSettings(
        uint256 sectionYOffset,
        uint256 lastOffsetX,
        uint256 canvasScale
    ) internal pure returns (uint256[2][2] memory range) {
        (, uint256 scaledCanvasWidth) = _calculateCanvasOffsets(canvasScale);
        // Rule 1 - if small yOffset and if gap on bottom right, stamp goes in bottom right

        // Check if sectionYOffset is below a certain threshold (100?)
        if (sectionYOffset < 100) {
            // Check if last offset x is less than 2/3 of the canvas width
            if (lastOffsetX < ((scaledCanvasWidth * 2) / 3)) {
                // Stamp goes in bottom right
                range[0][0] = _SEQUENCE_CANVAS_WIDTH_BASE / 2; // Start halfway across
                range[0][1] = (_SEQUENCE_CANVAS_WIDTH_BASE * 2) / 3; // End 2/3 across
                range[1][0] = 50 + (_MOVEMENT_CANVAS_HEIGHT * 2) / 3; // Start 2/3 down movement score
                range[1][1] = 50 + (_MOVEMENT_CANVAS_HEIGHT * 3) / 4; // End 3/4 down movement score
                return range;
            }
        }

        // Rule 2 - if gap on top, stamp goes on top middle or left
        if (sectionYOffset > 100) {
            // Check if last offset x is less than 2/3 of the canvas width
            // Stamp goes in bottom right
            range[0][0] = 50; // Start 50 from left
            range[0][1] = (_SEQUENCE_CANVAS_WIDTH_BASE * 1) / 3; // End 1/3 across
            range[1][0] = 0; // Start at top
            range[1][1] = 100; // End 50 down
            return range;
        }

        // Rule 3 - if large scale and gap on bottom right, stamp goes in bottom right
        if (canvasScale > 2000) {
            // Check if last offset x is less than 3/4 of the canvas width
            if (lastOffsetX < ((scaledCanvasWidth * 3) / 4)) {
                // Stamp goes in bottom right
                range[0][0] = _SEQUENCE_CANVAS_WIDTH_BASE / 2; // Start halfway across
                range[0][1] = (_SEQUENCE_CANVAS_WIDTH_BASE * 2) / 3; // End 2/3 across
                range[1][0] = 50 + (_MOVEMENT_CANVAS_HEIGHT * 2) / 3; // Start 2/3 down movement score
                range[1][1] = 50 + (_MOVEMENT_CANVAS_HEIGHT * 3) / 4; // End 3/4 down movement score
                return range;
            }
        }

        // Otherwise random
        range[0][0] = _SEQUENCE_CANVAS_WIDTH_BASE / 2; // Start halfway across
        range[0][1] = (_SEQUENCE_CANVAS_WIDTH_BASE * 2) / 3; // End 2/3 across
        range[1][0] = 50 + (_MOVEMENT_CANVAS_HEIGHT * 1) / 3; // Start 1/3 down movement score
        range[1][1] = 50 + (_MOVEMENT_CANVAS_HEIGHT * 2) / 3; // End 2/3 down movement score
        return range;
    }

    function _renderStamp(
        ChoreographyParams memory choreoToRender,
        uint256 sectionYOffset,
        uint256 lastXOffset,
        uint256 canvasScale
    ) internal view returns (string memory) {
        bytes32 seed = keccak256(
            abi.encodePacked(
                choreoToRender.sequence,
                choreoToRender.params[uint8(ChoreoParamsEnum.HeartTravel)]
            )
        );
        return
            _renderAttributeWithJitter(
                AttributesEnum.Stamp,
                _getRangeSettings(sectionYOffset, lastXOffset, canvasScale),
                seed,
                !_isVulnerable(choreoToRender) || _isInverted(choreoToRender)
            );
    }

    function _scales(
        uint8 movementId,
        uint256 canvasScale
    ) internal view returns (string memory, uint256) {
        (uint256 width, bytes memory svg) = _choreoLibrary.movements(
            movementId
        );
        uint256 scaledWidth = _scaleParam(width, canvasScale);
        return (string(svg.flzDecompress()), scaledWidth);
    }

    function _renderMovementOverlays(
        uint8 tempo,
        uint8 pause
    ) internal view returns (string memory) {
        uint8[] memory optionIds = new uint8[](3);
        optionIds[0] = tempo; // 1 is halftime and 2 is doubletime
        optionIds[1] = pause == 0 ? 0 : _PAUSE_SYMBOL;
        return
            _renderAttributeValues(
                AttributeValuesEnum.MovementOverlayOptions,
                optionIds,
                33,
                125
            );
    }

    function _isImprov(uint8 movementId) internal pure returns (bool) {
        return movementId == 0;
    }

    function _renderMovement(
        string memory render,
        ChoreographyParams memory choreoToRender,
        uint8 index,
        uint256 offsetX,
        uint256 offsetY,
        uint256 canvasScale,
        string memory scaledString
    ) internal view returns (string memory, uint256, uint256, uint256) {
        (string memory svg, uint256 scaledWidth) = _scales(
            choreoToRender.sequence[index],
            canvasScale
        );

        svg = string(
            abi.encodePacked(
                svg,
                _isImprov(choreoToRender.sequence[index])
                    ? ""
                    : _renderMovementOverlays(
                        choreoToRender.tempo[index],
                        choreoToRender.pauseFrames[index]
                    )
            )
        );

        uint256 scaledY = _scaleParam(_BASE_MOVEMENT_HEIGHT, canvasScale);

        render = string(
            abi.encodePacked(
                render,
                _transformFigure(
                    svg,
                    offsetX.toString(),
                    offsetY.toString(),
                    scaledString,
                    scaledString
                )
            )
        );

        if (index < choreoToRender.sequence.length - 1) {
            (offsetX, offsetY) = _calculateOffsets(
                choreoToRender,
                index,
                offsetX,
                offsetY,
                scaledWidth,
                scaledY,
                canvasScale
            );
        }

        return (render, offsetX, offsetY, scaledWidth);
    }

    function _calculateOffsets(
        ChoreographyParams memory choreoToRender,
        uint8 index,
        uint256 offsetX,
        uint256 offsetY,
        uint256 scaledWidth,
        uint256 scaledY,
        uint256 canvasScale
    ) internal view returns (uint256, uint256) {
        (, uint256 scaledCanvasWidth) = _calculateCanvasOffsets(canvasScale);

        (uint256 nextWidth, ) = _choreoLibrary.movements(
            choreoToRender.sequence[index + 1]
        );
        uint256 scaledNextWidth = _scaleParam(nextWidth, canvasScale);
        if (offsetX + scaledWidth + scaledNextWidth > scaledCanvasWidth) {
            offsetY += scaledY;
            offsetX = 0;
        } else {
            offsetX += scaledWidth;
        }

        return (offsetX, offsetY);
    }

    function _calculateRowsAndAccumulator(
        uint256[] memory imageWidths,
        uint256 scale
    ) private pure returns (uint256) {
        (, uint256 scaledCanvasWidth) = _calculateCanvasOffsets(scale);
        uint256 rows = 1;
        uint256 widthAccumulator = 0;

        for (uint16 i = 0; i < imageWidths.length; i++) {
            uint256 newWidthAccumulator = widthAccumulator +
                (imageWidths[i] * scale) /
                _SCALE_RES;
            if (newWidthAccumulator > scaledCanvasWidth) {
                rows++;
                widthAccumulator = (imageWidths[i] * scale) / _SCALE_RES;
            } else {
                widthAccumulator = newWidthAccumulator;
            }
        }

        return rows;
    }

    function _maxAndMin(
        uint256[] memory imageWidths
    ) internal pure returns (uint256, uint256) {
        uint256 maxImageWidth = imageWidths[0];
        uint256 minImageWidth = imageWidths[0];

        for (uint16 i = 1; i < imageWidths.length; i++) {
            if (imageWidths[i] > maxImageWidth) {
                maxImageWidth = imageWidths[i];
            }
            if (imageWidths[i] < minImageWidth) {
                minImageWidth = imageWidths[i];
            }
        }
        return (maxImageWidth, minImageWidth);
    }

    function _maxUint(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function _minUint(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function _calculateMaxScale(
        uint256[] memory imageWidths
    ) internal pure returns (uint256) {
        (uint256 maxWidth, ) = _maxAndMin(imageWidths);

        uint256 maxScaleByHeight = (((_MOVEMENT_CANVAS_HEIGHT * _SCALE_RES) /
            2) / _BASE_MOVEMENT_HEIGHT) - 1; // Clamp max scale by ensuring at least 2 rows

        uint256 scale = maxScaleByHeight;
        (, uint256 scaledCanvasWidth) = _calculateCanvasOffsets(scale);
        uint256 maxScale = maxWidth == 0
            ? maxScaleByHeight
            : (((scaledCanvasWidth) * _SCALE_RES) / maxWidth) - 1; // Calculate max scale in case lower

        scale = _minUint(maxScale, maxScaleByHeight); // Clamp scale to lower of maxScale and maxScaleByHeight
        return scale;
    }

    function _calculateScale(
        uint256[] memory imageWidths
    ) internal pure returns (uint256, uint256) {
        uint256 minScale = _SCALE_MIN;
        uint256 maxScale = _calculateMaxScale(imageWidths);
        uint256 scale;
        uint256 rows;
        uint256 totalHeight;

        uint256 lastValidScale;
        uint256 lastValidRows;

        uint256 iterationCounter;

        while (minScale <= maxScale) {
            iterationCounter++;
            scale = (minScale + maxScale) / 2;
            rows = _calculateRowsAndAccumulator(imageWidths, scale);
            totalHeight = _scaleParam(_BASE_MOVEMENT_HEIGHT * rows, scale);

            if (totalHeight > _MOVEMENT_CANVAS_HEIGHT) {
                maxScale = scale - 1;
            } else {
                lastValidScale = scale;
                lastValidRows = rows;
                if (totalHeight < _MOVEMENT_CANVAS_HEIGHT) {
                    minScale = scale + 1;
                } else {
                    break;
                }
            }
        }

        if (totalHeight > _MOVEMENT_CANVAS_HEIGHT) {
            scale = lastValidScale;
            rows = lastValidRows;
        }

        return (scale, rows);
    }

    function _scaleParam(
        uint256 base,
        uint256 scale
    ) internal pure returns (uint256) {
        return (base * scale) / _SCALE_RES;
    }

    function _scaleString(uint256 scale) internal pure returns (string memory) {
        uint256 integerPart = scale / _SCALE_RES;
        uint256 mantissa = scale % _SCALE_RES;
        string memory mantissaStr;

        if (mantissa < 10) {
            mantissaStr = string(abi.encodePacked("00", mantissa.toString()));
        } else if (mantissa < 100) {
            mantissaStr = string(abi.encodePacked("0", mantissa.toString()));
        } else {
            mantissaStr = mantissa.toString();
        }

        return
            string(abi.encodePacked(integerPart.toString(), ".", mantissaStr));
    }
}
