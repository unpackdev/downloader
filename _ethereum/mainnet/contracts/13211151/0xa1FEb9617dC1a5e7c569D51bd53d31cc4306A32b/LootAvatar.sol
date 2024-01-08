// contracts/RandomLoot.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LootAvatar is ERC721Enumerable, Ownable {

    struct LootItem{
        string text ;
        string lev ;
    }

    uint internal constant MAX_TOKEN_PURCHASE = 10 ;
    uint internal constant maxTokenSupply = 8000 ;
    uint internal constant TOKEN_PRICE = 0.05 ether ;
    uint internal constant tokenReserved = 220 ;

    string[] private weapons = ["Cleaver", "Sword", "Axe", "Staff", "Hammer", "Bow"];
    string[] private chestArmor = ["Tunic", "Guard Armor", "Robe", "Cloak", "Jerkin", "Santa's coat"];
    string[] private headArmor = ["Headband", "Wizard Hat", "Santa's Hat", "Pirate hat", "Warrior's Brain-cage"];
    string[] private footArmor = ["Buskin", "Leggings", "Anklets", "Clog", "Santa's boots"];
    string[] private necklaces = ["Cross", "Gold Chain", "Ruby", "Diamond", "Amulet"];
    string[] private facial = ["Repulsive in appearance", "So coooool!!", "I'm an avatar", "One-eyed"];
    string[] private namePrefixes = ["Sage's", "Archmage's", "Indomitable", "Despot's", "Stormcaller's", "Evoker's", "Honor Guard's", "Beastcaller's"];
    string[] private nameSuffixes = ["Arctic", "Crackling", "Blazing", "Piercing", "Radiant", "Keen", "Durable", "Stately"];
    string[] private suffixes = ["of the Demigod", "of Shelter", "of Erudition", "of Immortality", "of Retribution", "of Nightmares", "of Corrosion", "of Vengeance"];

    constructor() ERC721("Loot Avatar", "LOOTA") {}
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getWeapon(uint256 tokenId) public view returns (string memory str, string memory lev) {
        (str, lev) =  pluck(tokenId, "weapons", weapons , true);
    }
    
    function getChestArmor(uint256 tokenId) public view returns (string memory str, string memory lev) {
        (str, lev) =  pluck(tokenId, "chestArmor", chestArmor, true);
    }
    
    function getHeadArmor(uint256 tokenId) public view returns (string memory str, string memory lev) {
        (str, lev) =  pluck(tokenId, "headArmor", headArmor, true);
    }

    function getFootArmor(uint256 tokenId) public view returns (string memory str, string memory lev) {
        (str, lev) =  pluck(tokenId, "footArmor", footArmor, true);
    }
    
    function getNecklaces(uint256 tokenId) public view returns (string memory str, string memory lev) {
        (str, lev) =  pluck(tokenId, "necklaces", necklaces, true);
    }

    function getFacial(uint256 tokenId) public view returns (string memory str, string memory lev) {
        (str, lev) =  pluck(tokenId, "facial", facial, false);
    }

    function itemToText(LootItem memory item , string memory _y) internal pure returns (string memory str) {
        string[6] memory parts;
        parts[0] = item.lev ;
        parts[1] = '">' ;
        parts[2] = item.text;
        parts[3] = '</text><text x="10" y="' ;
        parts[4] = _y ;
        parts[5] = '" class="bs ' ;
        str = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3],parts[4],parts[5]));

    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray , bool lv) internal view returns (string memory output , string memory lev) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, Strings.toString(tokenId))));
        output = sourceArray[rand % sourceArray.length];
        if ( lv ) {
            uint256 greatness = rand % 21;
            lev = "" ;
            if (greatness > 5 ) { // > 5
                lev = "lv2" ;
                string[2] memory name;
                name[0] = namePrefixes[rand % namePrefixes.length];
                name[1] = nameSuffixes[rand % nameSuffixes.length];
                output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
                if (greatness >= 11 &&  greatness <= 14 ) { // lv3
                    lev = "lv3" ;
                    output = string(abi.encodePacked('', name[0], ' ', output));
                }
                else if (greatness >= 15 &&  greatness <= 17) { // lv4
                    lev = "lv4" ;
                    output = string(abi.encodePacked('', name[1], ' ', output));
                }
                else if (greatness >= 18 &&  greatness <= 19) { // lv5
                    lev = "lv5" ;
                    output = string(abi.encodePacked('', name[0], ' ', name[1], ' ', output));
                }
                else if (greatness == 20) { // lv6
                    lev = "lv6" ;
                    output = string(abi.encodePacked('', name[0], ' ', name[1], ' ', output, " +1"));
                }
            }
        }
    }

    function itemToAttributes(string memory _type , string memory _input ) internal pure returns (string memory str) {
        str = string(abi.encodePacked('{ "trait_type": "',_type,'", "value": "',_input,'"}'))  ;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[10] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.bs { fill: white; font-family: serif; font-size: 14px; } .lv2 {fill: #00DC82} .lv3 {fill: #2e82ff} .lv4 {fill: #c13cff} .lv5 {fill: #f8b73e} .lv6 {fill: #ff44b7}</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="bs ';

        LootItem memory item;
        ( item.text , item.lev) = getWeapon(tokenId);
        string memory attributes = itemToAttributes("weapon" , item.text );

        parts[1] = itemToText(item , "40") ;
        ( item.text , item.lev) = getChestArmor(tokenId);
        attributes = string(abi.encodePacked(attributes, ",", itemToAttributes("chestArmor" , item.text )));
        parts[2] = itemToText(item, "60") ;
        ( item.text , item.lev) = getHeadArmor(tokenId);
        attributes = string(abi.encodePacked(attributes,",", itemToAttributes("headArmor" , item.text )));
        parts[3] = itemToText(item, "80") ;
        ( item.text , item.lev) = getFootArmor(tokenId);
        attributes = string(abi.encodePacked(attributes, ",",itemToAttributes("footArmor" , item.text )));
        parts[4] = itemToText(item, "100") ;
        ( item.text , item.lev) = getNecklaces(tokenId);
        attributes = string(abi.encodePacked(attributes,",", itemToAttributes("necklaces" , item.text )));
        parts[5] = itemToText(item, "120") ;
        ( item.text , item.lev) = getFacial(tokenId);
        attributes = string(abi.encodePacked(attributes,",", itemToAttributes("facial" , item.text )));
        parts[6] = item.lev ;
        parts[7] = '">' ;
        parts[8] = item.text;
        parts[9] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Avatar #', Strings.toString(tokenId), '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '","attributes":[',attributes,']}'))));

        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    
    function mintTokens(uint numberOfTokens) public payable {

        require(numberOfTokens <= MAX_TOKEN_PURCHASE, "EX_M_TX");
        require((totalSupply() + numberOfTokens) <= (maxTokenSupply-tokenReserved), "EX_M_SUP");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "N_E_EVALUE");
        uint i;
        uint supply = totalSupply();
        for(i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function ownerClaim(uint256 tokenId) public onlyOwner {
        require(tokenId > (maxTokenSupply-tokenReserved)  && tokenId <= maxTokenSupply);
        _safeMint(msg.sender, tokenId);
    }
    
    function withdrawFunds() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}

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