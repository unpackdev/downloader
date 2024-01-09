// SPDX-License-Identifier: GPL-3.0

/*

   ▄████████   ▄▄▄▄███▄▄▄▄    ▄██████▄   ▄█                                        
  ███    ███ ▄██▀▀▀███▀▀▀██▄ ███    ███ ███                                        
  ███    █▀  ███   ███   ███ ███    ███ ███                                        
  ███        ███   ███   ███ ███    ███ ███                                        
▀███████████ ███   ███   ███ ███    ███ ███                                        
         ███ ███   ███   ███ ███    ███ ███                                        
   ▄█    ███ ███   ███   ███ ███    ███ ███▌    ▄                                  
 ▄████████▀   ▀█   ███   █▀   ▀██████▀  █████▄▄██                                  
                                        ▀                                          
 ▄█     █▄   ▄█  ███▄▄▄▄      ▄██████▄     ▄████████ ████████▄                     
███     ███ ███  ███▀▀▀██▄   ███    ███   ███    ███ ███   ▀███                    
███     ███ ███▌ ███   ███   ███    █▀    ███    █▀  ███    ███                    
███     ███ ███▌ ███   ███  ▄███         ▄███▄▄▄     ███    ███                    
███     ███ ███▌ ███   ███ ▀▀███ ████▄  ▀▀███▀▀▀     ███    ███                    
███     ███ ███  ███   ███   ███    ███   ███    █▄  ███    ███                    
███ ▄█▄ ███ ███  ███   ███   ███    ███   ███    ███ ███   ▄███                    
 ▀███▀███▀  █▀    ▀█   █▀    ████████▀    ██████████ ████████▀                     
                                                                                   
    ███     ███    █▄     ▄████████     ███      ▄█          ▄████████  ▄███████▄  
▀█████████▄ ███    ███   ███    ███ ▀█████████▄ ███         ███    ███ ██▀     ▄██ 
   ▀███▀▀██ ███    ███   ███    ███    ▀███▀▀██ ███         ███    █▀        ▄███▀ 
    ███   ▀ ███    ███  ▄███▄▄▄▄██▀     ███   ▀ ███        ▄███▄▄▄      ▀█▀▄███▀▄▄ 
    ███     ███    ███ ▀▀███▀▀▀▀▀       ███     ███       ▀▀███▀▀▀       ▄███▀   ▀ 
    ███     ███    ███ ▀███████████     ███     ███         ███    █▄  ▄███▀       
    ███     ███    ███   ███    ███     ███     ███▌    ▄   ███    ███ ███▄     ▄█ 
   ▄████▀   ████████▀    ███    ███    ▄████▀   █████▄▄██   ██████████  ▀████████▀ 

*/

// @title Smol Winged Turtlez
// @author @tom_hirst

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SmolWingedTurtlezLibrary.sol";
import "./Base64.sol";

