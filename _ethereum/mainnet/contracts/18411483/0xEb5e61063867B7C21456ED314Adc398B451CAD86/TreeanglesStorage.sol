/*
SPDX-License-Identifier: MIT
Treeangles by nix.eth                                                                                                                                                                         
                                                                                                   
                                                                                                   
 :+********=.                                                             *@%-                     
 -***%@@#**+.                                                             *@@-                     
     *@@:   +#+-*%: .=#%%#=.   :*%%#+:   +#%%%*-   *#+-*%%*:   .+#%#++#+. *@@-  .=#%%#=.  .+#%%#-  
     *@@:   *@@@#+.-%@+.:#@#. *@%:.=@@=  --:-*@@+  %@@#=+@@@: -%@%=-*@@#. *@@- :%@*.:*@%. %@@-:-.  
     *@@:   +@@=  .#@@@%%@@@-:@@@%%@@@# .*%@#%@@#  %@@.  *@@= *@@-  :%@#  *@@- +@@@%%@@@= =%@@%*:  
     *@@:   +@@-   *@@+...:. :@@%-...:. #@@: -@@*  %@@.  *@@= +@@*:.+@@#  *@@- =@@*:..::  ...-@@@  
     *@@:   +@@-    =#@@@@@+  :*%@@@@#. -%@@%#@@#  %@@.  *@@=  -#%@##%@#  *@@-  =#@@@@@* .%@%%@#=  
      ..     ..        ....      ....     ..   .    ..    ..   .:...+@@+   ..      ....    ....    
                                                               *@@@@@#=                            
                    ..............                                                                 
                  .+%@%%%@%%@@%%@%#-.                                                              
            .=+**#@@@@@@@@@@@@@@@@@@%#*+=:                                                         
         .-#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+.                                                      
        +%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*:                                                    
      :*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=                                                   
      .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-                                                   
      =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.                                                  
    -*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=                                                 
   .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                                                 
   -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                                                 
    -*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=                                                 
     :*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*-.                                                 
        :=%@@%%@@@@@@@@@@@@@@@@@@@@@@@@%%@@@+:.                                                    
          ... :#@%+=*%%*#@@@@%#%@#==#@%=....                                                       
               .:.   .. :%@@@+ ..    :.                                            =@#             
                        :%@@@+                                                                     
                        =@@@@#.                                          @@*#@@##  #@@ -@@* :@@=   
                        +@@@@%:                                          @@%  %@%  #@@  *@%.#@%    
                       .*@@@@@-                                          @@#  #@@  #@@    @@@      
                       :#@@@@@+.                                         @@#  #@@  #@@  *@%.#@%    
                       :%@@@@@*.                                         @@#  #@@  #@@ -@@* :@@=   

*/
pragma solidity ^0.8.21;

