
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./base64.sol";
import "./StringUtil.sol";

interface BlootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract BlootIdentity is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public price = 10000000000000000; // 0.01 ETH

    uint256 public TOTAL_SIZE = 11000;
    uint256 public Bloot_SIZE = 10000;

    address public blootAddress = 0xd44b96c6b4778cc652D91F1E4f1933517354FEBB;
    BlootInterface public BlootContract = BlootInterface(blootAddress);

    string[] private firstNames = [
        "Axtor",
        "Sawcon",
        "Chokonma",
        "Gobolma",
        "Eizzen",
        "Grabma",
        "Gobolma",
        "Hythan",
        "Ivan",
        "Jeven",
        "Kisma",
        "Ligma",
        "Marvin",
        "Nathan",
        "Ozzam",
        "Perside",
        "Swallama",
        "Rhydon",
        "Sagandese",
        "Sigma",
        "Tavos",
        "Urim",
        "Vomiti",
        "Wahwahman",
        "Yabloo",
        "Zygan"
    ];
    string[] private lastNames = [
        "Notz",
        "Degenard",
        "Maidek",
        "Deesnotz",
        "Emaculum",
        "Faridane",
        "Ligma",
        "Heiztor",
        "Immithen",
        "Jarvethen",
        "Karmore",
        "Ligma",
        "Malion",
        "Napier",
        "Orgusis",
        "Proviz",
        "Jajasime",
        "Prelate",
        "Sugma",
        "Dik",
        "Umozo",
        "Vamanac",
        "Gapalago",
        "Yambalos",
        "Bawlz"
    ];


    string [] private clans = [
        "Twitter Heads Group",
        "Discord Insomniacs",
        "Diamond Hand Corp",
        "Companions Solar",
        "Antibloot Bloot Club",
        "Organic Veganism"
    ];

    string [] private operation = [
        "alpha", 
        "beta",
        "gamma",
        "delta",
        "epsilon"
    ];

    string [] private regions = [
        "U5 Territory",
        "Citadel",
        "Cannabis District",
        "Foundry Nueva",
        "San Dominigo",
        "Globgogabgalab",
        "New Morvidia",
        "Diamond City",
        "Cartan",
        "Cave Arena",
        "Red Light Garden"
    ];
    
    string [] private skillboost = [
        "Strength Boost",
        "Aiming Boost",
        "Stamina Boost",
        "Stealth Boost",
        "Driving Boost",
        "Swimming Boost",
        "All Skill Boost"
    ];

    string [] private specialItems = [
        "silver chain",
        "metaverse goggles",
        "ebook reader",
        "crypto wallet",
        "stylus",
        "coconut water"
    ];

    constructor() ERC721("BlootIdentity", "BI") Ownable() {

    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getFirstName(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIRSTNAME", firstNames);
    }

    function getLastName(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LASTNAME", lastNames);
    }

    function getClan(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CLAN", clans);
    }

    function getOperation(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OPERATION", operation);
    }

    function getRegion(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "REGION", regions);
    }

    function getSkillBoost(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SKILLBOOST", skillboost);
    }
     function getItem(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ITEM", specialItems);
    }

    //blooooot

    function ownerIsBlootHolder(uint256 tokenId) internal view returns (bool) {
        try BlootContract.tokenOfOwnerByIndex(ownerOf(tokenId), 0) returns (uint256 blootId) {
            return true;
        } catch Error (string memory reason) {
            return false;
        }
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, StringUtil.toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[15] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="';

        parts[1] = "#3aeb34";
        
        parts[2] = '" /><text x="10" y="20" class="base">';

        parts[3] = getFirstName(tokenId);

        parts[4] = '</text><text x="10" y="40" class="base">';

        parts[5] = getLastName(tokenId);

        parts[6] = '</text><text x="10" y="60" class="base">';

        parts[7] = getClan(tokenId);

        parts[8] = '</text><text x="10" y="80" class="base">';

        parts[9] = getRegion(tokenId);

        parts[10] = '</text><text x="10" y="100" class="base">';

        parts[11] = getSkillBoost(tokenId);

        parts[12] = '</text><text x="10" y="120" class="base">';

        parts[13] = getItem(tokenId);

        parts[14] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', StringUtil.toString(tokenId), '", "description": "Identity is a persona layer on top of Bloot0. Names, properties, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Identity in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 10000 && tokenId <= 11000, "Token ID invalid");
        require(price <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

    function multiMint(uint256[] memory tokenIds) public payable nonReentrant {
        require((price * tokenIds.length) <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 10000 && tokenIds[i] <= 11000, "Token ID invalid");
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function mintWithBloot(uint256 blootId) public payable nonReentrant {
        require(blootId > 0 && blootId <= 10000, "Token ID invalid");
        require(BlootContract.ownerOf(blootId) == msg.sender, "Not the owner of Bloot id");
        _safeMint(_msgSender(), blootId);
    }

    function multiMintWithBloot(uint256[] memory blootIds) public payable nonReentrant {
        for (uint256 i = 0; i < blootIds.length; i++) {
            require(BlootContract.ownerOf(blootIds[i]) == msg.sender, "Not owner of Bloot id");
            _safeMint(_msgSender(), blootIds[i]);
        }
    }
}
