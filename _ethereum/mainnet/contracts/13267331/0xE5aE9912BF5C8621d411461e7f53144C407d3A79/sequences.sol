// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 /*
 * Sequences are on chain beats that can be used as a basis for music production.
 * This is v1 of the project and is built as a Tunes derivative. The Tune id seeds the sequence generation.
 * The visual element of sequences can be retrieved via the tokenURI metadata and contains an SVG of a step sequencer displaying the token's sequence.
 * Each sequence has 12 rows and 16 steps that are either active or inactive to indicate a sound should be played.
 * To make it easy to interpret the sequence into sounds there is a readSequence(id) function which returns a data url.
 * The data url encodes the sequence into UTF-8 text that can be parsed by players.
 * Use this key to interpret the sequence:
 *
 *   .  Do not play a sound.
 *   -  Play a sound.
 * 
 * Each row is ended by a new line character. Sample output from readSequence would be:
 *                             -.-.-.-.-.-.-.-.
 * This pattern alternates between playing a sound and silence each step.
 * Sequences are meant to be interpreted. Use your sequence to make music.
 * You are encouraged to experiment and prescribe the following to your sequence:
 * - Tempo
 * - Instruments (all rows could be different notes of the same instrument, a different instrument per row, etc.)
 * - Play columns instead of rows together?
 * - Which rows are on/off simultaneously
 *
 */
 
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Sequences is ERC721, Ownable{
    
    using Strings for uint256;
    
    IERC721Enumerable public tunes = IERC721Enumerable(0xfa932d5cBbDC8f6Ed6D96Cc6513153aFa9b7487C);

    constructor() ERC721("Sequences", "SEQ") Ownable() {
    }

    function mint(uint256[] calldata tokenIds) public {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            require(tokenId > 0 && tokenId <= tunes.totalSupply(), "You cannot mint outside of the IDs of Tunes.");
            require(tunes.ownerOf(tokenId) == msg.sender, "You must own the corresponding Tune to mint this.");
        }
        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _safeMint(msg.sender, tokenId);
        }
    }
    
    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        string memory sequenceSVG = drawSequence(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Sequence #', Strings.toString(tokenId), '", "description": "Sequences are randomly generated beat sequences stored and rendered on chain. Sequences are generated using Tunes as a seed. Interpret your sequence with the instruments of your choice, build players for your sequence, or remix with others.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(sequenceSVG)),'"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    ///////////////////
    //// GENERATOR ////
    ///////////////////

    uint256 constant MAX_SEQUENCES = 3;
    uint256 constant SEQUENCE_ROWS = 4; 
    uint256 constant STEPS_PER_BAR = 4;
    uint256 constant BARS_PER_SEQUENCE = 4;
    uint256 constant WIDTH = STEPS_PER_BAR * BARS_PER_SEQUENCE;
    uint256 constant HEIGHT = (SEQUENCE_ROWS * MAX_SEQUENCES);
    uint256 constant GRID_START_X = 74;
    uint256 constant GRID_START_Y = 494;
    bytes1 constant EMPTY = bytes1(0x2E); //empty
    
    bytes constant SVG_PREFIX = "data:text/plain;charset=utf-8,";


    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function doActivateBit(bytes32 b, uint pos) internal view returns (bool){
        return (  b & bytes32(1 << (pos+64)) ) != 0;
    }
    
    function getEuclideanRow(uint256 seed) internal view returns (bytes memory) {
        bytes memory output = new bytes(WIDTH);
        bytes1 entry = 0x2E;
        uint256 c = 0;
        uint256 pulses = 0;
        uint256 onsets = 0;
        
        uint256 offset = seed % STEPS_PER_BAR * 2;
        pulses = (seed % WIDTH) + 1;

        if(pulses < 2)
            pulses = 2;
        onsets = seed % (pulses / 2) + 1;
        onsets = 2 * (onsets / 4) + 1;
        int256 previous = -1;
                
        for (uint j = 0; j < WIDTH; j++) {
            entry = 0x2E;
            int256 current = int256(j * onsets / pulses);
            if( j >= offset && current != previous){
                entry = bytes1(0x2D);
                previous = current;
            }
            output[c] = entry;
            c++;
        }
        return output;
    }
    
    function getRow(uint256 row, uint256 id) internal view returns (bytes memory) {
        bytes memory output = new bytes(WIDTH);
        bytes1 entry = 0x2E;
        uint256 pos = 0;
        uint256 c = 0;
        
        uint256 rand = random(string(abi.encodePacked( Strings.toString(row),Strings.toString(id))));
        if(rand % 21 > 4){
            output = getEuclideanRow(rand);
            return output;
        }
        
        uint256 length = (rand % (STEPS_PER_BAR * BARS_PER_SEQUENCE / 2)) + 1;
        uint256 silence = (rand % STEPS_PER_BAR) + 1;
        
        bytes32 sequenceBytes = bytes32(rand);
        
        for (uint j = 0; j < WIDTH; j++) {
            entry = 0x2E;
            if(length > 0) {
                if( j % (length + silence) < length){
                    pos = j % (length + silence);
                    if(doActivateBit(sequenceBytes, pos)){
                        entry = bytes1(0x2D);
                    }
                }
            }

            output[c] = entry;
            c++;
        }
        return output;
    }
    
    function getStyleValue(bytes1 input) internal view returns (string memory) {
        if(input == EMPTY)
            return string("st1");
        else
            return string("st4");
    }
    
    function getSvgGridEntry(bytes1 input, uint256 xDrawPos, uint256 yDrawPos) internal view returns (string memory) {
        string memory gridString = string(abi.encodePacked('<rect x="',Strings.toString(xDrawPos),'" y="',Strings.toString(yDrawPos),'" class="', getStyleValue(input),'" width="100" height="100"/>'));
        return gridString;
    }
    
    function strConcat(string memory _a, string memory _b)
    internal pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }
    
    
    function drawSequence(uint256 id) public view returns (string memory) {
        string memory svgAccumulator = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 2048 2048" style="enable-background:new 0 0 2048 2048;" xml:space="preserve"><style type="text/css"> .st0{fill:#231F20;} .st1{fill:#414042;} .st2{fill:#3E92CC;} .st3{fill:#A3D17D;} .st4{fill:#E6E7E8;} .st5{fill:#F3743C;} .st6{fill:none;stroke:#414042;stroke-width:5;stroke-miterlimit:10;} .st7{fill:#EF4857;} .st8{fill:none;stroke:#E6E7E8;stroke-width:2;stroke-miterlimit:10;} .st9{fill:#F1F2F2;} .st10{font-family:monospace;} .st11{font-size:50px;} .st12{fill:none;stroke:#FFFFFF;stroke-width:4;} .st13{fill:#FFFFFF;}</style>';
        bytes memory output = new bytes(HEIGHT * (WIDTH + 3) + 30);
        svgAccumulator = strConcat(svgAccumulator, '<g> <rect x="0.27" y="0.32" class="st0" width="2048" height="2048"/></g><g><circle class="st2" cx="1204" cy="131.14" r="50"/><circle class="st3" cx="1444" cy="131.14" r="50"/><circle class="st4" cx="1684" cy="131.14" r="50"/><circle class="st5" cx="1924" cy="131.14" r="50"/><line class="st6" x1="1204" y1="131.14" x2="1204" y2="81.14"/><line class="st6" x1="1444" y1="131.14" x2="1487.29" y2="106.14"/><line class="st6" x1="1684" y1="131.14" x2="1727.26" y2="156.19"/><line class="st6" x1="1924" y1="131.14" x2="1890.38" y2="94.13"/><line class="st6" x1="1204" y1="253.99" x2="1204" y2="375.18"/><rect x="1154" y="253.99" class="st7" width="100" height="41.35"/><line class="st6" x1="1444" y1="253.99" x2="1444" y2="375.18"/><rect x="1394" y="274.66" class="st7" width="100" height="41.35"/><line class="st6" x1="1683.29" y1="253.99" x2="1683.29" y2="375.18"/><rect x="1633.29" y="290.35" class="st7" width="100" height="41.35"/><line class="st6" x1="1924" y1="253.99" x2="1924" y2="375.18"/><rect x="1874" y="260.17" class="st7" width="100" height="41.35"/><line class="st8" x1="74" y1="81.14" x2="774" y2="81.14"/><rect x="74" y="115.72" width="700" height="256.54"/><text transform="matrix(1 0 0 1 123.4748 191.0862)" class="st9 st10 st11">Sequence ');
        svgAccumulator = strConcat(svgAccumulator, Strings.toString(id));
        svgAccumulator = strConcat(svgAccumulator, '</text><g><path class="st12" d="M688.11,162.34h23.43c8.63,0,15.63,6.5,15.63,14.51l0,0c0,8.01-7,14.5-15.63,14.5h-46.88,c-8.63,0-15.63-6.5-15.63-14.5l0,0c0-8.01,7-14.51,15.63-14.51h3.9"/><path class="st13" d="M677.11,162.34l11-7.66V170L677.11,162.34z"/></g></g><g>');
        svgAccumulator = strConcat(svgAccumulator, '<defs><pattern id="Pattern" x="0" y="0" width="0.063125" height="0.0845"><rect x="0" y="0" width="100" height="100" class="st1"/></pattern></defs>');
        svgAccumulator =strConcat(svgAccumulator, '<rect fill="url(#Pattern)" x="74" y="494" width="1900" height="1420"/>');
        uint256 yDrawPos = GRID_START_Y;
        uint256 xDrawPos = GRID_START_X;
        string memory gridString = '';
        bytes1 gridValue = 0x00;

        uint256 c;
        for (c = 0; c < 30; c++) {
            output[c] = SVG_PREFIX[c];
        }
      
        for (uint256 i = 0; i < HEIGHT; i++) {
            yDrawPos = (i*120) + GRID_START_Y;
            bytes memory row = getRow(i, id);
            for (uint j = 0; j < WIDTH; j++) {
                output[c] = row[j];
                gridValue = row[j];
                if(gridValue != EMPTY){

                    xDrawPos = (j*120) + GRID_START_X;
                    gridString = getSvgGridEntry(gridValue, xDrawPos, yDrawPos);
                    svgAccumulator = strConcat(svgAccumulator, gridString);
                }
            }
            output[c] = bytes1(0x25); c++;
            output[c] = bytes1(0x30); c++;
            output[c] = bytes1(0x41); c++;
        }
    
        svgAccumulator = strConcat(svgAccumulator, '</g></svg>');
        return svgAccumulator;
    }
    
    function readSequence(uint256 id) public view returns (string memory) {
        bytes memory output = new bytes(HEIGHT * (WIDTH + 3) + 30);
        uint256 c;
        for (c = 0; c < 30; c++) {
            output[c] = SVG_PREFIX[c];
        }

        for (uint256 i = 0; i < HEIGHT; i++) {
            bytes memory row = getRow(i, id);
            for (uint j = 0; j < WIDTH; j++) {
                output[c] = row[j];
                c++;
            }
            output[c] = bytes1(0x25);
            c++;
            output[c] = bytes1(0x30);
            c++;
            output[c] = bytes1(0x41);
            c++;
        }
        string memory result = string(output);
        return result;
    }

}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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