import "./SSTORE2.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract TreeanglesStorage is Ownable {
    using Strings for uint8;
    using Strings for uint256;
    using Strings for uint24;

    string[] internal treeSizes = [
        'Majestic',
        'Grand',
        'Standard',
        'Modest',
        'Petite',
        'Dreamcape'
    ];
    string[] internal environments = [
        'Whispercloud',
        'Radiantbow',
        'Brightsolitude',
        'Iceshard',
        'Horizonhaven',
        'Dreamcape',
        'Sunscar',
        'Stormsong',
        'Celestial',
        'Daystar',
        'Starweaver'
    ];
    string[] internal landscapes = [
        'Wildmeadow',
        'Emeraldcourt',
        'Goldenstride',
        'Rubywhisper',
        'Obsidian',
        'Leafsong',
        'Liquidlight',
        'Perfectiongrass',
        'Frostvale'
    ];
    string[] internal trees = [
        'Sunspark',
        'Emberleaf',
        'Mossveil',
        'Sovereignshade',
        'Moonshade',
        'Valentine',
        'Dracofruit',
        'Regalroot',
        'Whisperbark',
        'Chromafrond',
        'Mysticveil',
        'Windwhisper'
    ];

    string private baseExternalURI = 'https://t.nix.art/';
    string private description = 'Truly onchain [More Details](';

    mapping(uint256 => address) internal pieces;

    constructor() Ownable(msg.sender){}

    function setPieceData(uint256 tokenId, bytes calldata _data) external onlyOwner {
        pieces[tokenId] = (SSTORE2.write(_data));
    }

    struct RawPiece { 
        uint256 tokenId;
        bytes data;
    }

    function setPiecesData(RawPiece[] calldata _pieces) external onlyOwner{
        for (uint i=0; i<_pieces.length; i++) {
            pieces[_pieces[i].tokenId] = (SSTORE2.write(_pieces[i].data));
        }
    }

    function setBaseExternalURI(string calldata uri) external onlyOwner{
        baseExternalURI = uri;
    }

    function setDescription(string calldata desc) external onlyOwner{
        description = desc;
    }

    function getPieceData(uint256 tokenId) external view returns (bytes memory) {
        return SSTORE2.read(pieces[tokenId]);
    }

    function getPiece(uint256 tokenId) external view returns (string memory, string memory) {
        bytes memory data = SSTORE2.read(pieces[tokenId]);

        string memory svg = string(getSVGFromData(data));

        string memory metadata = string(abi.encodePacked(
            getMetadataStartFromData(tokenId, data),
            '}'
        ));

        return (metadata, svg);
    }

    function getMetadataStartFromData(uint256 tokenId, bytes memory _data) internal view returns (string memory) {
        string memory tokenIdString = tokenId.toString();
        bytes memory externalURI = abi.encodePacked(baseExternalURI, tokenIdString);
        bytes memory attributes = abi.encodePacked(
            '"attributes": [',
                '{"trait_type": "Environment", "value": "',
                    environments[uint8(_data[0]) - 1],
                '"},{"trait_type": "Landscape", "value": "',
                    landscapes[uint8(_data[1]) - 1],
                '"},{"trait_type": "Tree", "value": "',
                    trees[uint8(_data[2]) - 1],
                '"},{"trait_type": "Tree Size", "value": "',
                    treeSizes[uint8(_data[3]) - 1],
                '"},{"trait_type": "Complexity", "value": "',
                    uint8(_data[4]).toString(),
            '"}]'
        );
        return string(abi.encodePacked(
            '{',
                '"name": "Treeangles #',tokenIdString,'",',
                '"description": "',description,externalURI,')",',
                '"external_url": "',externalURI,'",',
                attributes
        ));
    }

    function getSVGFromData(bytes memory _data) internal pure returns (bytes memory) {
        bytes3 mask3 = bytes3(0xfF0000);
        bytes12 mask12 = bytes12(0xfF0000000000000000000000);

        uint polygonCount = (_data.length - 5) / 12;
        bytes memory template = new bytes(98 * polygonCount);
        bytes memory template2 = new bytes(81 * polygonCount);
        uint cursor = 0;
        uint cursor2 = 0;
        for (uint i=0; i < polygonCount; i++) {
            uint dataOffset = (i * 12) + 5;
            bytes12 polyData;
            polyData^=(_data[dataOffset]);
            polyData^=(mask12&_data[dataOffset+1])>>(8);
            polyData^=(mask12&_data[dataOffset+2])>>(16);
            polyData^=(mask12&_data[dataOffset+3])>>(24);
            polyData^=(mask12&_data[dataOffset+4])>>(32);
            polyData^=(mask12&_data[dataOffset+5])>>(40);
            polyData^=(mask12&_data[dataOffset+6])>>(48);
            polyData^=(mask12&_data[dataOffset+7])>>(56);
            polyData^=(mask12&_data[dataOffset+8])>>(64);
            polyData^=(mask12&_data[dataOffset+9])>>(72);
            polyData^=(mask12&_data[dataOffset+10])>>(80);
            polyData^=(mask12&_data[dataOffset+11])>>(88);
            bytes3 result1;
            bytes3 result2;
            bytes3 result3;
            result1^=(polyData[0]);
            result1^=(mask3&polyData[1])>>(8);
            result1^=(mask3&polyData[2])>>(16);
            result2^=(polyData[3]);
            result2^=(mask3&polyData[4])>>(8);
            result2^=(mask3&polyData[5])>>(16);
            result3^=(polyData[6]);
            result3^=(mask3&polyData[7])>>(8);
            result3^=(mask3&polyData[8])>>(16);
            bytes memory points = abi.encodePacked(
                uint24(result1 >> 12).toString(), ',', (uint24(result1) % 2 ** 12).toString(), ' ',
                uint24(result2 >> 12).toString(), ',', (uint24(result2) % 2 ** 12).toString(), ' ',
                uint24(result3 >> 12).toString(), ',', (uint24(result3) % 2 ** 12).toString(), ' '
            );
            bytes memory color = abi.encodePacked(uint8(polyData[9]).toString(), ',', uint8(polyData[10]).toString(), ',', uint8(polyData[11]).toString());
            bytes memory polygon = abi.encodePacked(
                '<polygon points="',
                points,
                '" style="stroke:rgb(',
                color,
                ');stroke-width:4"/>                               '
            );
            bytes memory polygon2 = abi.encodePacked(
                '<polygon points="',
                points,
                '" style="fill:rgb(',
                color,
                ')"/>                               '
            );
            for (uint k=0; k < 98; k++) {
                template[cursor++] = polygon[k];
            }
            for (uint k=0; k < 81; k++) {
                template2[cursor2++] = polygon2[k];
            }
        }

        return abi.encodePacked('<svg viewBox="0 0 1100 1100" xmlns="http://www.w3.org/2000/svg">', template, template2, '</svg>');
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        bytes memory data = SSTORE2.read(pieces[tokenId]);

        string memory svg = Base64.encode(getSVGFromData(data));

        string memory uri = Base64.encode(abi.encodePacked(
            getMetadataStartFromData(tokenId, data),
            ',"image": "', abi.encodePacked(
                "data:image/svg+xml;base64,",
                svg
            ), '"}'
        ));

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                uri
            )
        );
    }
}