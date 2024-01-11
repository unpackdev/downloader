/*
 _   _ _  __ _      __          __   _ _
| \ | (_)/ _| |     \ \        / /  | | |
|  \| |_| |_| |_ _   \ \  /\  / /_ _| | |___
| . ` | |  _| __| | | \ \/  \/ / _` | | / __|
| |\  | | | | |_| |_| |\  /\  / (_| | | \__ \
|_| \_|_|_|  \__|\__, | \/  \/ \__,_|_|_|___/
          __/ |
         |___/

An NFT project by vrypan.eth.

*/
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Strings.sol";
import "./Ownable.sol";

contract Metadata is Ownable{
    using Strings for uint256;
    using Strings for uint8;

    string  public     baseURI = "https://arweave.net/zUr8QLeAV136LzRA7sNpR843-t-HF5HMLCA3BwGqnDk/";

    string[4] private     turmitesDict = ['LRR','LRL','LRRR','LRRL'];
    string[8] private     patternDict = ['Block','T-shape','C-shape','Stripes','Squares','Thorns','Inverse-L','O-shape'];
    string[68] private    color =      ['000000', '004b23', '007200', '38b000', '9ef01a', 'ffdd00', 'ffa200', 'ff8800',
                                        'ff7b00', '3c096c', '5a189a', '7b2cbf', '9d4edd', '48bfe3', '56cfe1', '64dfdf',
                                        '5aedc9', '9b2226', 'ae2012', 'bb3e03', 'ca6702', '582f0e', '7f4f24', '936639',
                                        'a68a64', 'b6ad90', '414833', 'bcbcbc', 'b1b1b1', '7d7d7d', '4d4d4d', 'ffc2d1',
                                        'ffb3c6', 'ff8fab', 'fb6f92', 'd62828', 'f77f00', 'fcbf49', 'eae2b7', '87bfff',
                                        '3f8efc', '2667ff', '3b28cc', 'ee9b00', 'ffffff', '780000', '660000', '520000',
                                        '3d0000', 'ffd700', '283035', '3b4c61', '569aaa', '6B8f6f', 'd7decd', 'fff963',
                                        '019d51', 'fb3195', '51b1cc', 'dab183', '573f77', '506a78', 'ad8b64', '703f21',
                                        '205947', 'ffd627', 'ff7626', '4e577e'];
    uint8[5][32] private colorDict = [
        [0, 1, 2, 3, 4],        [0, 5, 6, 7, 8],        [0, 9, 10, 11, 12],     [0, 13, 14, 15, 16],
        [0, 17, 18, 19, 20],    [0, 21, 22, 23, 24],    [0, 25, 26, 23, 22],    [0, 27, 28, 29, 30],
        [0, 31, 32, 33, 34],    [0, 35, 36, 37, 38],    [0, 39, 40, 41, 42],    [0, 43, 19, 18, 17],
        [44, 1, 2, 3, 4],       [44, 5, 6, 7, 8],       [44, 9, 10, 11, 12],    [44, 13, 14, 15, 16],
        [44, 17, 18, 19, 20],   [44, 21, 22, 23, 24],   [44, 25, 26, 23, 22],   [44, 27, 28, 29, 30],
        [44, 31, 32, 33, 34],   [44, 45, 46, 47, 48],   [44, 35, 36, 37, 38],   [44, 39, 40, 41, 42],
        [44, 43, 19, 18, 17],   [49, 9, 10, 11, 12],    [49, 21, 22, 23, 24],   [49, 39, 40, 41, 42],
        [50, 51, 52, 53, 54],   [0, 55, 56, 57, 58],    [59, 60, 61, 62, 63],   [0, 64, 65, 66, 67]
    ];
    
    struct Wall{
        uint8        turmite;
        uint8        pattern;
        string       background;
        string[4]    colors;
        uint8        fx;
        string       imageURL;
    }

    constructor() {}

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }
    
    function idToWall(uint _id) private view returns (Wall memory) {
        // Given any integer between 0 and 8191, there is a one way mapping to 
        // NiftyWall metadata.
        uint8 turmiteId = uint8(_id & 0x03);
        uint8 patternId = uint8( (_id >> 2)  & 0x07 );
        uint256 colorId = uint8( (_id >> 5)  & 0x1f );
        uint8 fxId      = uint8( (_id >> 10) & 0x07 );

        string memory background = color[colorDict[colorId][0]];
        string[4] memory colors = [
            color[colorDict[colorId][1]], color[colorDict[colorId][2]], color[colorDict[colorId][3]], color[colorDict[colorId][4]]
        ];

        if (patternId == 0) {
            // Block pattern has no empty space for background
            // We use -1 to indicate no value.
            background = '';
        }

        if (turmiteId <2) {
            // LRR and LRL only use 3 colors
            colors[3] = '';
        }

        if ( (turmiteId>1) && ( (fxId == 2) || (fxId == 6) ) ) {
            // LRRR and LRRL in FX3 and FX8 loose the 4th color.
            colors[3] = '';
        }

        return Wall(
            turmiteId,
            patternId,
            background,
            colors,
            fxId,
            ''
        );
    }
    function imageURI(uint _id) public view returns (string memory) {
        return( string( abi.encodePacked(baseURI, _id.toString(), '.png' )) );
    }
    function _traitToJson(string memory _type, string memory _value) private pure returns (string memory) {
        return( string(abi.encodePacked('{"trait_type":"', _type  ,'","value":"', _value, '"}')) );
    }
    function idToJson(uint _id) external view returns (string memory) {
        Wall memory w = idToWall(_id);        
        string memory turmite     = _traitToJson('Turmite', turmitesDict[w.turmite]);
        string memory pattern     = _traitToJson('Pattern', patternDict[w.pattern]);
        string memory fx          = _traitToJson('Effect', (w.fx+1).toString() );
        string memory background  = _traitToJson('background', bytes(w.background).length > 0 ? w.background : 'None');
        string memory colors;
        string memory image       = imageURI(_id);
        string memory id_to_str   = _id.toString();
        if (bytes(w.colors[3]).length > 0) {
            colors = string( abi.encodePacked(
                _traitToJson('color', w.colors[0]), ',',
                _traitToJson('color', w.colors[1]), ',',
                _traitToJson('color', w.colors[2]), ',',
                _traitToJson('color', w.colors[3])
            ));
        } else {
            colors = string( abi.encodePacked(
                _traitToJson('color', w.colors[0]), ',',
                _traitToJson('color', w.colors[1]), ',',
                _traitToJson('color', w.colors[2])
            ) );
        }
        string memory name = string(abi.encodePacked('NiftyWall #', id_to_str));
        string memory json = string(abi.encodePacked(
            '{"attributes":[', turmite, ',', pattern, ',', fx, ',', background, ',', colors, '],',
            '"description":"', 
                "Each NiftyWall is a unique, 3000x3000 algorithmically generated background. https://niftywalls.xyz/wall/",
                id_to_str,'",',
            '"image":"', image, '",',
            '"external_url":"https://niftywalls.xyz/wall/', id_to_str, '",',
            '"name":"', name ,'"}'
        ));
        return( json );
    }

    /* Only on testnets
    function shutdown() public onlyOwner {
        selfdestruct( payable(owner()) );
    }
    */
}