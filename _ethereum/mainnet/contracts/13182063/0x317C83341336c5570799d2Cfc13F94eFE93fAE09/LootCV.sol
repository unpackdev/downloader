// SPDX-License-Identifier: MIT

// .____                  __   _____________   ____
// |    |    ____   _____/  |_ \_   ___ \   \ /   /
// |    |   /  _ \ /  _ \   __\/    \  \/\   Y   / 
// |    |__(  <_> |  <_> )  |  \     \____\     /  
// |_______ \____/ \____/|__|   \______  / \___/   
//         \/                          \/          

pragma solidity ^0.8.0;

import "./base64.sol";
import "./StringUtil.sol";
import "./LootCVBase.sol";

contract LootCV is LootCVBase {
    uint256 public constant LOOTCV_COUNT = 8000;
    uint256 public constant OWNER_CLAIMABLE_COUNT = 100;

    constructor() LootCVBase("LootCV", "LCV") public { }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;

        Kingdom memory kingdom = pluckKingdom(tokenId);

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="';
        parts[1] = kingdom.color;
        parts[2] = '" /><text x="10" y="20" class="base">';
        parts[3] = kingdom.name;
        parts[4] = '</text><text x="10" y="40" class="base">';
        parts[5] = pluckUniversity(tokenId);
        parts[6] = '</text><text x="10" y="60" class="base">';
        parts[7] = pluckSociety(tokenId);
        parts[8] = '</text><text x="10" y="80" class="base">';
        parts[9] = pluckProfession(tokenId, 1);
        parts[10] = '</text><text x="10" y="100" class="base">';
        parts[11] = pluckProfession(tokenId, 2);
        parts[12] = '</text><text x="10" y="120" class="base">';
        parts[13] = pluckProfession(tokenId, 3);
        parts[14] = '</text><text x="10" y="140" class="base">';
        parts[15] = pluckHobby(tokenId);
        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "Course of Life #', StringUtil.toString(tokenId), '", "description": "Loot (Curriculum Vitae). Behind every Adventurer in the Loot Realm is a story.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))))));
    }
    
    function ownerClaim() public onlyOwner {
        // Tokens #7901 - #8000 reserved for project team
        for (uint256 i = 7901; i <= 8000; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function claim(uint256 numTokens) public {
        require(numTokens > 0 && numTokens <= 40, "invalid num");
        require(totalSupply() + numTokens <= 7900, "hit sale cap");
        for (uint i = 0; i < numTokens; i++) {
            uint256 nextTokenId = totalSupply() + 1;
            _safeMint(msg.sender, nextTokenId);
        }
    }

    function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
    }
}
