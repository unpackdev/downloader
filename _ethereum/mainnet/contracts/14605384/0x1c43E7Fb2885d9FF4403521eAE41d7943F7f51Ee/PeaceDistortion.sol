// SPDX-License-Identifier: MIT
/*
                    ..:---========--::..                    
                .-=======================-:.                
             :===============================-:             
          .=======================-=============-.          
        :===========-:.   :======:   .:-==========-.        
      .=++=======:.       :======:       .:-========-.      
     -++++====-.          :======:          .-======--:     
    =+++++===.            :======:             -====----    
   =++++++=:              :======:              .-==-----   
  =++++++=.               :======:                -=------  
 -++++++=.                :======:                 -------: 
 +++++++:                 :======:                 .------- 
:++++++=                  :======:                  -------:
=++++++:                  :======:                  :-------
+++++++.                  :======:                  .-------
+++++++.                 :========:                 .-------
=++++++:               :============:               .-------
:++++++=             :================:             -------:
 +++++++:          :====================:          .------- 
 -++++++=.       :========================:        -------: 
  =++++++=.    :=========:-======-:=========:     -=------  
   =++++++=: :=========:  :======:  :=========: .-==-----   
    =+++++===========:    :======:    :=============----    
     -++++=========:      :======:      :===========--:     
      .=++========.       :======:       .-=========-.      
        :===========-:.   :======:   .::-=========-.        
          :=======================-=============-.          
             :===============================-:             
                .-=======================-:.                

Peace Distortion was a collaboration between Peace DAO Movement 
https://juicebox.money/#/p/peace and https://peace.move.xyz/
and Artist 0xon-chain world, Discord on-chain world#4444
Thank you https://twitter.com/onchainworld for contributing the code.
Checkout the ongoing contributions for Peace in Ukraine in the links above.
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract PeaceDistortion is ERC721, Ownable {
    // Keeping track of supply and displaying it.
    using Counters for Counters.Counter;
    Counters.Counter private distortionSupply;

    /**
     * @notice This shows the randomness of block 14600852 which included the mint of the 1000th original Distortion piece.
     *
     */
    string public constant HASH_OF_BLOCK =
        "0x6e56139840a2bc1bfbba5aad5e51d8d68acf6a010a1e67f713a1d8fa371a836f";

    string public OPENSEA_STORE_METADATA = "ipfs://QmbZVKzsKWy3BJoKU9WSuKJbuDXdZKuy2WYpwspdoxhAaD";

    constructor() ERC721("Peace DAO Movement", "PEACE") { }
    
    /**
     *  @notice Set OpenSea metadata per https://docs.opensea.io/docs/contract-level-metadata
     */
    function setContractURI(string memory _contractMetadataURI) public onlyOwner {
        OPENSEA_STORE_METADATA = _contractMetadataURI;
    }

    /**
     *  @notice Get OpenSea metadata
     */
    function contractURI() public view returns (string memory) {
        return OPENSEA_STORE_METADATA;
    }

    /**
     * @notice Returns the total supply of tokens airdropped.
     *
     */
    function totalSupply() public view returns (uint256 supply) {
        return distortionSupply.current();
    }

    /**
     * @notice Once this shows true, it cannot be reversed, making the airdrop function uncallable.
     *
     */
    bool public airdropPermanentlyDisabled;

    /**
     * @notice This function will be called to disable airdrops permanently once all the tokens have been airdropped.
     *
     */
    function disableAirdrop() public onlyOwner {
        require(
            !airdropPermanentlyDisabled,
            "Once the airdrop function is disabled it cannot be re-enabled."
        );
        airdropPermanentlyDisabled = true;
    }

    /**
     * @notice The airdrop function which will be permanently disabled once all tokens have been airdropped.
     *
     */
    function airdrop(address[] memory _to, uint256[][] memory _tokenIds)
        public
        onlyOwner
    {
        require(
            !airdropPermanentlyDisabled,
            "Once the airdrop is disabled, the function can never be called again."
        );
        for (uint256 i = 0; i < _to.length; i++) {
            for (uint256 z = 0; z < _tokenIds[i].length; z++) {
                _safeMint(_to[i], _tokenIds[i][z]);
                distortionSupply.increment();
            }
        }
    }

    /**
    * @notice The mint function which will be permanently disabled once all tokens have been minted.
	*
    */
    function mint(address _to, uint256 _tokenId) public onlyOwner {
        require(!airdropPermanentlyDisabled, "Once the airdrop is disabled, the function can never be called again.");
        _safeMint(_to, _tokenId);
        distortionSupply.increment();
    }

    /*

    ░██████╗░███████╗███╗░░██╗███████╗██████╗░░█████╗░████████╗██╗██╗░░░██╗███████╗
    ██╔════╝░██╔════╝████╗░██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██║██║░░░██║██╔════╝
    ██║░░██╗░█████╗░░██╔██╗██║█████╗░░██████╔╝███████║░░░██║░░░██║╚██╗░██╔╝█████╗░░
    ██║░░╚██╗██╔══╝░░██║╚████║██╔══╝░░██╔══██╗██╔══██║░░░██║░░░██║░╚████╔╝░██╔══╝░░
    ╚██████╔╝███████╗██║░╚███║███████╗██║░░██║██║░░██║░░░██║░░░██║░░╚██╔╝░░███████╗
    ░╚═════╝░╚══════╝╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░╚═╝░░░╚══════╝
    Everything to do with the on-chain generation of the Distortion pieces.
    */

    string[] private colorNames = [
        "White",
        "Rose"        
    ];

    string[] private left = [
        "rgb(140,140,140)",
        "rgb(255, 26, 26)",
        "rgb(92, 214, 92)",
        "rgb(26, 140, 255)",
        "rgb(255, 215, 0)",
        "rgb(255, 128, 128)",
        "rgb(192, 50, 227)"
    ];

    string[] private right = [
        "rgb(52,52,52)",
        "rgb(230, 0, 0)",
        "rgb(51, 204, 51)",
        "rgb(0, 115, 230)",
        "rgb(204, 173, 0)",
        "rgb(255, 102, 102)",
        "rgb(167, 40, 199)"
    ];

    string[] private middleLeft = [
        "rgb(57,57,57)",
        "rgb(179, 0, 0)",
        "rgb(41, 163, 41)",
        "rgb(0, 89, 179)",
        "rgb(153, 130, 0)",
        "rgb(255, 77, 77)",
        "rgb(127, 32, 150)"
    ];

    string[] private middleRight = [
        "rgb(20,20,20)",
        "rgb(128, 0, 0)",
        "rgb(31, 122, 31)",
        "rgb(0, 64, 128)",
        "rgb(179, 152, 0)",
        "rgb(255, 51, 51)",
        "rgb(98, 19, 117)"
    ];

    string[] private frequencies = ["", "0", "00"];

    function generateString(
        string memory name,
        uint256 tokenId,
        string[] memory array
    ) internal pure returns (string memory) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(name, toString(tokenId)))
        ) % array.length;
        string memory output = string(
            abi.encodePacked(array[rand % array.length])
        );
        return output;
    }

    function generateColorNumber(string memory name, uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        uint256 output;
        uint256 rand = uint256(
            keccak256(abi.encodePacked(name, toString(tokenId)))
        ) % 100;

        if (keccak256(bytes(HASH_OF_BLOCK)) == keccak256(bytes(""))) {
            output = 0; //unrevealed
        } else {
            if (rand <= 15) {
                output = 1; //Red with 15% rarity.
            } else if (rand > 15 && rand <= 30) {
                output = 2; //Green with 15% rarity.
            } else if (rand > 30 && rand <= 45) {
                output = 3; //Blue with 15% rarity.
            } else if (rand > 45 && rand <= 75) {
                output = 0; //Black with 30% rarity.
            } else if (rand > 75 && rand <= 80) {
                output = 4; //Gold with 5% rarity.
            } else if (rand > 80 && rand <= 90) {
                output = 5; //Rose with 10% rarity.
            } else if (rand > 90) {
                output = 6; //Purple with 10% rarity.
            }
        }
        return output;
    }

    function generateNum(
        string memory name,
        uint256 tokenId,
        string memory genVar,
        uint256 low,
        uint256 high
    ) internal pure returns (string memory) {
        uint256 difference = high - low;
        uint256 randomnumber = (uint256(
            keccak256(abi.encodePacked(genVar, tokenId, name))
        ) % difference) + 1;
        randomnumber = randomnumber + low;
        return toString(randomnumber);
    }

    function generateNumUint(
        string memory name,
        uint256 tokenId,
        string memory genVar,
        uint256 low,
        uint256 high
    ) internal pure returns (uint256) {
        uint256 difference = high - low;
        uint256 randomnumber = (uint256(
            keccak256(abi.encodePacked(genVar, tokenId, name))
        ) % difference) + 1;
        randomnumber = randomnumber + low;
        return randomnumber;
    }

    function genDefs(uint256 tokenId) internal view returns (string memory) {
        string memory output;
        string memory xFrequency = generateString("xF", tokenId, frequencies);
        string memory yFrequency = generateString("yF", tokenId, frequencies);
        string memory scale = generateNum(
            "scale",
            tokenId,
            HASH_OF_BLOCK,
            10,
            40
        );

        if (keccak256(bytes(HASH_OF_BLOCK)) == keccak256(bytes(""))) {
            xFrequency = "";
            yFrequency = "";
            scale = "30";
        }

        output = string(
            abi.encodePacked(
                '<defs><filter id="squares" x="-30%" y="-30%" width="160%" height="160%"> <feTurbulence type="turbulence" baseFrequency="',
                "0.",
                xFrequency,
                "5 0.",
                yFrequency,
                "5",
                '" numOctaves="10" seed="" result="turbulence"> <animate attributeName="seed" dur="0.3s" repeatCount="indefinite" calcMode="discrete" values="1;2;3;4;5;6;7;8;9;1"/> </feTurbulence> <feDisplacementMap in="SourceGraphic" in2="turbulence" scale="',
                scale,
                '" xChannelSelector="R" yChannelSelector="G" /> </filter> </defs>'
            )
        );
        return output;
    }

    function genMiddle(uint256 tokenId) internal pure returns (string memory) {
        string memory translate = toString(
            divide(
                generateNumUint("scale", tokenId, HASH_OF_BLOCK, 10, 40),
                5,
                0
            )
        );
        
        string[5] memory p;

        if (keccak256(bytes(HASH_OF_BLOCK)) == keccak256(bytes(""))) {
            translate = "6";
        }

        p[
            0
        ] = '<style alt="surround"> #1 { stroke-dasharray: 50,50,150 } .cls-2 { fill: rgba(140,140,140, 1);}.cls-3 {fill: rgba(140,140,140, 0.3);}</style><g style="filter: url(#squares);" opacity="100%" id="1"> <g transform="translate(-';
        p[1] = translate;
        p[2] = ", -";
        p[3] = translate;
        p[4] = ')" >';

        return string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4]));
    }

    function genSquares(uint256 tokenId) internal view returns (string memory) {
        string memory output1;
        string memory output2;
        uint256 ringCount = generateNumUint(
            "ringCount",
            tokenId,
            HASH_OF_BLOCK,
            5,
            15
        );

        string[2] memory xywh;
        uint256 ringScaling = divide(25, ringCount, 0);

        if (keccak256(bytes(HASH_OF_BLOCK)) == keccak256(bytes(""))) {
            ringCount = 5;
            ringScaling = 5;
        }

        for (uint256 i = 0; i < ringCount; i++) {
            xywh[0] = toString(ringScaling * i + 5);
            xywh[1] = toString(100 - (ringScaling * i + 5) * 2);
            output1 = string(
                abi.encodePacked(
                    '<g style="animation: glitch 1.',
                    toString(i),
                    's infinite;"> <rect x="',
                    xywh[0],
                    '%" y="',
                    xywh[0],
                    '%" width="',
                    xywh[1],
                    '%" height="',
                    xywh[1],
                    '%" fill="none" stroke="',
                    left[generateColorNumber("color", tokenId)],
                    '" id="1" /> </g>'
                )
            );
            output2 = string(abi.encodePacked(output1, output2));
        }
        return output2;
    }

    function genEnd(uint256 tokenId) internal view returns (string memory) {
        uint256 colorNum = generateColorNumber("color", tokenId);
        string[4] memory p;
        p[0] = '</g> </g><g style="animation: glitch 0.5s infinite;filter: url(#squares);"> <g transform="scale(0.40) translate(750, 750)" style="opacity:40%"> <path fill="';
        p[1] = right[colorNum];
        p[2] = '" d="M500,0C223.86,0,0,223.86,0,500s223.86,500,500,500,500-223.86,500-500S776.14,0,500,0ZM878,500a376.44,376.44,0,0,1-82.55,235.81L560,500.34V126.71C740.27,155.46,878,311.64,878,500ZM440,873.29a375.83,375.83,0,0,1-147.13-57L440,669.15ZM560,670,706.59,816.63A375.73,375.73,0,0,1,560,873.29ZM440,126.71V499.45L204.13,735.32A376.48,376.48,0,0,1,122,500C122,311.64,259.73,155.46,440,126.71Z"/>';
        p[3] = "</g> </g> </svg>";        

        string memory output = string(abi.encodePacked(p[0], p[1], p[2], p[3]));
        return output;
    }

    /**
     * @notice Generate the SVG of any Distortion piece, including token IDs that are out of bounds.
     *
     */
    function generateDistortion(uint256 tokenId)
        public
        view
        returns (string memory)
    {        
        return string(
            abi.encodePacked(                                
                '<svg width="750px" height="750px" viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="background-color: ',
                colorNames[generateColorNumber("color", tokenId) % 2],
                ';"><style> @keyframes glitch { 0% {transform: translate(0px); opacity: 0.15;} 7% {transform: translate(2px); opacity: 0.65;} 45% {transform: translate(0px); opacity: 0.35;} 50% {transform: translate(-2px); opacity: 0.85;} 100% {transform: translate(0px); opacity: 0.25;} } </style> <defs> <filter id="background" x="-20%" y="-20%" width="140%" height="140%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="linearRGB"> <feTurbulence type="fractalNoise" baseFrequency="10" numOctaves="4" seed="1" stitchTiles="stitch" x="0%" y="0%" width="100%" height="100%" result="turbulence"> <animate attributeName="seed" dur="1s" repeatCount="indefinite" calcMode="discrete" values="1;2;3;4;5;6;7;8;9;10" /> </feTurbulence> <feSpecularLighting surfaceScale="10" specularExponent="10" lighting-color="#fff" width="100%" height="100%"> <animate attributeName="surfaceScale" dur="1s" repeatCount="indefinite" calcMode="discrete" values="10;11;12;13;14;15;14;13;12;11" /> <feDistantLight elevation="100"/> </feSpecularLighting> </filter> </defs> <g opacity="10%">',
                '<rect width="700" height="700" fill="hsl(23, 0%, 100%)" filter="url(#background)"></rect></g>',                
                genDefs(tokenId),
                genMiddle(tokenId),
                genSquares(tokenId),
                genEnd(tokenId)                
            )
        );
    }

    function getFrequency(uint256 tokenId) internal view returns (uint256) {
        uint256[2] memory xy;

        string memory y = generateString("yF", tokenId, frequencies);
        string memory x = generateString("xF", tokenId, frequencies);

        if (keccak256(bytes(x)) == keccak256(bytes("0"))) {
            xy[0] = 2;
        } else if (keccak256(bytes(x)) == keccak256(bytes("00"))) {
            xy[0] = 1;
        } else {
            xy[0] = 3;
        }

        if (keccak256(bytes(y)) == keccak256(bytes("0"))) {
            xy[1] = 2;
        } else if (keccak256(bytes(y)) == keccak256(bytes("00"))) {
            xy[1] = 1;
        } else {
            xy[1] = 3;
        }
        return xy[0] * xy[1];
    }

    /**
     * @notice
     *
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Token doesn't exist. Try using the generateDistortion function to generate non-existant pieces."
        );
        
        string memory ringCount = generateNum(
            "ringCount",
            tokenId,
            HASH_OF_BLOCK,
            5,
            15
        );
        
        string memory scale = generateNum(
            "scale",
            tokenId,
            HASH_OF_BLOCK,
            10,
            40
        );
        
        uint256 freq = getFrequency(tokenId);

        bytes memory _bytes = new bytes(1);
        _bytes[0] = bytes1(uint8(generateColorNumber("color", tokenId) + 48));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Peace No. ',
                        toString(tokenId),
                        '","attributes": [ { "trait_type": "Color", "value": "',
                        colorNames[generateColorNumber("color", tokenId) % 2],
                        '" }, { "trait_type": "Distortion Scale", "value": ',
                        scale,
                        ' }, { "trait_type": "Rings", "value": ',
                        ringCount,
                        ' }, { "trait_type": "Frequency Multiple", "value": ',
                        toString(freq),
                        " }]",
                        ', "description": "The Peace DAO Distortion on-chain NFT was awarded to the generous individuals who contributed to the Peace DAO JuiceBox Treasury (https://juicebox.money/#/p/peace). Your contributions had direct, life-changing impact on the fortunes of Ukrainians in need.  Join our Discord for up to date discussions and proposals on how the capital is deployed.  This NFT was developed in collaboration with @onchainworld as a fully on-chain art piece."',
                        ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(string(abi.encodePacked(generateDistortion(tokenId))))),
                        '"}'
                    )
                )
            )
        );
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function divide(
        uint256 a,
        uint256 b,
        uint256 precision
    ) internal pure returns (uint256) {
        return (a * (10**precision)) / b;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }
        return string(result);
    }
}