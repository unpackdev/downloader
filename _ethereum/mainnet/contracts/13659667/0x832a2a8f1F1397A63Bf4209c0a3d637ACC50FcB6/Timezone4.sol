//SPDX-License-Identifier: Unlicense


/**

nascent-energy.eth
   ____
 /   0   \
|    |    |
|0   |   0|
|     \   |
|         |
 \___0___/


 */



pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Timezone4 is ERC721Enumerable, Ownable{
    
    struct Mintdata {
        uint mintdeploytimestamp;
        uint minteployblocknumber;
        string attribute1;
        uint8 [] colors;
    }
    
    mapping(uint => Mintdata) tokenidtomintdata;

    string private greeting;
    uint public deploytimestamp;
    uint public deployblocknumber;
    uint public counter;
    string svgheader = "<?xml version='1.0' encoding='UTF-8'?><svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='500' width='500' viewBox='0 0 500 500' >";
    string colordef1 = "<defs><radialGradient id='grad' cx='20%' cy='60%' r='80%' fx='50%' fy='54%'> <stop offset='0%' style='stop-color:rgb(";
    string colordef2 = ");stop-opacity:0' /> <stop offset='100%' style='stop-color:rgb(";
    string colordef3 = ");stop-opacity:1' />";
    string closingtag = '</svg>';
    string closingtaganimation = "</radialGradient></defs>";
    string animatelink = "<animate attributeName='";
    string close1to ="%' to='";
    string dur = "dur='";


    constructor()ERC721("Nascent - Timezone4 / Ethereum Edition", "TZ4") {
        deploytimestamp = block.timestamp;
        deployblocknumber = block.number;
        counter = 1;
    }

    function mint() public {
        require(counter < 32, "max number of tokens exist");
        uint8 [] memory colors = new uint8[](6);
        for(uint i = 0; i < 6;i++){
            colors[i]= randomnumber(i);
        }
        if (counter % 3 == 0){
            tokenidtomintdata[counter] = Mintdata(block.timestamp,
                                                  block.number,
                                                  "cx' ",
                                                  colors);
        }
        else if(counter % 3 == 1){
            tokenidtomintdata[counter] = Mintdata(block.timestamp,
                                                  block.number,
                                                  "cy' ",
                                                  colors);
        }
        else if(counter % 3 == 2){
            tokenidtomintdata[counter] = Mintdata(block.timestamp,
                                                  block.number,
                                                  "fx' ",
                                                  colors);

        }
        else if(counter % 3 == 3){
            tokenidtomintdata[counter] = Mintdata(block.timestamp,
                                                  block.number,
                                                  "fy' ",
                                                  colors);
        }
        _mint(msg.sender,counter);
        counter = counter + 1;
    }


    function randomnumber(uint index) internal view returns (uint8) {
        return uint8(blockhash(block.number - 1)[index]);
    }

    function timestamp() public view returns (uint) {
        return block.timestamp;
    }

    function gettimespan(uint256 tokenId) public view returns (uint){
        return timestamp() - tokenidtomintdata[tokenId].mintdeploytimestamp;
    }

    function getblockspan(uint256 tokenId) public view returns (uint){
        return blocknumber() - tokenidtomintdata[tokenId].minteployblocknumber;
    }

    function calculateavgblocktime(uint256 tokenId) public view returns(uint){
        uint safeblockspan = getblockspan(tokenId);
        uint safetime = gettimespan(tokenId);
        if(safetime == 0){
            safetime = 1;
        }
        if(safeblockspan == 0){
            safeblockspan = 1;
        }
        uint avgblocktime = safetime / safeblockspan ;
        return avgblocktime;
    }

    function blocknumber() public view returns (uint) {
        return block.number;
    }

    function generatename(uint256 tokenId) pure public returns (string memory){
        return string(abi.encodePacked("Clockzone ",Strings.toString(tokenId)));
    }


    function generategradientanimation(uint tokenId) internal view returns (string memory){
        return string(
            abi.encodePacked(
                string(
                    abi.encodePacked(
                        animatelink,
                        tokenidtomintdata[tokenId].attribute1,
                        dur    
                    )
                ),
                Strings.toString(calculateavgblocktime(tokenId)),
                "s' repeatCount='indefinite' values='",
                "10%; 70%; 10%;'/>",
                closingtaganimation
            )
        );
    }

    function generatestyle(uint256 tokenId) internal view returns (string memory){
        return string(
            abi.encodePacked(
                "<style> @keyframes scale {0%{transform:scale(1)} 50%{transform:scale(0.",
                Strings.toString(tokenidtomintdata[tokenId].colors[0] %8),
                ")} 100%{transform:scale(1)}} #spinner { transform-origin: center; animation: scale ",
                Strings.toString(calculateavgblocktime(tokenId)),
                "s infinite;}</style>"
            )
        );  
    }


    function generatecircle() internal pure returns (string memory){
        string memory animation1 =  "<circle id='spinner' fill='url(#grad";
        string memory animation10 = ")' cx='250' cy='250' r='200'>";
        return string(
            abi.encodePacked(
                animation1,
                animation10,
                "</circle>"
            )
        );
    }

    function generateattributes(uint256 tokenId) internal view returns (string memory){
        return string(
            abi.encodePacked(
                '[',
                '{"trait_type":"GenesisBlocknumber",',
                '"value":"',
                 Strings.toString(tokenidtomintdata[tokenId].minteployblocknumber),
                '"},',
                '{"trait_type":"UNIXTimestamp",',
                '"value":"',
                 Strings.toString(tokenidtomintdata[tokenId].mintdeploytimestamp),
                '"},',
                '{"trait_type":"MetaWaveform",',
                '"value":"',
                tokenidtomintdata[tokenId].attribute1,
                '"},',
                '{"trait_type":"BlockScale",',
                '"value":"',
                 Strings.toString(tokenidtomintdata[tokenId].colors[0] %8),
                '"}',
                ']'
            )
        );

    }

    function generatecolor(uint256 tokenId)internal view returns (string memory){
        return string(
            abi.encodePacked(
                colordef1,
                Strings.toString(tokenidtomintdata[tokenId].colors[0]),
                ",",
                Strings.toString(tokenidtomintdata[tokenId].colors[1]),
                ",",
                Strings.toString(tokenidtomintdata[tokenId].colors[2]),
                colordef2,
                Strings.toString(tokenidtomintdata[tokenId].colors[3]),
                ",",
                Strings.toString(tokenidtomintdata[tokenId].colors[4]),
                ",",
                Strings.toString(tokenidtomintdata[tokenId].colors[5]),
                colordef3
            )               
        );
    }

    function generatesvg(uint256 tokenId) public view returns (string memory){
        return string(
            abi.encodePacked(
                svgheader,
                generatestyle(tokenId),
                generatecolor(tokenId),
                generategradientanimation(tokenId),
                "<rect x='0' y='0' width='500' height='500' fill='rgb(235,235,235)'/>",
                "<circle fill='black' cx='250' cy='250' r='199'></circle>",
                "<circle id='spinner' fill='white' cx='250' cy='250' r='199'></circle>",
                generatecircle(),
                closingtag
            )               
        );
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory name = generatename(tokenId); 
        string memory description = "On-chain generative ERC721 tokens calculating the average Blocktime as parameters for rendering of svg animation.";
        string memory image = generatesvg(tokenId);
        string memory attributes = generateattributes(tokenId);
        return string(
            abi.encodePacked(
                'data:text/plain,'
                '{"name":"', 
                name,
                '", "description":"', 
                description,
                '", "image": "', 
                image,'",',
                '"attributes": ',
                attributes,
                '}'
            )               
        );
    }

}
