/*

 .
  / \
  | |
  |.|
  |.|
  |.|
  |:|      __
,_|:|_,   /  )
  (Oo    / _I_
   +\ \  || X_X|
      \ \||___|
        \ /.:.\-\
         |.:. /-----\
         |___|::oOo::|        NFT Tales
         /   |:<_T_>:|          5555 
        |_____\ NFT /
         | |  \ \:/
         | |   | |
         \ /   | \___
         / |   \_____\
         `-'

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";
import "./Counters.sol";


contract NFTTales is ERC721, ReentrancyGuard, Ownable {

        uint internal _totalSupply = 0;

        using Counters for Counters.Counter;
        Counters.Counter private _tokenIds;

        string[] private attribute = [
        "an arrogant",
		"a shy",
		"a lonely",
		"a brave",
		"a lazy",
		"a cowardly",
		"a lonely",
		"an adventures",
		"a friendly",
		"a magic",
		"a mighty"
    ];
    
    string[] private nft = [
        "CyberPunk",
		"Meebit",
		"CryptoCat",
		"Loot",
		"Hashmask",
		"Pudgy Penguin",
		"Bored Ape",
		"Mutant Ape",
		"Cool Cat",
		"Veefriend",
		"Gutter Cat",
		"CyberKong",
		"Metaverse Hero",
		"CryptoKoala",
		"Mooncat",
		"Wicked Cranium",
		"Supduck",
		"Bastard Gan Punk",
		"CryptoKittie",
		"Voxie",
		"Party Penguin",
		"Alien Boy",
		"Crypto Pill",
		"Degenz",
		"Boring Banana",
		"Fucking Pickle"
    ];
    
    string[] private task = [
		"save a princess",
		"shill NFTs",
		"burn some tokens",
		"deploy a contract",
		"increase the transaction fee",
		"win a giveaway",
		"cancel a transaction",
		"speed up a transaction",
		"leave home",
		"defeat a giant",
		"attend a dance",
		"evade an unwanted lover",
		"slay a monster",
		"defeat a tyrant",
		"outwit a faerie",
		"break a curse",
		"solve a mystery",
		"overcome three challenges",
		"solve three riddles "
    ];
    
    string[] private goal = [
		" to win the hand of a love interest - a ",
		" to marry his best friend - a ",
		" to escape an abusive ", 
		" to save the kingdom of a mighty ", 
		" to find the magic ",
		" to solve a mystery about a ",
		" to sweep the floor on OpenSea by buying a ",
		" to donate the token of a "
    ];
    
    string[] private complications = [
		"the gas fees are ridiculus high.",
		"the villain was kidnapping the main character's wallet.",
		"the villain was stealing the secret phrase.",
		"the main villain was trying to burn the main character.",
		"OpenSea is down again.",
		"Etherscan is down again.",
		"Vitalik announced the release date of Ethereum 2.0.",
		"the Metaverse became real."
    ];
    
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getAttribute(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "Attribute", attribute);
    }
    

    function getNft(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "NFT", nft);
    }
	
	function getHelpNft(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "HelpNFT", nft);
    }
	
	function getGoalNft(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "GoalNFT", nft);
    }
		
	function getHelpAttribute(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "HelpAttribute", attribute);
    }
    
    function getTask1(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "Task1", task);
    }
	
	function getTask2(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "Task2", task);
    }
	
	function getTask3(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "Task3", task);
    }
    
    function getGoal(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "Goal", goal);
    }

    function getComplications(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "Complications", complications);
    }
    

    
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
    
    
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><rect width="100%" height="100%" fill="#FFBE61" /><style>.base { fill: #ffffff; font-family: papyrus; font-weight: bold; font-size: 12px; }</style><text x="14" y="65" class="base" style="font-size: 36px;">&#127800; NFT Tales &#127800;</text> <text x="145" y="105" class="base">N&#333; ';

        parts[1] = '</text><foreignObject width="300" height="250"  x="25" y="120" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility"><p xmlns="http://www.w3.org/1999/xhtml" style="fill: #ffffff; font-family: papyrus; font-weight: bold; font-size: 12px; ">Once upon a time, there was ';

        parts[2] = '. ... And they all lived happily on the Ethereum Blockchain until they were burned.</p></foreignObject><text x="270" y="320" class="base">The end.</text></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], toString(tokenId), parts[1], getAttribute(tokenId), ' ', getNft(tokenId), ' who must ', getTask1(tokenId), ', ', getTask2(tokenId)));
		output = string(abi.encodePacked(output, ', and ', getTask3(tokenId), getGoal(tokenId), getGoalNft(tokenId), '. Complications arose when it was discovered that ', getComplications(tokenId), ' Assistance came in the form of ', getHelpAttribute(tokenId)));
		output = string(abi.encodePacked(output, ' ', getHelpNft(tokenId),  parts[2]));
        
        string memory json = string(abi.encodePacked('{"name": "NFTTale #', toString(tokenId), '", "description": "NFTTales - fully stored and generated Tales about NFTs fully on Chain! Own a tale!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '",'));
        string memory json_attr =  Base64.encode(bytes(string(abi.encodePacked(json, '"attributes":[{"trait_type": "NFT", "value": "',getNft(tokenId), '"},{"trait_type": "HelpNFT", "value": "', getHelpNft(tokenId), '"},{"trait_type": "GoalNFT", "value": "' ,getGoalNft(tokenId)  , '"},{"trait_type": "Goal", "value": "', getGoal(tokenId), '"},{"trait_type": "Attribute", "value": "', getAttribute(tokenId) , '"},{"trait_type": "Complications", "value": "' , getComplications(tokenId) , '"}]}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json_attr));

        return output;
    }

    function claim() public nonReentrant {
        require(totalSupply() + 1 <= 5555, "MaxSupply");
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);
        _totalSupply++;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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


    // Get total Supply
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    } 

    // Check if token exists
    function existsPubl(uint _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    } 
    
    constructor() ERC721("NFTTales", "Tales") Ownable() {}
}

