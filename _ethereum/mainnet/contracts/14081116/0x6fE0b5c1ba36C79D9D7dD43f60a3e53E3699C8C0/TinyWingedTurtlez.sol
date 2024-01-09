// SPDX-License-Identifier: MIT

/*

████████╗██╗███╗   ██╗██╗   ██╗                            
╚══██╔══╝██║████╗  ██║╚██╗ ██╔╝                            
   ██║   ██║██╔██╗ ██║ ╚████╔╝                             
   ██║   ██║██║╚██╗██║  ╚██╔╝                              
   ██║   ██║██║ ╚████║   ██║                               
   ╚═╝   ╚═╝╚═╝  ╚═══╝   ╚═╝                               
                                                           
██╗    ██╗██╗███╗   ██╗ ██████╗ ███████╗██████╗            
██║    ██║██║████╗  ██║██╔════╝ ██╔════╝██╔══██╗           
██║ █╗ ██║██║██╔██╗ ██║██║  ███╗█████╗  ██║  ██║           
██║███╗██║██║██║╚██╗██║██║   ██║██╔══╝  ██║  ██║           
╚███╔███╔╝██║██║ ╚████║╚██████╔╝███████╗██████╔╝           
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═════╝            
                                                           
████████╗██╗   ██╗██████╗ ████████╗██╗     ███████╗███████╗
╚══██╔══╝██║   ██║██╔══██╗╚══██╔══╝██║     ██╔════╝╚══███╔╝
   ██║   ██║   ██║██████╔╝   ██║   ██║     █████╗    ███╔╝ 
   ██║   ██║   ██║██╔══██╗   ██║   ██║     ██╔══╝   ███╔╝  
   ██║   ╚██████╔╝██║  ██║   ██║   ███████╗███████╗███████╗
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚══════╝╚══════╝

*/