contract SmolWingedTurtlez is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    uint256 public maxSupply = 6969;
    uint256 public constant TOKEN_PRICE = 0.02 ether;

    struct Hash {
        uint16 backgroundColor;
        uint16 wingColor;
        uint16 wingType;
        bool bandana;
        uint16 bandanaColor;
        bool boots;
        uint16 bootsColor;
        uint16 pupil;
        bool tongue;
        bool tail;
    }

    struct Coordinates {
        string x;
        string y;
    }

    struct Color {
        string hexCode;
        string name;
    }

    Hash[] private tokenIdHash;
    mapping(uint256 => Coordinates) private pupils;
    mapping(uint256 => Coordinates[]) private wingTypes;
    mapping(uint256 => Color[]) private colorPalettes;

    string[] private wingTypeValues = [
        'Regular',
        'Long',
        'Tall',
        'Spiky',
        'Ruffled',
        'Loose Feathers',
        'Sparkly',
        'Claw'
    ];

    string[] private pupilValues = ['Mindful', 'Positive', 'Reserved', 'Focused'];

    uint16[][5] traitWeights;

    function setPupil(
        uint48 pupilIndex,
        string memory x,
        string memory y
    ) private {
        pupils[pupilIndex] = Coordinates(x, y);
    }

    function setWingType(uint48 wingTypeIndex, Coordinates[3] memory coordinates) private {
        for (uint8 i = 0; i < coordinates.length; i++) {
            wingTypes[wingTypeIndex].push(coordinates[i]);
        }
    }

    function setColorPalette(uint48 colorPaletteIndex, Color[8] memory colors) private {
        for (uint8 i = 0; i < colors.length; i++) {
            colorPalettes[colorPaletteIndex].push(colors[i]);
        }
    }

    constructor() ERC721('Smol Winged Turtlez', 'SWT') {
        // Start at token 1
        _nextTokenId.increment();

        // Dummy value to prevent need for offset
        tokenIdHash.push(
            Hash({
                backgroundColor: 0,
                wingType: 0,
                wingColor: 0,
                bandana: false,
                bandanaColor: 0,
                boots: false,
                bootsColor: 0,
                pupil: 0,
                tongue: false,
                tail: false
            })
        );

        // Wing type rarity
        traitWeights[0] = [1600, 1350, 1200, 1050, 850, 550, 369];

        // Wing color rarity
        traitWeights[1] = [3400, 2250, 1250, 69];

        // Boots rarity
        traitWeights[2] = [1500, 5469];

        // Bandana rarity
        traitWeights[3] = [2069, 4900];

        // Tongue rarity
        traitWeights[4] = [5000, 1969];

        // Background colors
        setColorPalette(
            0,
            [
                Color({ hexCode: '#bcdfb9', name: 'Green' }),
                Color({ hexCode: '#d5bada', name: 'Purple' }),
                Color({ hexCode: '#ecc1db', name: 'Pink' }),
                Color({ hexCode: '#e3c29e', name: 'Orange' }),
                Color({ hexCode: '#84cfc6', name: 'Turquoise' }),
                Color({ hexCode: '#faf185', name: 'Yellow' }),
                Color({ hexCode: '#b0d9f4', name: 'Blue' }),
                Color({ hexCode: '#444444', name: 'Black' })
            ]
        );

        // Accessory colors
        setColorPalette(
            1,
            [
                Color({ hexCode: '#567e39', name: 'Green' }),
                Color({ hexCode: '#8c3895', name: 'Purple' }),
                Color({ hexCode: '#ab62a8', name: 'Pink' }),
                Color({ hexCode: '#da7327', name: 'Orange' }),
                Color({ hexCode: '#00a794', name: 'Turquoise' }),
                Color({ hexCode: '#decf22', name: 'Yellow' }),
                Color({ hexCode: '#1b80c4', name: 'Blue' }),
                Color({ hexCode: '#222222', name: 'Black' })
            ]
        );

        // Wing colors
        setColorPalette(
            2,
            [
                Color({ hexCode: '#ffffff', name: 'White' }),
                Color({ hexCode: '#af8d56', name: 'Bronze' }),
                Color({ hexCode: '#a7a5a5', name: 'Silver' }),
                Color({ hexCode: '#d4af34', name: 'Gold' }),
                Color({ hexCode: '#ffffff', name: 'White' }),
                Color({ hexCode: '#af8d56', name: 'Bronze' }),
                Color({ hexCode: '#a7a5a5', name: 'Silver' }),
                Color({ hexCode: '#d4af34', name: 'Gold' })
            ]
        );

        // Mindful
        setPupil(0, '16', '10');

        // Positive
        setPupil(1, '17', '10');

        // Reserved
        setPupil(2, '16', '11');

        // Focused
        setPupil(3, '17', '11');

        // Regular
        setWingType(
            0,
            [Coordinates({ x: '0', y: '0' }), Coordinates({ x: '0', y: '0' }), Coordinates({ x: '0', y: '0' })]
        );

        // Long
        setWingType(
            1,
            [Coordinates({ x: '3', y: '8' }), Coordinates({ x: '4', y: '8' }), Coordinates({ x: '5', y: '8' })]
        );

        // Tall
        setWingType(
            2,
            [Coordinates({ x: '5', y: '8' }), Coordinates({ x: '5', y: '7' }), Coordinates({ x: '5', y: '6' })]
        );

        // Spiky
        setWingType(
            3,
            [Coordinates({ x: '4', y: '7' }), Coordinates({ x: '6', y: '7' }), Coordinates({ x: '8', y: '7' })]
        );

        // Ruffled
        setWingType(
            4,
            [Coordinates({ x: '6', y: '7' }), Coordinates({ x: '9', y: '7' }), Coordinates({ x: '10', y: '6' })]
        );

        // Loose
        setWingType(
            5,
            [Coordinates({ x: '8', y: '12' }), Coordinates({ x: '10', y: '12' }), Coordinates({ x: '12', y: '12' })]
        );

        // Sparkly
        setWingType(
            6,
            [Coordinates({ x: '4', y: '6' }), Coordinates({ x: '2', y: '7' }), Coordinates({ x: '3', y: '8' })]
        );

        // Claw
        setWingType(
            7,
            [Coordinates({ x: '4', y: '9' }), Coordinates({ x: '3', y: '10' }), Coordinates({ x: '5', y: '10' })]
        );
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function weightedRarityGenerator(uint16 pseudoRandomNumber, uint8 trait) internal view returns (uint16) {
        uint16 lowerBound = 0;

        for (uint8 i = 0; i < traitWeights[trait].length; i++) {
            uint16 weight = traitWeights[trait][i];

            if (pseudoRandomNumber >= lowerBound && pseudoRandomNumber < lowerBound + weight) {
                return i;
            }

            lowerBound = lowerBound + weight;
        }

        revert();
    }

    function createTokenIdHash(uint256 tokenId) public view returns (Hash memory) {
        uint256 pseudoRandomBase = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId)));

        return
            Hash({
                backgroundColor: uint16(uint16(pseudoRandomBase) % 8),
                wingType: weightedRarityGenerator(uint16(uint16(pseudoRandomBase) % 6969), 0),
                wingColor: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 48) % 6969), 1),
                bandana: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 96) % 6969), 2) == 1,
                bandanaColor: uint16(uint16(pseudoRandomBase >> 144) % 8),
                boots: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 192) % 6969), 3) == 1,
                bootsColor: uint16(uint16(pseudoRandomBase >> 240) % 8),
                pupil: uint16(uint16(pseudoRandomBase) % 4),
                tongue: weightedRarityGenerator(uint16(uint16(pseudoRandomBase) % 6969), 4) == 1,
                tail: uint16(uint16(pseudoRandomBase) % 2) == 1
            });
    }

    function getTokenIdHashSvg(Hash memory hash) public view returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                svg,
                "<rect fill='",
                colorPalettes[0][hash.backgroundColor].hexCode,
                "' height='24' width='24' />",
                "<rect fill='#567e39' height='1' width='4' x='9' y='9' />",
                "<rect fill='#567e39' height='1' width='6' x='8' y='10' />",
                "<rect fill='#567e39' height='3' width='8' x='7' y='11' />",
                "<rect fill='#65bc48' height='1' width='3' x='15' y='9' />",
                "<rect fill='#65bc48' height='3' width='4' x='15' y='10' />",
                "<rect fill='#65bc48' height='1' width='3' x='15' y='13' />",
                "<rect fill='#65bc48' height='1' width='8' x='7' y='14' />",
                "<rect fill='#65bc48' height='1' width='2' x='7' y='15' />",
                "<rect fill='#65bc48' height='1' width='2' x='13' y='15' />"
                "<rect fill='#ffffff' height='2' width='2' x='16' y='10' />",
                "<rect fill='",
                colorPalettes[2][hash.wingColor].hexCode,
                "' height='1' width='6' x='5' y='8' />",
                "<rect fill='",
                colorPalettes[2][hash.wingColor].hexCode,
                "' height='1' width='4' x='7' y='9' />",
                "<rect fill='",
                colorPalettes[2][hash.wingColor].hexCode,
                "' height='1' width='2' x='9' y='10' />",
                "<rect fill='#65bc48' height='1' width='1' x='6' y='13' />",
                "<rect fill='#000000' height='1' width='1' x='",
                pupils[hash.pupil].x,
                "' y='",
                pupils[hash.pupil].y,
                "' />"
            )
        );

        if (hash.wingType != 0) {
            for (uint8 i = 0; i < wingTypes[hash.wingType].length; i++) {
                svg = string(
                    abi.encodePacked(
                        svg,
                        "<rect fill='",
                        colorPalettes[2][hash.wingColor].hexCode,
                        "' height='1' width='1' x='",
                        wingTypes[hash.wingType][i].x,
                        "' y='",
                        wingTypes[hash.wingType][i].y,
                        "' />"
                    )
                );
            }
        }

        if (hash.boots) {
            svg = string(
                abi.encodePacked(
                    svg,
                    "<rect fill='",
                    colorPalettes[1][hash.bootsColor].hexCode,
                    "' height='1' width='2' x='7' y='15' /><rect fill='",
                    colorPalettes[1][hash.bootsColor].hexCode,
                    "' height='1' width='2' x='13' y='15' />"
                )
            );
        }

        if (hash.bandana) {
            svg = string(
                abi.encodePacked(
                    svg,
                    "<rect fill='",
                    colorPalettes[1][hash.bandanaColor].hexCode,
                    "' height='1' width='1' x='14' y='8' /><rect fill='",
                    colorPalettes[1][hash.bandanaColor].hexCode,
                    "' height='1' width='3' x='15' y='9' />"
                )
            );
        }

        if (hash.tongue) {
            svg = string(abi.encodePacked(svg, "<rect fill='#ed2024' height='1' width='1' x='18' y='13' />"));
        }

        if (hash.tail) {
            svg = string(abi.encodePacked(svg, "<rect fill='#65bc48' height='1' width='1' x='5' y='12' />"));
        } else {
            svg = string(abi.encodePacked(svg, "<rect fill='#65bc48' height='1' width='1' x='5' y='14' />"));
        }

        return
            string(
                abi.encodePacked(
                    "<svg id='smol-winged-turtle' xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 24 24'>",
                    svg,
                    '<style>#smol-winged-turtle{shape-rendering:crispedges;}</style></svg>'
                )
            );
    }

    function getTokenIdHashMetadata(Hash memory hash) public view returns (string memory metadata) {
        metadata = string(
            abi.encodePacked(
                metadata,
                '{"trait_type":"Background", "value":"',
                colorPalettes[0][hash.backgroundColor].name,
                '"},',
                '{"trait_type":"Wing Type", "value":"',
                wingTypeValues[hash.wingType],
                '"},',
                '{"trait_type":"Wing Color", "value":"',
                colorPalettes[2][hash.wingColor].name,
                '"},',
                '{"trait_type":"Eyes", "value":"',
                pupilValues[hash.pupil],
                '"}'
            )
        );

        if (hash.boots) {
            metadata = string(
                abi.encodePacked(
                    metadata,
                    ',{"trait_type":"Boots", "value":"',
                    colorPalettes[1][hash.bootsColor].name,
                    '"}'
                )
            );
        }

        if (hash.bandana) {
            metadata = string(
                abi.encodePacked(
                    metadata,
                    ',{"trait_type":"Bandana", "value":"',
                    colorPalettes[1][hash.bandanaColor].name,
                    '"}'
                )
            );
        }

        if (hash.tongue) {
            metadata = string(abi.encodePacked(metadata, ',{"trait_type":"Tongue", "value":"True"}'));
        }

        if (hash.tail) {
            metadata = string(abi.encodePacked(metadata, ',{"trait_type":"Tail", "value":"Up"}'));
        } else {
            metadata = string(abi.encodePacked(metadata, ',{"trait_type":"Tail", "value":"Down"}'));
        }

        return string(abi.encodePacked('[', metadata, ']'));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        Hash memory hash = tokenIdHash[tokenId];

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Smol Winged Turtle #',
                                    SmolWingedTurtlezLibrary.toString(tokenId),
                                    '", "description": "Smol Winged Turtlez is a collection of up to 6,969 fully on-chain characters that might be a great investment opportunity. Mint your turtlez before they fly away!", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(bytes(getTokenIdHashSvg(hash))),
                                    '","attributes":',
                                    getTokenIdHashMetadata(hash),
                                    '}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function mint(uint256 numberOfTokens) public payable {
        require(numberOfTokens > 0, 'Quantity must be greater than 0.');
        require(numberOfTokens < 6, 'Exceeds max per mint.');
        require(totalSupply() + numberOfTokens <= maxSupply, 'Exceeds max supply.');
        require(msg.value >= numberOfTokens * TOKEN_PRICE, 'Wrong ETH value sent.');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _nextTokenId.current();

            tokenIdHash.push(createTokenIdHash(tokenId));

            _safeMint(msg.sender, tokenId);

            _nextTokenId.increment();
        }
    }

    function reduceSupply() external onlyOwner {
        require(totalSupply() < maxSupply, 'All minted.');
        maxSupply = totalSupply();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
