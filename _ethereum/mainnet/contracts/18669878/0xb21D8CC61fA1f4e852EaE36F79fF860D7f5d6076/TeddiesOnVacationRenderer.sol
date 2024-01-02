//  _____         _     _ _                                                _   _             
// /__   \___  __| | __| (_) ___  ___     ___  _ __    /\   /\__ _  ___ __ _| |_(_) ___  _ __  
//   / /\/ _ \/ _` |/ _` | |/ _ \/ __|   / _ \| '_ \   \ \ / / _` |/ __/ _` | __| |/ _ \| '_ \ 
//  / / |  __/ (_| | (_| | |  __/\__ \  | (_) | | | |   \ V / (_| | (_| (_| | |_| | (_) | | | |
//  \/   \___|\__,_|\__,_|_|\___||___/   \___/|_| |_|    \_/ \__,_|\___\__,_|\__|_|\___/|_| |_|
// // // // // // // //                             =########             
// // // // // // // //       :********.   :**********#######**.          
// // // // // // // //     -+*********+++++*************====##.          
// // // // // // // //   -+*#*****====******************++--##.          
// // // // // // // //   +##****==--++********************++--           
// // // // // // // //   +##****--++************************             
// // // // // // // //   -=+##**==**************************--           
// // // // // // // //     -++##***************##*******##****.          
// // // // // // // //       :+****************%%*******%%****.          
// // // // // // // //         .##*************##=-----=##****.          
// // // // // // // //         .##*************-------======**.          
// // // // // // // //         .##***********--------*%%%%%%--           
// // // // // // // //         .##***********----------=%#----           
// // // // // // // //            ##***********---------=---             
// // // // // // // //            ..*#**********************             
// // // // // // // //              *######**************+..             
// // // // // // // //            ==*##########***********++             
// // // // // // // //          --****###########*********##====.        
// // // // // // // //       .--********#########***********####+-:      
// // // // // // // //     .:=********#########***************####+-:    
// // // // // // // //     =**********#######*****************######*::  
// // // // // // // //   ..=**********#######*******************#######  
// // // // // // // //   +**********#######*********************#######  
// // // // // // // //   +**********#######*********************#########
// // // // // // // // ***********#########*********************#########
/**
 * @title TeddiesOnVacationRenderer
 * @author numo <@numo_0> <info@numo.art>
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ToVInfos.sol";
import "./DynamicBuffer.sol";
import "./Base64.sol";
import "./SSTORE2.sol";
import "./Strings.sol";

contract TeddiesOnVacationRenderer is Ownable, ReentrancyGuard {
    using DynamicBuffer for bytes;

    error InvalidSeason();

    struct TraitDTO {
        string name;
        string mimetype;
        bytes data;
        bool hide;
        bool useExistingData;
        uint existingDataIndex;
    }

    struct Trait {
        string name;
        string mimetype;
        bool hide;
    }

    struct OneOfOne { 
        uint256 tokenId;
        uint256 dna;
    }

    bool private shouldWrapSVG = true;
    string private backgroundColor = "transparent";
    string private placeholderImage = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiB2aWV3Qm94PSIwIDAgMTIwMCAxMjAwIiB2ZXJzaW9uPSIxLjIiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGltYWdlIHdpZHRoPSIxMjAwIiBoZWlnaHQ9IjEyMDAiIGhyZWY9ImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU1USXdNQ0lnYUdWcFoyaDBQU0l4TWpBd0lpQjJhV1YzUW05NFBTSXdJREFnTVRJd01DQXhNakF3SWlCMlpYSnphVzl1UFNJeExqSWlJSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SWdjM1I1YkdVOUltSmhZMnRuY205MWJtUXRZMjlzYjNJNmRISmhibk53WVhKbGJuUTdZbUZqYTJkeWIzVnVaQzFwYldGblpUcDFjbXdvWkdGMFlUcHBiV0ZuWlM5d2JtYzdZbUZ6WlRZMExHbFdRazlTZHpCTFIyZHZRVUZCUVU1VFZXaEZWV2RCUVVGRFFVRkJRVUZuUTBGWlFVRkJRbnBsYm5Jd1FVRkJRVUZZVGxOU01FbEJjbk0wWXpaUlFVRkNVRlpLVWtWR1ZWZEpWMlJzTURGMlNFVlZVV2h3SzNGSWRTdDFOMWxxUldwdFRWUktlVWhvVVVWRWFVTjFTVk5KV2tOR1JrOVlRMUFyVlVWVFFXZHBTV05uYUVWeU9FRndTa0ZSWmpZeGFuZzBOR3BtTW5neWNEWnpOR1JOTDNNNU9YQlJNRzFxWVRka05UWXpNM0Z5Y1hKMFNGZHNPVGcxYlZONmQzbFBiVzFUTkhablUzQmhWRGhxZDBGcmRIVkVUVUp6Y1hBNVVrdDVORVZHTUVaRlMwbHZRV3QxUWtaa1dIaGtRVVJrVEVKR1ZYZDNUWGQyU2taT1RVRjBabXhLVmxOV1pVaHBSVnBCVEhnMlNtcEhObXR3VGtscE0wMDBkMjlyUWtoRVJFTkJVbnBXUVhoVVFWaE9jME53Um1sa1JVcFljbkZOY1hGRGFHaGlXbFkwT0VKd1JWVkNSVEJHUldkc0wxTkRVa1JCZW1kc2RFcHJXWFpSVDFoMVVIVTVVMUJNVXpKUFMwUkNSVkZGV1c5UmEzTlRXbWhQWTNoRFIwWjFUSEpOVlZKd1RtZG9SbEZJUVdONVRYVk1LMUJ4YlV4MU5FazJORFF3WkhaalJFNXJObVJ2ZDJkVmNIbDZaVUZoUVhGeFMzRkNRbFl3TVdsdkx6a3JXRXMyZEdoVWIwTTJSRzV3TjJVMlowZEVSVkI0YkVGTVVEbGFSRGxXVTJ4S1FrTnlkMGx4UTFOQlZVOW5aa3hXVUVOSmNVa3djbmt4YW5GeFFUVkZORmxLUWtsQlRYZDZiemRNV1ZKRVdXYzNTV3BETTNSdllWb3daRE5hZUZaVVFraFVkRFpuZVRWa2R6aDNiMmhwU1ZoU1dYVkJhVVpNZFRkNVQzRmtVa1ZYU1ZWQ1YxcGhaMlJDTVVsUmVrNUtkbU56Tm1KT09XUjRUVEZEYUhOWU5sUmljblZPVWxWek1VWlZTbGRSUzFWMkszZEROR2wwV1VVMWRTOWpVbXhTVVRGaFVrRkdaakZCUTNGeVF6QTJRelJLT1cxTVJVUkJWbkJMZVRCR2FsRnZVbTAxYkU0MGIydDFaVkU0U25kVlIzZFNablV6YTJ0d1JXOVZhVWxLUkVkQmVXNVpLeXR1ZUd0Q2IzSkhkemgzVGpoM1RYSmpRa3hGYm1rd01VWkZjWFZEYlVZMVFUSnRhVzVCVVM5UGVsQmFNMU5tWWpsbFR6RjROWFJ2UTNKelpuWTRUSE1yZW1jNFVrNVhkblpyVTBwT1YwWnNkRVJhTWpBd1FrdG9VbkpPTkdoc1VrRnZiMDVDWTJoWFVXeFNhRkYzSzJGdWN5OVFhRFppUnpkUmR6RjNRV2M1Y25CSlEwdHNUMWhFYkhSaU9XTTNTMnRNUjJOdmFVZEVhMXBtYTJWbk9UTTJXbTkwUTJkaGNtUndlRFZZZVZkNFZqWXpTR3hsWkdSTU5qbFhlR1Y1YVU1Q1kxZzJPV0pJVGtoVlFtTlFVa3N5VnpOVmVuUnhUSEkwTXpWMmQybEZkWFptVUd0NlZrUTBhVUZ2TkdjMmVtWldZbGRKZVc5SE1scEthR0pSVUd0SFUyaFZiVXBIV2sxQlVWRmhRbGR4YnpRcmFFcFNOM1F4ZUdab2NIWnJibVJJUVVaRFZWTkJVMWd6WkZVd1JYVlFUSEF2VlhWRVZqTlBSRGd4ZG1ZdlZrUTNhM0JHTXk5NmFGQkJXVGhrVW1kQlRHUXlOWG8xWkRRNVJHNDNLMkpUWWpSUmNsQkNNbUp6SzNkaGRVdzRlSGxtYm0xalFVRldUM1ZtU0dsUU1rOTBhSE5UVTFkalVYaHlkM05JWlhRM1ZraEhNVkJDYVRCaFRDdFpWa1pPUWxReFl6TTFNazkxWW1vMVRWVXZia3czWXpWSGVIcGhlVXhIVkVGTVZFeG9UbFo2YXlzMmEySnVWMUZxTTJaTFlUTm1UR1ZpY0dsSVlXWTFTMHgyUXpOTlVXYzJjSGRaVDJjNWVsVmlZbk5zVjJ0WFQxbGlaMUpOWVRsWE9UazFSak0zVGtWMlltUlVWM0IxVkhCT2FrZERVek5uVUROMmRFWkxTRGRXVDJGaVVVczFZVk5pT0hWNGJXMUViVXhJT1hkdGJISkdaa0V4YlZwcGIybGhSMlF4TW0wNE5VOXRPRGN5UkhBeWRHSlVkM1pqYms1MVVGQjROa2x0UkZaSVlqTlBWMWdyZFZORFVsaElNelpHZUZscFdrUm1iRXMzTUZOTk5uRjZiemRpTTNFek9XNWpZMGhtVDA1eVl6Um1ZbTFLZUZKTFVHTlRjVXBrTm1SMmMxWnFWMVFyZURGcFlqRjFTSHA1YlhsTk1ITlFNek5uYVd4RWFHZE1iV3BsUzNGWU5uWnZWVEF3VEVWS2JHSnhkRTB4Ynpka1JrZEpjRFpFVFdwUE9HcENUMnBPTUVKaGJqbDRNMVpoVmpVNEx6RXdRM2h4TlVONWVtTjJZMDlpV0RVdlQwcEVRbUZJTkZCSWMxcGplR3BqZGtrcll6VlBkWEJDYTFseWNUaG9SRkV2TDNOblltRTJkRlJNZVZNNVJucHpWRFZhT1VadlRFdHlSSG8wWmtJNFpYaFhTMnhvUzA4M2NHcDRhWGhOZFVwMVYwUlVUV3BtVHk4dmNEZHZLMHhLTWk5UFVWQTBhRkozZWpka2JHeGhWbkpYU1hsS1VrZGhURWRrTVc1TU1tTTJjalEzY21rNWNubzNaVGxRS3pkS1NFazVlVFJVY21rcldFcE9VVk5RWkRScGVFVjJTVGt6TWxoeWNFTk5OM1l6Y1hkT2J6QjFSVEIwZG1KR1JuVmhaV2ROZFVsNFZtZ3ZSeTlUTDBSak1rbHlkemhTVmxoNGVqa3dTMjR2T1ZoamNrb3ZjV2RUTWlzM2FrRTNVRTFMT1M5M01UTnJZbE5ZZEZOd1RsbG1LMWxqWjFGalNtNHdZblJuT0hWQ1pqWXZRMEUyUVZaNEwwVXZkMG9yZEVOTlMyeERjRko2VVVGQlFVRkNTbEpWTlVWeWEwcG5aMmM5UFNrN1ltRmphMmR5YjNWdVpDMXlaWEJsWVhRNmJtOHRjbVZ3WldGME8ySmhZMnRuY205MWJtUXRjMmw2WlRwamIyNTBZV2x1TzJKaFkydG5jbTkxYm1RdGNHOXphWFJwYjI0NlkyVnVkR1Z5TzJsdFlXZGxMWEpsYm1SbGNtbHVaem90ZDJWaWEybDBMVzl3ZEdsdGFYcGxMV052Ym5SeVlYTjBPeTF0Y3kxcGJuUmxjbkJ2YkdGMGFXOXVMVzF2WkdVNmJtVmhjbVZ6ZEMxdVpXbG5hR0p2Y2p0cGJXRm5aUzF5Wlc1a1pYSnBibWM2TFcxdmVpMWpjbWx6Y0MxbFpHZGxjenRwYldGblpTMXlaVzVrWlhKcGJtYzZjR2w0Wld4aGRHVmtPeUkrUEM5emRtYysiPjwvaW1hZ2U+PC9zdmc+";
    string[] private layerNames =   [   
                                        unicode"1/1", 
                                        unicode"Handheld", 
                                        unicode"Head", 
                                        unicode"Head", // mask & helmet
                                        unicode"Eyes", 
                                        unicode"Snout", 
                                        unicode"Body", 
                                        unicode"Type", 
                                        unicode"Background"
                                    ];

    bytes32 public SEASON1_ONE_OF_ONE_IDS_HASH = 0x1980099be486d3bcdb0216af2c717f8dae73c16812d94dc1ac4c1972c9f78195;
    bytes32 public SEASON2_ONE_OF_ONE_IDS_HASH = 0x82998fb94fcc4699e39f14bcb230450ef96ee7f522d72bfb40f6dc283b545417;
    bytes32 public SEASON3_ONE_OF_ONE_IDS_HASH = 0xfdce05748e2384f41f03ee9eba3b81b6a7af2786dabb77f01597948f00cb82f7;

    uint256 public constant NUM_LAYERS = 9;
    uint256 public constant NUM_SEASONS = 4;
    uint16[][NUM_LAYERS] WEIGHTS;
    uint16[NUM_SEASONS][NUM_LAYERS] WEIGHTS_START_INDEX;

    // After contract sealed, no changes are possible anymore
    bool public isContractSealed;
    bool[NUM_SEASONS] public isRevealed;

    // on-chain data for the art
    mapping(uint => address[]) private _traitDataPointers;
    // on-chain data for the metadata
    mapping(uint => mapping(uint => Trait)) private _traitDetails;
    // information about the one of ones for each season
    mapping(uint => OneOfOne[]) public oneOfOnes;

    constructor() {
        // Start index for each season per trait
        WEIGHTS_START_INDEX[0] = [0, 4, 7, 10];
        WEIGHTS_START_INDEX[1] = [23, 35, 45, 23];
        WEIGHTS_START_INDEX[2] = [36, 43, 51, 36];
        WEIGHTS_START_INDEX[3] = [2, 23, 41, 1];
        WEIGHTS_START_INDEX[4] = [23, 28, 33, 23];
        WEIGHTS_START_INDEX[5] = [25, 28, 30, 25];
        WEIGHTS_START_INDEX[6] = [20, 33, 43, 20];
        WEIGHTS_START_INDEX[7] = [7, 7, 7, 7];
        WEIGHTS_START_INDEX[8] = [5, 5, 5, 5];
    
        
        WEIGHTS[0] = [/* 1 */ 2500, 2500, 2500, 2500,
                      /* 2 */ 3334, 3333, 3333,
                      /* 3 */ 3334, 3333, 3333];
        WEIGHTS[1] = [/* Basic */   170, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 125, 125, 175,
                      /* 1 */       100, 80, 80, 100, 100, 100, 80, 80, 80, 100, 80, 100,
                      /* 2 */       118, 90, 110, 90, 120, 112, 120, 80, 120, 120,
                      /* 3 */       77, 77, 77, 77, 77, 77, 77, 78, 77, 77, 77, 77, 77, 78,
                      /* None */    5000];
        WEIGHTS[2] = [/* Basic */   277, 277, 277, 277, 277, 227, 227, 227, 227, 227, 177, 277, 277, 227, 187, 177, 177, 277, 137, 137, 137, 137, 137, 227, 177, 277, 277, 277, 1195, 177, 227, 227, 127, 227, 177, 177,
                      /* 1 */       150, 150, 200, 200, 200, 150, 150,
                      /* 2 */       150, 150, 150, 150, 150, 150, 150, 150,
                      /* 3 */       160, 160, 130, 130, 115, 115, 130, 130, 130];
        WEIGHTS[3] = [/* Basic */   63, 13,
                      /* 1 */       20, 6, 20, 6, 20, 20, 20, 6, 20, 6, 20, 20, 6, 20, 20, 7, 20, 20, 7, 20, 20,
                      /* 2 */       23, 10, 15, 9, 20, 25, 25, 9, 25, 24, 10, 15, 20, 10, 24, 25, 10, 25,
                      /* 3 */       47, 14, 47, 47, 14, 47, 14, 47, 47,
                      /* None */    9600];
        WEIGHTS[4] = [/* Basic */   436, 386, 636, 432, 386, 386, 386, 386, 386, 436, 386, 386, 386, 336, 386, 386, 386, 386, 436, 280, 330, 380, 380,
                      /* 1 */       200, 200, 150, 200, 150,
                      /* 2 */       180, 180, 180, 180, 180,
                      /* 3 */       150, 150, 150, 150, 150, 150];
        WEIGHTS[5] = [/* Basic */   594, 444, 434, 194, 434, 394, 424, 444, 394, 444, 284, 294, 294, 284, 444, 344, 434, 444, 384, 384, 394, 394, 284, 244, 194,
                      /* 1 */       250, 250, 200,
                      /* 2 */       350, 350,
                      /* 3 */       100, 100, 100, 100, 100, 100, 100];
        WEIGHTS[6] = [/* Basic */   460, 305, 410, 460, 365, 365, 415, 415, 415, 660, 415, 395, 285, 285, 285, 285, 285, 415, 415, 415,
                      /* 1 */       150, 200, 200, 150, 200, 200, 150, 150, 150, 200, 150, 200, 150,
                      /* 2 */       225, 225, 225, 225, 225, 155, 225, 260, 260, 225,
                      /* 3 */       187, 190, 187, 187, 187, 187, 187, 187, 190, 187, 187, 187];
        WEIGHTS[7] = [/* Basic */   5000, 900, 500, 900, 900, 900, 900,
                      /* Special */ 10000];
        WEIGHTS[8] = [/* Basic */ 1625, 3500, 1625, 1625, 1625];
    }

    /**
     * Checks if the contract is sealed.
     */
    modifier whenUnsealed() {
        require(!isContractSealed, "Contract is sealed");
        _;
    }

    /**
     * Function to retrieve the metadata & art for a given token.
     * @param tokenId The tokenID to get the data for
     * @param tovData Addition information for retrieving the correct data
     * @param contractData The contract information of the calling contract
     */
    function tokenURI(uint256 tokenId, ToVInfos.ToV memory tovData, ToVInfos.ContractData memory contractData) 
        public 
        view 
        returns (string memory) 
    {
        bool oneOfOne;
        uint256 tovDna;

        (oneOfOne, tovDna) = isOneOfOneTokenId(tokenId, tovData.season);

        uint16[NUM_LAYERS] memory dna;
        if (oneOfOne) {
            dna = getRarityWeights(tovDna);
        } else {            
            dna = getRarityWeights(tovData.dna);
            dna[0] = 0;
        }

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);

        jsonBytes.appendSafe(
            abi.encodePacked(
                '{"name":"',
                contractData.name,
                " #",
                Strings.toString(tokenId),
                '","description":"',
                contractData.description,
                '",'
            )
        );

        if (!isRevealed[tovData.season-1]) {
            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image":"',
                    placeholderImage,
                    '"}'
                )
            );
        } else {
            string memory svgCode = "";
            if (shouldWrapSVG) {
                string memory svgString = getSVG(dna, tovData.season);

                svgCode = string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                svgString,
                                '"></image></svg>'
                            )
                        )
                    )
                );
            } else {
                svgCode = getSVG(dna, tovData.season);
            }

            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image_data":"',
                    svgCode,
                    '",'
                )
            );

            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"attributes":',
                    getMetaData(dna, tovData.season),
                    "}"
                )
            );
        }

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(jsonBytes)
            )
        );
    }

    /**
     * Gets the SVG image of a certain DNA.
     * @param _dna The DNA used to retrieve the art of it
     * @param _season The current season of the DNA
     */
    function getSVG(uint16[NUM_LAYERS] memory _dna, uint256 _season) public view returns (string memory) {
        uint256 traitIndex;
        bool oneOfOne = hasOneOfOne(_dna[0]);
        bool handheld = hasHandHeld(_dna[1]);
        bool mask = hasMask(_dna[3]);
        bool eyesOnTop;

        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);

        svgBytes.appendSafe('<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-color:');
        svgBytes.appendSafe(
            abi.encodePacked(
                backgroundColor,
                ";background-image:url("
            )
        );

        // Put eyes on top if necessary/defined
        (traitIndex, ) = getTraitIndex(_dna[4], 4, _season);

        if (!oneOfOne && !mask && ((traitIndex > 18 && traitIndex < 23) 
        || (_season == 1 && traitIndex == 27 ))) {
            svgBytes.appendSafe(
                abi.encodePacked(
                    "data:",
                    _traitDetails[4][traitIndex].mimetype,
                    ";base64,",
                    Base64.encode(SSTORE2.read(_traitDataPointers[4][traitIndex])),
                    "),url("
                )
            );
            eyesOnTop = true;
        }

        uint16[][NUM_LAYERS] memory weights = WEIGHTS;
        uint256 weightsLength;
        uint256 layerIndexFactor = oneOfOne ? 0 : NUM_LAYERS - 1;

        if (!oneOfOne) {
            for (uint8 i = 1; i < NUM_LAYERS - 1; i++) {
                weightsLength = weights[i].length;
                    
                (traitIndex, ) = getTraitIndex(_dna[i], i, _season);            
                
                // Add layer only for a valid index
                if (traitIndex < weightsLength) {
                    // Make sure there is no mask, eyes or snout when DNA has mask trait
                    // Skip eyes trait if eyes is on top because already appended above
                    if (((i == 2 || i == 4 || i == 5) && !mask) || (i < 4 || (i > 5 && i < 8))) {
                        if (!handheld && i == 1) continue;
                        if (mask && i == 2) continue;
                        if (!mask && i == 3) continue;
                        if (eyesOnTop && i == 4) continue;
                        svgBytes.appendSafe(
                            abi.encodePacked(
                                "data:",
                                _traitDetails[i][traitIndex].mimetype,
                                ";base64,",
                                Base64.encode(SSTORE2.read(_traitDataPointers[i][traitIndex])),
                                "),url("
                            )
                        );
                    }
                }
            }
        }

        (traitIndex, ) = getTraitIndex(_dna[layerIndexFactor], uint8(layerIndexFactor), _season);

        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                _traitDetails[layerIndexFactor][traitIndex].mimetype,
                ";base64,",
                Base64.encode(SSTORE2.read(_traitDataPointers[layerIndexFactor][traitIndex])),
                ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
            )
        );

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svgBytes)
            )
        );
    }

    /**
     * Gets the metadata of a certain tokenId.
     * @param _tokenId The DNA used to retrieve the metadata of it
     * @param _tovData Data of the ToV
     */
    function getMetaDataFromTokenID(uint256 _tokenId, ToVInfos.ToV memory _tovData) public view returns (string memory) {
        if (isRevealed[_tovData.season-1]) {
            bool oneOfOne;
            uint256 tovDna;
            (oneOfOne, tovDna) = isOneOfOneTokenId(_tokenId, _tovData.season);

            uint16[NUM_LAYERS] memory dna;
            if (oneOfOne) {
                dna = getRarityWeights(tovDna);
            } else {            
                dna = getRarityWeights(_tovData.dna);
                dna[0] = 0;
            }
            return getMetaData(dna, _tovData.season);
        }
        return "";
    }

    /**
     * Gets the metadata of a certain DNA.
     * @param _dna The DNA used to retrieve the metadata of it
     * @param _season The current season of the DNA
     */
    function getMetaData(uint16[NUM_LAYERS] memory _dna, uint256 _season) public view returns (string memory) {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        uint256 traitIndex;
        uint64 seasonTraitCount;
        bool afterFirstTrait;
        bool oneOfOne = hasOneOfOne(_dna[0]);
        bool handheld = hasHandHeld(_dna[1]);
        bool mask = hasMask(_dna[3]);
        bool isSeasonTrait;
        uint8 layerIndexFactor = oneOfOne ? 0 : 1;
        
        uint16[][NUM_LAYERS] memory weights = WEIGHTS;
        uint256 weightsLength;

        metadataBytes.appendSafe("[");
        
        for (uint8 i = layerIndexFactor; i < NUM_LAYERS; i++) {
            weightsLength = weights[i].length;

            (traitIndex, isSeasonTrait) = getTraitIndex(_dna[i], i, _season);

            // Add layer only for a valid index
            if (traitIndex < weightsLength) {   
                // Make sure there is no mask, eyes or snout when DNA has mask trait
                if (((oneOfOne && i == 0) || (!oneOfOne && i > 0)) && (_traitDetails[i][traitIndex].hide == false) &&
                (((i == 2 || i == 4 || i == 5) && !mask) || (i < 4 || (i > 5 && i < 9)))) {
                    if (!handheld && i == 1) continue;
                    if (mask && i == 2) continue;
                    if (!mask && i == 3) continue;
                    if (afterFirstTrait) {
                        metadataBytes.appendSafe(",");
                    }

                    if (isSeasonTrait) {
                        ++seasonTraitCount;
                    }

                    metadataBytes.appendSafe(
                        abi.encodePacked(
                            '{"trait_type":"',
                            layerNames[i],
                            '","value":"',
                            _traitDetails[i][traitIndex].name,
                            '"}'
                        )
                    );
                    if (afterFirstTrait == false) {
                        afterFirstTrait = true;
                    }
                    isSeasonTrait = false;
                }

                if (i == NUM_LAYERS - 1) {
                    if (!oneOfOne) {
                        metadataBytes.appendSafe(
                            abi.encodePacked(
                                ',{"trait_type":"',
                                "Season Traits",
                                '","value":"',
                                Strings.toString(seasonTraitCount),
                                '"}'
                            )
                        );
                    }

                    metadataBytes.appendSafe(
                        abi.encodePacked(
                            ',{"trait_type":"',
                            "Season",
                            '","value":"',
                            Strings.toString(_season),
                            '"}'
                        )
                    );
                  
                    metadataBytes.appendSafe("]");
                }
            }
        }       

        return string(metadataBytes);
    }

    /**
     * Checks if a certain tokenID is a one of one and returns the DNA of it.
     * @param _tokenId  The tokenID to check
     * @param _season The season of the one of one
     * @return bool Returns if an one of one was found
     * @return uint256 The DNA of the one of one 
     */
    function isOneOfOneTokenId(uint256 _tokenId, uint256 _season) public view returns (bool, uint256) {
        OneOfOne[] memory seasonOneOfOnes = oneOfOnes[_season];
        for (uint256 i = 0; i < seasonOneOfOnes.length; i++) {
            if (seasonOneOfOnes[i].tokenId == _tokenId) {
                return (true, seasonOneOfOnes[i].dna);
            }
        }
        return (false, 0);
    }

    /**
     * Gets the rarity weights of a certain DNA.
     * @param _dna DNA to get the weights.
     */
    function getRarityWeights(uint256 _dna) internal pure returns (uint16[NUM_LAYERS] memory rarityWeights) {
        for (uint256 i = 0; i < rarityWeights.length; i++) {
            rarityWeights[i] = uint16(_dna % 10000);
            _dna >>= 14;
        }
        return rarityWeights;
    }

    /**
     * Retrieves the trait index for a certain trait weight and season.
     * @param _traitWeight The trait weight to determine the trait index for
     * @param _index Determines which trait type
     * @param _season The season of the trait index
     * @return uint256 returns the trait index
     * @return bool returns if the trait is a season trait
     */
    function getTraitIndex(uint16 _traitWeight, uint8 _index, uint256 _season) public view returns (uint256, bool) {
        uint16 i;
        uint16 lowerBound;
        uint16 percentage;
        uint16[] memory currentWeights = WEIGHTS[_index];
        uint16[NUM_SEASONS] memory startIndices = WEIGHTS_START_INDEX[_index];
        uint256 maxIndex;
        bool seasonTrait;

        if (_season == NUM_SEASONS) {
            maxIndex = currentWeights.length;
           
            // Traits only from the last season except for Background
            if (_index == 8) {
                i = 0;
            } else {
                i = startIndices[_season-1];
            }

            _traitWeight = uint16(multiplyByFactor(_traitWeight, _index));
        } else {
            // take start index of the next season as max of the current season.
            if (_season == 3) {
                maxIndex = currentWeights.length;
            } else {
                maxIndex = startIndices[_season];
            }
            // Traits only from the certain season for one on ones
            if (_index == 0) {
                i = startIndices[_season-1];
            } else {
                i = 0;                
            }
        }

        for (; i < maxIndex; i++) {
            percentage = currentWeights[i];  
    
            if (_traitWeight >= lowerBound && _traitWeight < lowerBound + percentage) {
                if (i >= startIndices[_season-1] && i < maxIndex && _index != 7 && _index != 8) {
                    seasonTrait = true;
                }

                return (i, seasonTrait);
            }
            lowerBound += percentage;
            
            // jump to the correct season index
            // startIndices[0] - 1 stands for the base trait max index
            // Don't jump for OneOfOnes, Background and Type traits
            if((_index != 0 && _index != 7 && _index != 8) && i == (startIndices[0] - 1)) {
                i = startIndices[_season-1] - 1;
            }
        }
        
        // If not found, return index higher than available layers. Will get filtered out.
        return (currentWeights.length, false);
    }

    function hasMask(uint256 _traitWeight) public view returns (bool) {
        return _traitWeight < (10000 - WEIGHTS[3][50]);
    }

    function hasHandHeld(uint256 _traitWeight) public view returns (bool) {
        return _traitWeight < (10000 - WEIGHTS[1][59]);
    }
    
    function hasOneOfOne(uint256 _traitWeight) public pure returns (bool) {
        return _traitWeight > 0;
    }

    /**
     * A factor to keep the trait weight in correct range for the last season.
     * @param _value The value which should be transformed
     * @param _index Determines the trait type
     */
    function multiplyByFactor(uint256 _value, uint256 _index) public pure returns (uint) {
        if (_index == 1) {
            return (_value * 648) / 1000;
        } else if (_index == 2) {
            return (_value * 36) / 100;
        } else if (_index == 3) {
            return (_value * 24) / 100;
        } else if (_index == 4) {
            return (_value * 27) / 100;
        } else if (_index == 5) {
            return (_value * 21) / 100;
        } else if (_index == 6) {
            return (_value * 675) / 1000;
        } else {
            return _value;
        }
    }

    // =========================================================================
    //                             Owner Functions
    // =========================================================================

    /**
     * Function to add the different metadata and art for the layers (trait types) on-chain
     * @param layerIndex Describes which trait type
     * @param traits Array of the metadata and art of the layer
     */
    function addLayer(uint layerIndex, TraitDTO[] calldata traits) public onlyOwner whenUnsealed {
        require(WEIGHTS[layerIndex].length == traits.length, "Traits length is incorrect");
        address[] memory dataPointers = new address[](traits.length);
        for (uint i = 0; i < traits.length; i++) {
            if (traits[i].useExistingData) {
                dataPointers[i] = dataPointers[traits[i].existingDataIndex];
            } else {
                dataPointers[i] = SSTORE2.write(traits[i].data);
            }
            _traitDetails[layerIndex][i] = Trait(traits[i].name, traits[i].mimetype, traits[i].hide);
        }
        _traitDataPointers[layerIndex] = dataPointers;
        return;
    }

    /**
     * Function to add/Update the metadata and art of one trait on-chain.
     * @param layerIndex Describes which trait type
     * @param traitIndex The certain trait which should be updated
     * @param trait Metadata and art of the new/updated trait
     */
    function addTrait(uint layerIndex, uint traitIndex, TraitDTO calldata trait) public onlyOwner whenUnsealed {
        _traitDetails[layerIndex][traitIndex] = Trait(trait.name, trait.mimetype, trait.hide);
        address[] memory dataPointers = _traitDataPointers[layerIndex];
        if (trait.useExistingData) {
            dataPointers[traitIndex] = dataPointers[trait.existingDataIndex];
        } else {
            dataPointers[traitIndex] = SSTORE2.write(trait.data);
        }
        _traitDataPointers[layerIndex] = dataPointers;
        return;
    }

    /**
     * Set the unique hash for the encrypted one of ones. 
     * @param _hash Holds the hash for the one of ones
     * @param _season One of ones for a certain season
     */
    function setOneOfOneHash(bytes32 _hash, uint256 _season) public onlyOwner whenUnsealed {
        if (_season == 1) {
            SEASON1_ONE_OF_ONE_IDS_HASH = _hash;
        } else if (_season == 2) {
            SEASON2_ONE_OF_ONE_IDS_HASH = _hash;
        } else {
            SEASON3_ONE_OF_ONE_IDS_HASH = _hash;
        }
    }

    /**
     * Set the one of one data.
     * @param _oneOfOnes Holds the data for the one of ones
     * @param _season One of ones for a certain season
     */
    function commitOneOfOnes(OneOfOne[] calldata _oneOfOnes, uint256 _season) public onlyOwner whenUnsealed {
        bytes32 hashedOneOfOnes = keccak256(abi.encode(_oneOfOnes));
        if (SEASON1_ONE_OF_ONE_IDS_HASH == hashedOneOfOnes ||
            SEASON2_ONE_OF_ONE_IDS_HASH == hashedOneOfOnes ||
            SEASON3_ONE_OF_ONE_IDS_HASH == hashedOneOfOnes ) {
            oneOfOnes[_season] =  _oneOfOnes;
        }
    }
    
    /**
     * Reveals or unreveals a certain season.
     * @param _season The season which should be revealed
     * @param _reveal Value if reveal or unreveal
     */
    function setRevealSeason(uint256 _season, bool _reveal) public onlyOwner {
        if (_season <= 0 || _season > NUM_SEASONS) revert InvalidSeason();
        isRevealed[_season-1] = _reveal;
    }

    /**
     * Seals the contract, so no changes are possible anymore.
     */
    function sealRendererContract() external whenUnsealed onlyOwner {
        isContractSealed = true;
    }
    function toggleWrapSVG() external onlyOwner {
        shouldWrapSVG = !shouldWrapSVG;
    }
    function setBackgroundColor(string calldata color) external onlyOwner {
        backgroundColor = color;
    }
    function setPlaceholderImage(string calldata placeholder) external onlyOwner {
        placeholderImage = placeholder;
    }    
}