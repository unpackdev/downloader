// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract NFTProjectERC721{
  function balanceOf(address) external view returns (uint256) {}
}

contract CryptoPunkSC{
  mapping (address => uint256) public balanceOf;
}

contract pLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    // Private Variables
    uint256 public maxSupply = 7700;
    uint256 public devAllocation = 300;

    // NFT Allocation
    uint256 public maxPerAddress = 20;
    
    // Define Struct
    struct smartContractDetails { 
      address smartContractAddress;
      uint8 smartContractType; // 0  ERC-721, 1 CryptoPunks
    }

    //Smart Contract's Address mapping
    mapping(string => smartContractDetails) public smartContractAddresses;

    // Loot Packs
    string[] private lootPack1 = [
      "PEGZ",
      "Meebits",
      "Deafbeef",
      "CryptoPunks",
      "Autoglyphs",
      "Avid Lines",
      "Bored Ape Yacht Club",
      "BEEPLE - GENESIS COLLECTION",
      "Damien Hirst - The Currency"
    ];

    string[] private lootPack2 = [
      "Blitmap",
      "VeeFriends",
      "The Sevens",
      "PUNKS Comic",
      "MetaHero Universe",
      "Bored Ape Kennel Club",
      "Loot (for Adventurers)",
      "Mutant Ape Yacht Club",
      "The Mike Tyson NFT Collection"
    ];
    
    string[] private lootPack3 = [
      "0N1 Force",
      "CyberKongz",
      "The n Project",
      "Cryptovoxels",
      "Cool Cats NFT",
      "World of Women",
      "Pudgy Penguins",
      "Solvency by Ezra Miller",
      "Tom Sachs Rocket Factory"
    ];
    
    string[] private lootPack4 = [
      "Chiptos",
      "SupDucks",
      "Hashmasks",
      "FLUF World",
      "Lazy Lions",
      "Plasma Bears",
      "SpacePunksClub",
      "The Doge Pound",
      "Rumble Kong League"
    ];
    
    string[] private lootPack5 = [
      "GEVOLs",
      "Stoner Cats",
      "The CryptoDads",
      "BullsOnTheBlock",
      "Wicked Ape Bone Club",
      "BASTARD GAN PUNKS V2",
      "Bloot (not for Weaks)",
      "Lonely Alien Space Club",
      "Koala Intelligence Agency"
    ];
    
    string[] private lootPack6 = [
      "thedudes",
      "Super Yeti",
      "Spookies NFT",
      "Arabian Camels",
      "Untamed Elephants",
      "Rogue Society Bots",
      "Slumdoge Billionaires",
      "Crypto-Pills by Micha Klein",
      "Official MoonCats - Acclimated"
    ];
    
    string[] private lootPack7 = [
      "GOATz",
      "Sushiverse",
      "FusionApes",
      "CHIBI DINOS",
      "DystoPunks V2",
      "The Alien Boy",
      "LightSuperBunnies",
      "Creature World NFT",
      "SympathyForTheDevils"
    ];
    
    string[] private lootPack8 = [
      "Chubbies",
      "Animetas",
      "DeadHeads",
      "Incognito",
      "Party Penguins",
      "Krazy Koalas NFT",
      "Crazy Lizard Army",
      "Goons of Balatroon",
      "The Vogu Collective"
    ];

    // Constructor
    constructor() ERC721("pLoot (for NFT Collectors)", "pLoot") Ownable() 
    {
      initSmartContractMapping();
    }

    function initSmartContractMapping() private
    { 
      // Initialize smart contract Mapping
      smartContractAddresses["Bored Ape Yacht Club"] = smartContractDetails(address(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D),0);
      smartContractAddresses["Meebits"] = smartContractDetails(address(0x7Bd29408f11D2bFC23c34f18275bBf23bB716Bc7),0);
      smartContractAddresses["Deafbeef"] = smartContractDetails(address(0xd754937672300Ae6708a51229112dE4017810934),1);
      smartContractAddresses["CryptoPunks"] = smartContractDetails(address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB),0);
      smartContractAddresses["Autoglyphs"] = smartContractDetails(address(0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782),0);
      smartContractAddresses["Avid Lines"] = smartContractDetails(address(0xDFAcD840f462C27b0127FC76b63e7925bEd0F9D5),0);
      smartContractAddresses["PEGZ"] = smartContractDetails(address(0x1eFf5ed809C994eE2f500F076cEF22Ef3fd9c25D),0);
      smartContractAddresses["BEEPLE - GENESIS COLLECTION"] = smartContractDetails(address(0x12F28E2106CE8Fd8464885B80EA865e98b465149),0);
      smartContractAddresses["Damien Hirst - The Currency"] = smartContractDetails(address(0xaaDc2D4261199ce24A4B0a57370c4FCf43BB60aa),0);
      smartContractAddresses["Blitmap"] = smartContractDetails(address(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63),0);
      smartContractAddresses["VeeFriends"] = smartContractDetails(address(0xa3AEe8BcE55BEeA1951EF834b99f3Ac60d1ABeeB),0);
      smartContractAddresses["PUNKS Comic"] = smartContractDetails(address(0xd0A07a76746707f6D6d36D9d5897B14a8e9ED493),0);
      smartContractAddresses["Bored Ape Kennel Club"] = smartContractDetails(address(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623),0);
      smartContractAddresses["The Sevens"] = smartContractDetails(address(0xf497253C2bB7644ebb99e4d9ECC104aE7a79187A),0);
      smartContractAddresses["Loot (for Adventurers)"] = smartContractDetails(address(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7),0);
      smartContractAddresses["Mutant Ape Yacht Club"] = smartContractDetails(address(0x60E4d786628Fea6478F785A6d7e704777c86a7c6),0);
      smartContractAddresses["MetaHero Universe"] = smartContractDetails(address(0x6dc6001535e15b9def7b0f6A20a2111dFA9454E2),0);
      smartContractAddresses["The Mike Tyson NFT Collection"] = smartContractDetails(address(0x40fB1c0f6f73B9fc5a81574FF39d27e0Ba06b17b),0);
      smartContractAddresses["0N1 Force"] = smartContractDetails(address(0x3bf2922f4520a8BA0c2eFC3D2a1539678DaD5e9D),0);
      smartContractAddresses["CyberKongz"] = smartContractDetails(address(0x57a204AA1042f6E66DD7730813f4024114d74f37),0);
      smartContractAddresses["The n Project"] = smartContractDetails(address(0x05a46f1E545526FB803FF974C790aCeA34D1f2D6),0);
      smartContractAddresses["Cryptovoxels"] = smartContractDetails(address(0x79986aF15539de2db9A5086382daEdA917A9CF0C),0);
      smartContractAddresses["Cool Cats NFT"] = smartContractDetails(address(0x1A92f7381B9F03921564a437210bB9396471050C),0);
      smartContractAddresses["World of Women"] = smartContractDetails(address(0xe785E82358879F061BC3dcAC6f0444462D4b5330),0);
      smartContractAddresses["Pudgy Penguins"] = smartContractDetails(address(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8),0);
      smartContractAddresses["Solvency by Ezra Miller"] = smartContractDetails(address(0x82262bFba3E25816b4C720F1070A71C7c16A8fc4),0);
      smartContractAddresses["Tom Sachs Rocket Factory"] = smartContractDetails(address(0x11595fFB2D3612d810612e34Bc1C2E6D6de55d26),0);
      smartContractAddresses["Rumble Kong League"] = smartContractDetails(address(0xEf0182dc0574cd5874494a120750FD222FdB909a),0);
      smartContractAddresses["Chiptos"] = smartContractDetails(address(0xf3ae416615A4B7c0920CA32c2DfebF73d9D61514),0);
      smartContractAddresses["SupDucks"] = smartContractDetails(address(0x3Fe1a4c1481c8351E91B64D5c398b159dE07cbc5),0);
      smartContractAddresses["Hashmasks"] = smartContractDetails(address(0xC2C747E0F7004F9E8817Db2ca4997657a7746928),0);
      smartContractAddresses["SpacePunksClub"] = smartContractDetails(address(0x45DB714f24f5A313569c41683047f1d49e78Ba07),0);
      smartContractAddresses["The Doge Pound"] = smartContractDetails(address(0xF4ee95274741437636e748DdAc70818B4ED7d043),0);
      smartContractAddresses["Lazy Lions"] = smartContractDetails(address(0x8943C7bAC1914C9A7ABa750Bf2B6B09Fd21037E0),0);
      smartContractAddresses["Plasma Bears"] = smartContractDetails(address(0x909899c5dBb5002610Dd8543b6F638Be56e3B17E),0);
      smartContractAddresses["FLUF World"] = smartContractDetails(address(0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d),0);
      smartContractAddresses["GEVOLs"] = smartContractDetails(address(0x34b4Df75a17f8B3a6Eff6bBA477d39D701f5e92c),0);
      smartContractAddresses["Stoner Cats"] = smartContractDetails(address(0xD4d871419714B778eBec2E22C7c53572b573706e),0);
      smartContractAddresses["The CryptoDads"] = smartContractDetails(address(0xECDD2F733bD20E56865750eBcE33f17Da0bEE461),0);
      smartContractAddresses["BullsOnTheBlock"] = smartContractDetails(address(0x3a8778A58993bA4B941f85684D74750043A4bB5f),0);
      smartContractAddresses["Wicked Ape Bone Club"] = smartContractDetails(address(0xbe6e3669464E7dB1e1528212F0BfF5039461CB82),0);
      smartContractAddresses["BASTARD GAN PUNKS V2"] = smartContractDetails(address(0x31385d3520bCED94f77AaE104b406994D8F2168C),0);
      smartContractAddresses["Bloot (not for Weaks)"] = smartContractDetails(address(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613),0);
      smartContractAddresses["Lonely Alien Space Club"] = smartContractDetails(address(0x343f999eAACdFa1f201fb8e43ebb35c99D9aE0c1),0);
      smartContractAddresses["Koala Intelligence Agency"] = smartContractDetails(address(0x3f5FB35468e9834A43dcA1C160c69EaAE78b6360),0);
      smartContractAddresses["Super Yeti"] = smartContractDetails(address(0x3F0785095A660fEe131eEbcD5aa243e529C21786),0);
      smartContractAddresses["Spookies NFT"] = smartContractDetails(address(0x5e34dAcDa29837F2f220D3d1aEAAabD1eDCa5BD1),0);
      smartContractAddresses["Arabian Camels"] = smartContractDetails(address(0x3B3Bc9b1dD9F3C8716Fff083947b8769e2ff9781),0);
      smartContractAddresses["Untamed Elephants"] = smartContractDetails(address(0x613E5136a22206837D12eF7A85f7de2825De1334),0);
      smartContractAddresses["Rogue Society Bots"] = smartContractDetails(address(0xc6735852E181A55F736e9Db62831Dc63ef8C449a),0);
      smartContractAddresses["Slumdoge Billionaires"] = smartContractDetails(address(0x312d09D1160316A0946503391B3D1bcBC583181b),0);
      smartContractAddresses["Crypto-Pills by Micha Klein"] = smartContractDetails(address(0x7DD04448c6CD405345D03529Bff9749fd89F8F4F),0);
      smartContractAddresses["Official MoonCats - Acclimated"] = smartContractDetails(address(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69),0);
      smartContractAddresses["thedudes"] = smartContractDetails(address(0xB0cf7Da8dc482997525BE8488B9caD4F44315422),0);
      smartContractAddresses["Sushiverse"] = smartContractDetails(address(0x06aF447c72E18891FB65450f41134C00Cf7Ac28c),0);
      smartContractAddresses["FusionApes"] = smartContractDetails(address(0xEA6504BA9ec2352133e6A194bB35ad4B1a3b68e7),0);
      smartContractAddresses["CHIBI DINOS"] = smartContractDetails(address(0xe12EDaab53023c75473a5A011bdB729eE73545e8),0);
      smartContractAddresses["DystoPunks V2"] = smartContractDetails(address(0xbEA8123277142dE42571f1fAc045225a1D347977),0);
      smartContractAddresses["The Alien Boy"] = smartContractDetails(address(0x4581649aF66BCCAeE81eebaE3DDc0511FE4C5312),0);
      smartContractAddresses["LightSuperBunnies"] = smartContractDetails(address(0x3a3fBa79302144f06f49ffde69cE4b7F6ad4DD3d),0);
      smartContractAddresses["Creature World NFT"] = smartContractDetails(address(0xc92cedDfb8dd984A89fb494c376f9A48b999aAFc),0);
      smartContractAddresses["SympathyForTheDevils"] = smartContractDetails(address(0x36d02DcD463Dfd71E4a07d8Aa946742Da94e8D3a),0);
      smartContractAddresses["GOATz"] = smartContractDetails(address(0x3EAcf2D8ce91b35c048C6Ac6Ec36341aaE002FB9),0);
      smartContractAddresses["Chubbies"] = smartContractDetails(address(0x1DB61FC42a843baD4D91A2D788789ea4055B8613),0);
      smartContractAddresses["Animetas"] = smartContractDetails(address(0x18Df6C571F6fE9283B87f910E41dc5c8b77b7da5),0);
      smartContractAddresses["DeadHeads"] = smartContractDetails(address(0x6fC355D4e0EE44b292E50878F49798ff755A5bbC),0);
      smartContractAddresses["Party Penguins"] = smartContractDetails(address(0x31F3bba9b71cB1D5e96cD62F0bA3958C034b55E9),0);
      smartContractAddresses["Krazy Koalas NFT"] = smartContractDetails(address(0x8056aD118916db0fEef1c8B82744Fa37E5d57CC0),0);
      smartContractAddresses["Crazy Lizard Army"] = smartContractDetails(address(0x86f6Bf16F495AFc065DA4095Ac12ccD5e83a8c85),0);
      smartContractAddresses["Goons of Balatroon"] = smartContractDetails(address(0x8442DD3e5529063B43C69212d64D5ad67B726Ea6),0);
      smartContractAddresses["The Vogu Collective"] = smartContractDetails(address(0x18c7766A10df15Df8c971f6e8c1D2bbA7c7A410b),0);
      smartContractAddresses["Incognito"] = smartContractDetails(address(0x3F4a885ED8d9cDF10f3349357E3b243F3695b24A),0);
    }

    // Balance Check
    function checkHodler(uint256 tokenID, string memory projectName) public view returns (bool)
    {
      address hodlerAddress = ownerOf(tokenID);
      if (smartContractAddresses[projectName].smartContractType == 0)
      {
        NFTProjectERC721 projInstance = NFTProjectERC721(smartContractAddresses[projectName].smartContractAddress);
        if (projInstance.balanceOf(hodlerAddress) > 0)
        {
          return true;
        }
        else
        {
          return false;
        }
      }
      else if (smartContractAddresses[projectName].smartContractType == 1)
      {
        CryptoPunkSC projInstance = CryptoPunkSC(smartContractAddresses[projectName].smartContractAddress);
        if (projInstance.balanceOf(hodlerAddress) > 0)
        {
          return true;
        }
        else
        {
          return false;
        }
      }
      else
      {
        revert("Invalid Contract Details!");
      }
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getLoot1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack1", lootPack1);
    }
    
    function getLoot2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack2", lootPack2);
    }
    
    function getLoot3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack3", lootPack3);
    }
    
    function getLoot4(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack4", lootPack4);
    }

    function getLoot5(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack5", lootPack5);
    }
    
    function getLoot6(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack6", lootPack6);
    }
    
    function getLoot7(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack7", lootPack7);
    }
    
    function getLoot8(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack8", lootPack8);
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        
        bool diamondHands = true;
        
        string[2] memory spanStrings;
        
        spanStrings[0] = '</tspan><tspan x="40" dy="1.4em">';
        
        spanStrings[1] = '</tspan><tspan x="275" dy="1.4em">';

        string[36] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base{fill:white;font-family:ui-monospace;font-size:14px}</style><style>.black{fill:black;font-family:ui-monospace;font-size:14px}</style><g id="columnGroup"> <rect width="100%" height="100%" fill="black" /> <text y="60" font-size="15px" class="base"> <tspan x="23" dy="1em">';

        parts[1] = toAsciiString(ownerOf(tokenId));

        parts[2] = '</tspan></text><line x1="30" y1="90" x2="300" y2="90" stroke="white" class="base" stroke-width="1.5"/><text x="100" y="100" font-size="15px" class="base"><tspan x="40" dy="1.25em">';
        
        parts[3] = getLoot1(tokenId);

        parts[4] = spanStrings[0];

        parts[5] = getLoot2(tokenId);
      
        parts[6] = spanStrings[0];

        parts[7] = getLoot3(tokenId);
        
        parts[8] = spanStrings[0];

        parts[9] = getLoot4(tokenId);

        parts[10] = spanStrings[0];

        parts[11] = getLoot5(tokenId);

        parts[12] = spanStrings[0];

        parts[13] = getLoot6(tokenId);

        parts[14] = spanStrings[0];

        parts[15] = getLoot7(tokenId);

        parts[16] = spanStrings[0];

        parts[17] = getLoot8(tokenId);

        parts[18] = '</tspan></text><text x="100" y="100" font-size="15px" class="black"><tspan x="275" dy="1.25em">';

        if (checkHodler(tokenId, getLoot1(tokenId)))
        {
          parts[19] = unicode'✅';
        }
        else
        {
          parts[19] = 'X';
          diamondHands = false;
        }

        parts[20] = spanStrings[1];

        if (checkHodler(tokenId, getLoot2(tokenId)))
        {
          parts[21] = unicode'✅';
        }
        else
        {
          parts[21] = 'X';
          diamondHands = false;
        }

        parts[22] = spanStrings[1];

        if (checkHodler(tokenId, getLoot3(tokenId)))
        {
          parts[23] = unicode'✅';
        }
        else
        {
          parts[23] = 'X';
          diamondHands = false;
        }

        parts[24] = spanStrings[1];

        if (checkHodler(tokenId, getLoot4(tokenId)))
        {
          parts[25] = unicode'✅';
        }
        else
        {
          parts[25] = 'X';
          diamondHands = false;
        }

        parts[26] = spanStrings[1];

        if (checkHodler(tokenId, getLoot5(tokenId)))
        {
          parts[27] = unicode'✅';
        }
        else
        {
          parts[27] = 'X';
          diamondHands = false;
        }

        parts[28] = spanStrings[1];

        if (checkHodler(tokenId, getLoot6(tokenId)))
        {
          parts[29] = unicode'✅';
        }
        else
        {
          parts[29] = 'X';
          diamondHands = false;
        }

        parts[30] = spanStrings[1];

        if (checkHodler(tokenId, getLoot7(tokenId)))
        {
          parts[31] = unicode'✅';
        }
        else
        {
          parts[32] = 'X';
          diamondHands = false;
        }

        parts[33] = spanStrings[1];

        if (checkHodler(tokenId, getLoot8(tokenId)))
        {
          parts[34] = unicode'✅';
        }
        else
        {
          parts[34] = 'X';
          diamondHands = false;
        }
        
        if (diamondHands)
        {
            parts[35] = unicode'</tspan></text><text x="150" y="280" font-size="15px" class="black"> <tspan>💎🙌</tspan></text></g></svg>';
        }
        else 
        {
            parts[35] = '</tspan></text></g></svg>'; 
        }
        
        string memory output = string(abi.encodePacked(parts[0], '0x', parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23], parts[24]));
        output = string(abi.encodePacked(output, parts[25], parts[26], parts[27], parts[28], parts[29], parts[30], parts[31], parts[32]));
        output = string(abi.encodePacked(output, parts[33], parts[34], parts[35]));

        string memory json = Base64.encode(
                  bytes(string(
                    abi.encodePacked(
                      '{"name": "Loot Bag #', toString(tokenId), 
                      '", "description": "pLoot is a personalised & randomized adventurer gear for NFT collectors generated and stored on chain. Collect NFTs in the loot bag & refresh metadata to get green ticks. Collect all of the NFTs in the loot bag to get diamond hands!", "image": "data:image/svg+xml;base64,',
                      Base64.encode(bytes(output)),
                      '"}'))));
        
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    // Mint Function
    function claimFreeLootBag(uint256 qty) public {
        require((qty + balanceOf(msg.sender)) <= maxPerAddress, "You have reached your minting limit.");
        require((qty + totalSupply()) <= maxSupply, "Qty exceeds total supply.");
        // Mint the NFTs
        for (uint256 i = 0; i < qty; i++) 
        {
          uint256 mintIndex = totalSupply();
          _safeMint(msg.sender, mintIndex);
        }
    }

    // Pure Helper functions
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    // Admin Functions
    function modifySmartContractAddressMap(string memory projectName, address projAddress, uint8 projType) public onlyOwner {
      smartContractAddresses[projectName] = smartContractDetails(projAddress,projType);
    }

    function deleteSmartContractAddressMap(string memory projectName) public onlyOwner {
      delete smartContractAddresses[projectName];
    }

    function devCreateLootBag(uint256 qty) public onlyOwner {
        require(totalSupply() >= maxSupply, "Dev not allowed to mint!");
        require((totalSupply() + qty) <= (maxSupply + devAllocation), "Dev allocation exceeded!");
        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    // Withdraw function
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Receive ether function
    receive() external payable {} 
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