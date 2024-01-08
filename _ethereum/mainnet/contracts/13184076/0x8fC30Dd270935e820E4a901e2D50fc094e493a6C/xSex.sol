// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

import "./IMintableERC20.sol";
import "./Base64.sol";

contract xSex is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 constant public REWARDS_PER_CLAIM = 10*10**18;

    IMintableERC20 private sceneToken;
    IERC721 private loot;
    IERC721 private pLoot;
    IERC721 private xLoot;

    uint256 public lootClaimedCount;
    mapping(address => uint8) looterClaimedCount;

    uint256 public pLootClaimedCount;
    mapping(address => uint8) pLooterClaimedCount;

    uint256 public xLootClaimedCount;
    mapping(address => uint8) xLooterClaimedCount;

    uint256 private _tokenId;

    constructor(
        address _sceneToken,
        address _loot,
        address _pLoot,
        address _xLoot
    ) ERC721("xSex by xScene.io for adventurers", "XSEX") Ownable() {
        sceneToken = IMintableERC20(_sceneToken);
        loot = IERC721(_loot);
        pLoot = IERC721(_pLoot);
        xLoot = IERC721(_xLoot);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
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

    function getAnatomicalSex(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");

        uint256 rand = random(string(abi.encodePacked("Anatomical Sex", Strings.toString(tokenId))));
        uint256 greatness = rand % 1000;
        if (greatness < 600) {
            return "Male";
        }
        if (greatness > 599 && greatness < 999) {
            return "Female";
        }
        return "Intersex";
    }

    function getGenderIdentity(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");

        uint256 rand = random(string(abi.encodePacked("Gender Identity", Strings.toString(tokenId))));
        uint256 greatness = rand % 100;
        if (greatness < 58) {
            return "Male";
        }
        if (greatness > 57 && greatness < 96) {
            return "Female";
        }
        if (greatness > 95 && greatness < 97) {
            return "Agender";
        }
        return "Bigender";
    }

    function getAttraction(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");
    
        uint256 rand = random(string(abi.encodePacked("Attraction", Strings.toString(tokenId))));
        uint256 greatness = rand % 100;
        if (greatness < 38) {
            return "Male";
        }
        if (greatness > 37 && greatness < 96) {
            return "Female";
        }
        if (greatness > 95 && greatness < 97) {
            return "Agender";
        }
        return "Bigender";
    }

    function getX(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");

        uint256 rand = random(string(abi.encodePacked("X", Strings.toString(tokenId))));
        uint256 greatness = rand % 1000;
        if (greatness < 1) {
            return "Two-spirit";
        }
        if (greatness > 0 && greatness < 5) {
            return "Transsexual";
        }
        return "";
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string[9] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">Anatomical Sex: ';

        parts[1] = getAnatomicalSex(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">Gender Identity: ';

        parts[3] = getGenderIdentity(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">Attraction: ';

        parts[5] = getAttraction(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getX(tokenId);

        parts[8] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "xSex #', toString(tokenId), '", "description": "Don\'t feel like a boy or girl? Come to join xSex. Your experience of gender is unique to you. No wrong answers here and we hope you enjoy your metaverse identity in this sexy world.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function looterClaim() public nonReentrant {
        require(_tokenId < 10020, "Token ID invalid");
        require(lootClaimedCount < 8020, "Loot card claim completed");
        require(loot.balanceOf(_msgSender()) > 0, "Not Loot owner");
        require(looterClaimedCount[_msgSender()] < 10, "Exceeded max claim times");

        looterClaimedCount[_msgSender()] = looterClaimedCount[_msgSender()] + 1;
        lootClaimedCount++;
        _safeMint(_msgSender(), _tokenId);
        _tokenId++;
        sceneToken.mint(owner(), REWARDS_PER_CLAIM);
        sceneToken.mint(_msgSender(), REWARDS_PER_CLAIM);
    }

    function pLooterClaim() public nonReentrant {
        require(_tokenId < 10020, "Token ID invalid");
        require(pLootClaimedCount < 1000, "pLoot card claim completed");
        require(pLoot.balanceOf(_msgSender()) > 0, "Not pLoot owner");
        require(pLooterClaimedCount[_msgSender()] < 3, "Exceeded max claim times");

        pLooterClaimedCount[_msgSender()] = pLooterClaimedCount[_msgSender()] + 1;
        pLootClaimedCount++;
        _safeMint(_msgSender(), _tokenId);
        _tokenId++;
        sceneToken.mint(owner(), REWARDS_PER_CLAIM);
        sceneToken.mint(_msgSender(), REWARDS_PER_CLAIM);
    }

    function xLooterClaim() public nonReentrant {
        require(_tokenId < 10020, "Token ID invalid");
        require(xLootClaimedCount < 1000, "xLoot card claim completed");
        require(xLoot.balanceOf(_msgSender()) > 0, "Not xLoot owner");
        require(xLooterClaimedCount[_msgSender()] < 3, "Exceeded max claim times");

        xLooterClaimedCount[_msgSender()] = xLooterClaimedCount[_msgSender()] + 1;
        xLootClaimedCount++;
        _safeMint(_msgSender(), _tokenId);
        _tokenId++;
        sceneToken.mint(owner(), REWARDS_PER_CLAIM);
        sceneToken.mint(_msgSender(), REWARDS_PER_CLAIM);
    }
    
    function ownerBatchClaim(uint256 startTokenID, uint256 count) public nonReentrant onlyOwner {
        require(
            startTokenID > 10019 && startTokenID + count < 10221,
            "Token ID invalid"
        );
        for (uint256 i = 0; i < count; i++) {
            _safeMint(owner(), startTokenID + i);
        }
        sceneToken.mint(owner(), 2 * count * REWARDS_PER_CLAIM);
    }

    function ownerClaim(uint256 tokenID) public nonReentrant onlyOwner {
        require(tokenID > 10019 && tokenID < 10220, "Token ID invalid");
        _safeMint(owner(), tokenID);
        sceneToken.mint(owner(), 2 * REWARDS_PER_CLAIM);
    }
}