// @title Tiny Winged Turtlez
// @author @tom_hirst

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./TinyWingedTurtlezLibrary.sol";
import "./Base64.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TinyWingedTurtlez is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    uint256 public freeTurtlez = 1000;
    uint256 public maxSupply = 5000;
    uint256 public turtlePrice = 0.02 ether;

    bool public claimActive;
    bool public mintActive;

    struct Turtle {
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
        uint16 turtleType;
    }

    struct Coordinates {
        string x;
        string y;
    }

    struct Color {
        string hexCode;
        string name;
    }

    struct TurtleType {
        string name;
        string lightHexCode;
        string darkHexCode;
        string pupilHexCode;
        string detailX;
        string detailY;
    }

    mapping(uint256 => Turtle) private tokenIdTurtle;

    Color[] private backgroundColors;
    Color[] private accessoryColors;
    Color[] private wingColors;

    Coordinates[] private pupils;
    Coordinates[][8] private wingTypes;
    TurtleType[] private turtleTypes;

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

    uint16[][6] private traitWeights;

    address public immutable proxyRegistryAddress;
    bool public openSeaProxyActive;
    mapping(address => bool) public proxyToApproved;

    function setPupils(Coordinates[4] memory coordinates) private {
        for (uint8 i = 0; i < coordinates.length; i++) {
            pupils.push(coordinates[i]);
        }
    }

    function setWingType(uint48 wingTypeIndex, Coordinates[3] memory coordinates) private {
        for (uint8 i = 0; i < coordinates.length; i++) {
            wingTypes[wingTypeIndex].push(coordinates[i]);
        }
    }

    function setBackgroundColors(Color[8] memory colors) private {
        for (uint8 i = 0; i < colors.length; i++) {
            backgroundColors.push(colors[i]);
        }
    }

    function setAccessoryColors(Color[5] memory colors) private {
        for (uint8 i = 0; i < colors.length; i++) {
            accessoryColors.push(colors[i]);
        }
    }

    function setWingColors(Color[4] memory colors) private {
        for (uint8 i = 0; i < colors.length; i++) {
            wingColors.push(colors[i]);
        }
    }

    function setTurtleTypes(TurtleType[4] memory types) private {
        for (uint8 i = 0; i < types.length; i++) {
            turtleTypes.push(types[i]);
        }
    }

    function toggleOpenSeaProxy() public onlyOwner {
        openSeaProxyActive = !openSeaProxyActive;
    }

    function toggleProxy(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    constructor(address _proxyRegistryAddress) ERC721('Tiny Winged Turtlez', 'TWT') {
        // Start at token 1
        _nextTokenId.increment();

        // Wing type rarity
        traitWeights[0] = [1248, 986, 842, 724, 569, 371, 209, 51];

        // Wing color rarity
        traitWeights[1] = [3200, 1200, 500, 100];

        // Boots rarity
        traitWeights[2] = [1622, 3378];

        // Bandana rarity
        traitWeights[3] = [1587, 3413];

        // Tongue rarity
        traitWeights[4] = [3579, 1421];

        // Turtle type rarity
        traitWeights[5] = [4752, 141, 79, 28];

        // OpenSea proxy contract
        proxyRegistryAddress = _proxyRegistryAddress;

        // Background colors
        setBackgroundColors(
            [
                Color({ hexCode: '#bcdfb9', name: 'Green' }),
                Color({ hexCode: '#d5bada', name: 'Purple' }),
                Color({ hexCode: '#ecc1db', name: 'Pink' }),
                Color({ hexCode: '#e3c29e', name: 'Orange' }),
                Color({ hexCode: '#9cd7d5', name: 'Turquoise' }),
                Color({ hexCode: '#faf185', name: 'Yellow' }),
                Color({ hexCode: '#b0d9f4', name: 'Blue' }),
                Color({ hexCode: '#333333', name: 'Black' })
            ]
        );

        // Accessory colors
        setAccessoryColors(
            [
                Color({ hexCode: '#c52035', name: 'Red' }),
                Color({ hexCode: '#67489d', name: 'Purple' }),
                Color({ hexCode: '#1475bc', name: 'Blue' }),
                Color({ hexCode: '#cc5927', name: 'Orange' }),
                Color({ hexCode: '#e31c79', name: 'Pink' })
            ]
        );

        // Wing colors
        setWingColors(
            [
                Color({ hexCode: '#ffffff', name: 'White' }),
                Color({ hexCode: '#af8d56', name: 'Bronze' }),
                Color({ hexCode: '#afafaf', name: 'Silver' }),
                Color({ hexCode: '#d4af34', name: 'Gold' })
            ]
        );

        // Pupils
        setPupils(
            [
                Coordinates({ x: '16', y: '10' }),
                Coordinates({ x: '17', y: '10' }),
                Coordinates({ x: '16', y: '11' }),
                Coordinates({ x: '17', y: '11' })
            ]
        );

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

        // Turtle Types
        setTurtleTypes(
            [
                TurtleType({
                    name: 'Normal',
                    lightHexCode: '#65bc48',
                    darkHexCode: '#567e39',
                    pupilHexCode: '#000000',
                    detailX: '7',
                    detailY: '12'
                }),
                TurtleType({
                    name: 'Zombie',
                    lightHexCode: '#7ea26b',
                    darkHexCode: '#4c6141',
                    pupilHexCode: '#ff0005',
                    detailX: '17',
                    detailY: '13'
                }),
                TurtleType({
                    name: 'Droid',
                    lightHexCode: '#d4af34',
                    darkHexCode: '#a07e2d',
                    pupilHexCode: '#4d3311',
                    detailX: '16',
                    detailY: '7'
                }),
                TurtleType({
                    name: 'Alien',
                    lightHexCode: '#8cb0b0',
                    darkHexCode: '#578888',
                    pupilHexCode: '#027287',
                    detailX: '16',
                    detailY: '12'
                })
            ]
        );
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function weightedRarityGenerator(uint16 pseudoRandomNumber, uint8 trait) private view returns (uint16) {
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

    function createTokenIdTurtle(uint256 tokenId) public view returns (Turtle memory) {
        uint256 pseudoRandomBase = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId)));

        return
            Turtle({
                backgroundColor: uint16(uint16(pseudoRandomBase) % 8),
                wingType: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 1) % maxSupply), 0),
                wingColor: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 2) % maxSupply), 1),
                bandana: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 3) % maxSupply), 2) == 1,
                bandanaColor: uint16(uint16(pseudoRandomBase >> 4) % 5),
                boots: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 5) % maxSupply), 3) == 1,
                bootsColor: uint16(uint16(pseudoRandomBase >> 6) % 5),
                pupil: uint16(uint16(pseudoRandomBase >> 7) % 4),
                tongue: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 8) % maxSupply), 4) == 1,
                tail: uint16(uint16(pseudoRandomBase >> 9) % 2) == 1,
                turtleType: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 10) % maxSupply), 5)
            });
    }

    function getTurtleBase(Turtle memory turtle) private view returns (string memory turtleBase) {
        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    backgroundColors[turtle.backgroundColor].hexCode,
                    "' height='24' width='24' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].lightHexCode,
                    "' height='1' width='3' x='15' y='9' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].lightHexCode,
                    "' height='3' width='4' x='15' y='10' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].lightHexCode,
                    "' height='1' width='3' x='15' y='13' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].lightHexCode,
                    "' height='1' width='8' x='7' y='14' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].lightHexCode,
                    "' height='1' width='2' x='7' y='15' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].lightHexCode,
                    "' height='1' width='2' x='13' y='15' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].darkHexCode,
                    "' height='1' width='4' x='9' y='9' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].darkHexCode,
                    "' height='1' width='6' x='8' y='10' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].darkHexCode,
                    "' height='3' width='8' x='7' y='11' />",
                    "<rect fill='#ffffff' height='2' width='2' x='16' y='10' />"
                )
            );
    }

    function getTurtleWings(Turtle memory turtle) private view returns (string memory turtleWings) {
        turtleWings = string(
            abi.encodePacked(
                "<rect fill='",
                wingColors[turtle.wingColor].hexCode,
                "' height='1' width='6' x='5' y='8' />",
                "<rect fill='",
                wingColors[turtle.wingColor].hexCode,
                "' height='1' width='4' x='7' y='9' />",
                "<rect fill='",
                wingColors[turtle.wingColor].hexCode,
                "' height='1' width='2' x='9' y='10' />"
            )
        );

        // Regular wings don't need detail
        if (turtle.wingType != 0) {
            for (uint8 i = 0; i < wingTypes[turtle.wingType].length; i++) {
                turtleWings = string(
                    abi.encodePacked(
                        turtleWings,
                        "<rect fill='",
                        wingColors[turtle.wingColor].hexCode,
                        "' height='1' width='1' x='",
                        wingTypes[turtle.wingType][i].x,
                        "' y='",
                        wingTypes[turtle.wingType][i].y,
                        "' />"
                    )
                );
            }
        }

        return turtleWings;
    }

    function getTurtlePupil(Turtle memory turtle) private view returns (string memory turtlePupil) {
        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].pupilHexCode,
                    "' height='1' width='1' x='",
                    pupils[turtle.pupil].x,
                    "' y='",
                    pupils[turtle.pupil].y,
                    "' />"
                )
            );
    }

    function getTurtleDetail(Turtle memory turtle) private view returns (string memory turtleDetail) {
        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].darkHexCode,
                    "' height='2' width='1' x='",
                    turtleTypes[turtle.turtleType].detailX,
                    "' y='",
                    turtleTypes[turtle.turtleType].detailY,
                    "' />"
                )
            );
    }

    function getTurtleBoots(Turtle memory turtle) private view returns (string memory turtleBoots) {
        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    accessoryColors[turtle.bootsColor].hexCode,
                    "' height='1' width='2' x='7' y='15' /><rect fill='",
                    accessoryColors[turtle.bootsColor].hexCode,
                    "' height='1' width='2' x='13' y='15' />"
                )
            );
    }

    function getTurtleBandana(Turtle memory turtle) private view returns (string memory turtleBandana) {
        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    accessoryColors[turtle.bandanaColor].hexCode,
                    "' height='1' width='1' x='14' y='8' /><rect fill='",
                    accessoryColors[turtle.bandanaColor].hexCode,
                    "' height='1' width='3' x='15' y='9' />"
                )
            );
    }

    function getTurtleTongue() private pure returns (string memory turtleTongue) {
        return string(abi.encodePacked("<rect fill='#ed2024' height='1' width='1' x='18' y='13' />"));
    }

    function getTurtleTail(Turtle memory turtle) private view returns (string memory turtleTail) {
        string memory tailY = turtle.tail ? '12' : '14';

        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].lightHexCode,
                    "' height='1' width='1' x='6' y='13' />",
                    "<rect fill='",
                    turtleTypes[turtle.turtleType].lightHexCode,
                    "' height='1' width='1' x='5' y='",
                    tailY,
                    "' />"
                )
            );
    }

    function getTokenIdTurtleSvg(Turtle memory turtle) public view returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                getTurtleBase(turtle),
                getTurtleWings(turtle),
                getTurtlePupil(turtle),
                getTurtleDetail(turtle),
                getTurtleTail(turtle)
            )
        );

        if (turtle.boots) {
            svg = string(abi.encodePacked(svg, getTurtleBoots(turtle)));
        }

        // Droids can't have a bandana
        if (turtle.bandana && turtle.turtleType != 2) {
            svg = string(abi.encodePacked(svg, getTurtleBandana(turtle)));
        }

        // Zombies can't have a tongue
        if (turtle.tongue && turtle.turtleType != 1) {
            svg = string(abi.encodePacked(svg, getTurtleTongue()));
        }

        return
            string(
                abi.encodePacked(
                    "<svg id='tiny-winged-turtle' xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 24 24'>",
                    svg,
                    '<style>#tiny-winged-turtle{shape-rendering:crispedges;}</style></svg>'
                )
            );
    }

    function getTokenIdTurtleMetadata(Turtle memory turtle) public view returns (string memory metadata) {
        metadata = string(
            abi.encodePacked(
                metadata,
                '{"trait_type":"Background", "value":"',
                backgroundColors[turtle.backgroundColor].name,
                '"},',
                '{"trait_type":"Type", "value":"',
                turtleTypes[turtle.turtleType].name,
                '"},',
                '{"trait_type":"Wings", "value":"',
                wingTypeValues[turtle.wingType],
                '"},',
                '{"trait_type":"Wing Color", "value":"',
                wingColors[turtle.wingColor].name,
                '"},',
                '{"trait_type":"Eyes", "value":"',
                pupilValues[turtle.pupil],
                '"}'
            )
        );

        if (turtle.boots) {
            metadata = string(
                abi.encodePacked(
                    metadata,
                    ',{"trait_type":"Boots", "value":"',
                    accessoryColors[turtle.bootsColor].name,
                    '"}'
                )
            );
        }

        // Droids can't have a bandana
        if (turtle.bandana && turtle.turtleType != 2) {
            metadata = string(
                abi.encodePacked(
                    metadata,
                    ',{"trait_type":"Bandana", "value":"',
                    accessoryColors[turtle.bandanaColor].name,
                    '"}'
                )
            );
        }

        // Zombies can't have a tongue
        if (turtle.tongue && turtle.turtleType != 1) {
            metadata = string(abi.encodePacked(metadata, ',{"trait_type":"Tongue", "value":"True"}'));
        }

        if (turtle.tail) {
            metadata = string(abi.encodePacked(metadata, ',{"trait_type":"Tail", "value":"Up"}'));
        } else {
            metadata = string(abi.encodePacked(metadata, ',{"trait_type":"Tail", "value":"Down"}'));
        }

        return string(abi.encodePacked('[', metadata, ']'));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        Turtle memory turtle = tokenIdTurtle[tokenId];

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Tiny Winged Turtle #',
                                    TinyWingedTurtlezLibrary.toString(tokenId),
                                    '", "description": "Tiny Winged Turtlez are a collection of fully on-chain, randomly generated, small turtles with wings.", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(bytes(getTokenIdTurtleSvg(turtle))),
                                    '","attributes":',
                                    getTokenIdTurtleMetadata(turtle),
                                    '}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function internalMint(uint256 numberOfTokens) private {
        require(numberOfTokens > 0, 'Quantity must be greater than 0.');
        require(numberOfTokens < 11, 'Exceeds max per mint.');
        require(totalSupply() + numberOfTokens <= maxSupply, 'Exceeds max supply.');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _nextTokenId.current();

            tokenIdTurtle[tokenId] = createTokenIdTurtle(tokenId);

            _safeMint(msg.sender, tokenId);

            _nextTokenId.increment();
        }
    }

    function ownerClaim(uint256 numberOfTokens) external onlyOwner {
        internalMint(numberOfTokens);
    }

    function claim(uint256 numberOfTokens) external {
        require(claimActive, 'Claiming not active yet.');
        require(totalSupply() + numberOfTokens <= freeTurtlez, 'Exceeds claim supply.');

        internalMint(numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable {
        require(mintActive, 'Mint not active yet.');
        require(msg.value >= numberOfTokens * turtlePrice, 'Wrong ETH value sent.');

        internalMint(numberOfTokens);
    }

    function setFreeTurtlez(uint256 newFreeTurtlez) external onlyOwner {
        require(newFreeTurtlez <= maxSupply, 'Would increase max supply.');
        freeTurtlez = newFreeTurtlez;
    }

    function setTurtlePrice(uint256 newTurtlePrice) external onlyOwner {
        turtlePrice = newTurtlePrice;
    }

    function toggleClaim() external onlyOwner {
        claimActive = !claimActive;
    }

    function toggleMint() external onlyOwner {
        mintActive = !mintActive;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Allow OpenSea proxy contract
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if (address(proxyRegistry.proxies(owner)) == operator) {
            return openSeaProxyActive;
        }

        // Allow future contracts
        if (proxyToApproved[operator]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function reduceSupply() external onlyOwner {
        require(totalSupply() < maxSupply, 'All minted.');
        maxSupply = totalSupply();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
