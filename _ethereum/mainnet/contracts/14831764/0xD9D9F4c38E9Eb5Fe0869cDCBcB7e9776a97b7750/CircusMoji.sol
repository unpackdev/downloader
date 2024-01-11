//SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import { Base64 } from "Base64.sol";

contract CircusMoji is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    string public collectionName;
    string public collectionSymbol;

uint256 public totalSupply = 0; //Number of minted token totally
uint256 public maxSupply = 1000; //Limit of mintable token

string baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 500 500'><style>.base { fill: white; font-family: monospace; font-size: 130px; } .adr { fill: white; font-family: monospace; font-size: 19px; }</style><rect width='100%' height='100%' fill='#0ABAB5' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

string[] zirkus = [
unicode"🎪",

unicode"🎡",

unicode"🤹🏻‍♂️",

unicode"🤡",

unicode"🤹",

unicode"🎢",

unicode"🍬",

unicode"🍿",

unicode"🎠",

unicode"🍭",

unicode"🃏"
];

string[] lachen = [
unicode"😁",

unicode"😂",

unicode"😅",

unicode"😄",

unicode"😅",

unicode"😎",

unicode"🤑",

unicode"🥳",

unicode"😀",

unicode"😃"
];

string[] animalen = [
unicode"🐪",

unicode"🦄",

unicode"🐝",

unicode"🐞",

unicode"🐡",

unicode"🐘",

unicode"🐊",

unicode"🦩",

unicode"🦒",

unicode"🐅",

unicode"🦁",

unicode"🦓"

];

    constructor() ERC721("CircusMoji", "CIRCUSMOJI") {
        collectionName = name();
        collectionSymbol = symbol();
    }

    function random(string memory _input) internal pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_input)));
    }
   
   function pickFirstWord(uint256 tokenId) public view returns(string memory) {
       uint256 rand = random(string(abi.encodePacked("zirkus", Strings.toString(tokenId))));
       rand = rand % zirkus.length;
       return zirkus[rand];
   }


   function pickSecondWord(uint256 tokenId) public view returns(string memory) {
       uint256 rand = random(string(abi.encodePacked("lachen", Strings.toString(tokenId))));
       rand = rand % lachen.length;
       return lachen[rand];
   }

   function pickThirdWord(uint256 tokenId) public view returns(string memory) {
       uint256 rand = random(string(abi.encodePacked("animalen", Strings.toString(tokenId))));
       rand = rand % animalen.length;
       return animalen[rand];
   }



    function createCircusMoji() public returns(uint256) {
        uint256 newItemId = _tokenId.current();


        string memory first = pickFirstWord(newItemId);
        string memory second = pickSecondWord(newItemId);
        string memory third = pickThirdWord(newItemId);
        string memory combinedWord = string(abi.encodePacked(first,second,third));

        string memory finalSvg = string(abi.encodePacked(baseSvg, first, second, third,"</text> <text  x='2%' y='90%' class='adr'>",Strings.toHexString(uint256(uint160(msg.sender)), 20),"</text> </svg>" ));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                    '{"name": "',
                        combinedWord,
                        '", "description": "A Circus in your wallet!", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                    '"}'
                    )
                )
            )
        );

        string memory finalTokenURI = string(abi.encodePacked(
            "data:application/json;base64,", json
        ));

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, finalTokenURI);

        _tokenId.increment();
        
        //when NFT is created, total supply increases
        totalSupply += 1;

        return newItemId;
    }
}