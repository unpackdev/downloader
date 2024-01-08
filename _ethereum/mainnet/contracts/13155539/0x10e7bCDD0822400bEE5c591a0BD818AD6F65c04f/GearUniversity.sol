
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./base64.sol";
import "./StringUtil.sol";

interface GearInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract GearUniversity is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public price = 10000000000000000; // 0.01 ETH
    uint256 public GEAR_UNIVERSITY_CLASS_SIZE = 12000;

    address public gearAddress = 0xFf796cbbe32B2150A4585a3791CADb213D0F35A3;
    GearInterface public gearContract = GearInterface(gearAddress);

    string[] private societies = [
        "Alpha",
        "Delta",
        "Kappa",
        "Lambda",
        "Zeta" 
    ];

    string [] private classes = [
        "Frosh",
        "Soph",
        "Junior",
        "Senior",
        "Masters",
        "PhD"
    ];

    string [] private grades = [
        "A",
        "B",
        "C",
        "P",
        "NP"
    ];

    string [] private majors = [
        "Underwater Basket Weaving",
        "Intergalactic Relations",
        "Cannabis Cultivation",
        "Puppetry",
        "Canadian Studies",
        "Canine Astrology",
        "Snake Oil Sales",
        "Roller Coaster Engineering",
        "Dinosaur Genetics",
        "DOGE Hodling"
    ];
    
    string [] private interests = [
        "Rollerball",
        "Robot Boxing",
        "Podracing",
        "Chicken Fighting",
        "Samurai Sword Collecting",
        "Vampire Hunting",
        "Rock Throwing",
        "Time Hopping",
        "Space Diving"
    ];

    string [] private accessories = [
        "Backpack",
        "Tote Bag",
        "Laptop",
        "Beer Can",
        "Headphones",
        "Journal"
    ];

    mapping (string => string) societyBackgrounds;

    constructor() ERC721("GearUniversity", "GU") Ownable() {
        societyBackgrounds["Alpha"] = "#930101";
        societyBackgrounds["Delta"] = "#128100";
        societyBackgrounds["Kappa"] = "#000D81";
        societyBackgrounds["Lambda"] = "#5100A1";
        societyBackgrounds["Zeta"] = "#D15007";
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getSociety(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SOCIETY", societies);
    }

    function getMajor(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MAJOR", majors);
    }

    function getGrade(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GRADE", grades);
    }

    function getClass(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CLASS", classes);
    }

    function getInterest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "INTEREST", interests);
    }

    function getAccessory(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ACCESSORY", accessories);
    }

    function getSwagger(uint256 tokenId) public view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("SWAGGER", StringUtil.toString(tokenId))));
        if (ownerIsGearHolder(tokenId)) {
            return rand % 100;
        }
        return rand % 80;
    }

    function ownerIsGearHolder(uint256 tokenId) internal view returns (bool) {
        try gearContract.tokenOfOwnerByIndex(ownerOf(tokenId), 0) returns (uint256 gearId) {
            return true;
        } catch Error (string memory reason) {
            return false;
        }
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, StringUtil.toString(tokenId))));
        return sourceArray[rand % sourceArray.length];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="';

        parts[1] = societyBackgrounds[getSociety(tokenId)];
        
        parts[2] = '" /><text x="10" y="20" class="base">';

        parts[3] = getSociety(tokenId);

        parts[4] = '</text><text x="10" y="40" class="base">';

        parts[5] = getClass(tokenId);

        parts[6] = '</text><text x="10" y="60" class="base">Major: ';

        parts[7] = getMajor(tokenId);

        parts[8] = '</text><text x="10" y="80" class="base">Grade: ';

        parts[9] = getGrade(tokenId);

        parts[10] = '</text><text x="10" y="100" class="base">Accessory: ';

        parts[11] = getAccessory(tokenId);

        parts[12] = '</text><text x="10" y="120" class="base">Hobbies: ';

        parts[13] = getInterest(tokenId);

        parts[14] = '</text><text x="10" y="140" class="base">Swagger: ';
        
        parts[15] = StringUtil.toString(getSwagger(tokenId));

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Roll #', StringUtil.toString(tokenId), '", "description": "Gear University is a college themed derivative universe adding randomly generated student profiles stored on chain to the Gear project. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Gear University in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    function ownerClaim(uint256[] memory tokenIds) public nonReentrant onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 7777 && tokenIds[i] <= 7877, "Token ID invalid");
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function mint(uint256[] memory tokenIds) public payable nonReentrant {
        require((price * tokenIds.length) <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 7877 && tokenIds[i] <= 12000, "Token ID invalid");
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function claimWithGear(uint256[] memory gearIds) public payable nonReentrant {
        for (uint256 i = 0; i < gearIds.length; i++) {
            require(gearIds[i] > 0 && gearIds[i] <= 7777, "Token ID invalid");
            require(gearContract.ownerOf(gearIds[i]) == msg.sender, "Not gear owner");
            _safeMint(_msgSender(), gearIds[i]);
        }
    }

    function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
    }
}
