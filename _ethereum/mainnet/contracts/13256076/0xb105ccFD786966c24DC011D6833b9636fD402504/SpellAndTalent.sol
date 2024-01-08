// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./Base64.sol";
import "./Project.sol";

contract SpellAndTalent is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using Strings for uint;

    uint public constant PRICE = 1e16; //0.01 ETH
    uint public constant MAX_PURCHASE = 50;
    uint private constant MAX_SUPPLY = 16888;
    uint private constant MAX_RESERVE = 45;

    uint private constant MAX_LOOT = 8001;
    uint private constant MAX_N = 8889;

    uint private _maxProjectSupply = 4000;
    uint private _lootSupply = 0;
    uint private _nSupply = 0;

    mapping(uint => bool) private _loot;
    mapping(uint => bool) private _n;

    string[] private skill1 = [
        "Divine Favor",
        "Holy Sword",
        "Remove Disease",
        "Dragon Breath",
        "Negative Energy",

        "Lay On Hands",
        "Aura Of Courage",
        "Concentration Aura",
        "Demonic Embrace",
        "Soul Link"
    ];

    string[] private skill2 = [
        "Shield Strike",
        "Summon Creature",
        "Shadow Bolt",
        "Lightning Storm",
        "Killing Spree",

        "Protection Aura",
        "Shadow Aura",
        "Magic Resistance",
        "Mastery Elements",
        "Dual Wield"
    ];


    string[] private skill3 = [
        "Flame Wave",
        "Deadly Poison",
        "Rage Shot",
        "Light Heal",
        "Wave Of Heal",

        "Fire Mastery",
        "Beast Aura",
        "Rampage",
        "Healing Favor",
        "Holy Concentration"
    ];

    string[] private skill4 = [
        "Shield Bash",
        "Blind",
        "Ambush",
        "Power Barrier",
        "Summon Rare Creature",

        "Stone Skin",
        "Aid Mastery",
        "Double Strike",
        "Dragon Fury",
        "Elemental Focus"
    ];

    string[] private skill5 = [
        "Implosion",
        "Bloody Claw",
        "Brutal Clap",
        "Seal Of Vengeance",
        "Sacrifice",

        "Combat Mastery",
        "Blessed Fortitude",
        "Greater Range",
        "Toughness",
        "Improved Recovery"
    ];

    string[] private skill6 = [
        "Fire Missiles",
        "Mute Shot",
        "Resurrection",
        "Armageddon",
        "Berserk",

        "Dodge Mastery",
        "Inspiring Strike",
        "Weapon Specialization",
        "Gift Of Nature",
        "Wild Instinct"
    ];

    string[] private skill7 = [
        "Hypnotize",
        "Fade",
        "Weakness",
        "Heavy shot",
        "Hammer Strike",

        "Efficiency",
        "Precision",
        "Improved Haste",
        "Bloodlust",
        "Second Chance"
    ];

    string[] private skill8 = [
        "Healing Guardian",
        "Ghost Strike",
        "Magic Shield",
        "Bladefall",
        "Shadow Bolt",

        "Focus",
        "Unleashed Anger",
        "Slayer",
        "Iron Hope",
        "Eternal Ones Blessing"
    ];

    //Loot Contract
    address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    ProjectInterface lootContract = ProjectInterface(lootAddress);

    //N Contract
    address public nAddress = 0x05a46f1E545526FB803FF974C790aCeA34D1f2D6;
    ProjectInterface nContract = ProjectInterface(nAddress);

    function random(string memory input) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(input)));
    }

    function getSkill1(uint tokenId) public view returns (string memory, bool) {
        return pluck(tokenId, "SKILLONE", skill1);
    }

    function getSkill2(uint tokenId) public view returns (string memory, bool) {
        return pluck(tokenId, "SKILLTWO", skill2);
    }

    function getSkill3(uint tokenId) public view returns (string memory, bool) {
        return pluck(tokenId, "SKILLTHREE", skill3);
    }

    function getSkill4(uint tokenId) public view returns (string memory, bool) {
        return pluck(tokenId, "SKILLFOUR", skill4);
    }

    function getSkill5(uint tokenId) public view returns (string memory, bool) {
        return pluck(tokenId, "SKILLFIVE", skill5);
    }

    function getSkill6(uint tokenId) public view returns (string memory, bool) {
        return pluck(tokenId, "SKILLSIX", skill6);
    }

    function getSkill7(uint tokenId) public view returns (string memory, bool) {
        return pluck(tokenId, "SKILLSEVEN", skill7);
    }

    function getSkill8(uint tokenId) public view returns (string memory, bool) {
        return pluck(tokenId, "SKILLEIGHT", skill8);
    }

    function getSkills(uint tokenId) public view returns (string[16] memory) {
        string[16] memory skills;
        uint skillKey = 0;
        uint talentKey = 8;

        (string memory skill, bool isSpell) = getSkill1(tokenId);
        if (isSpell) {
            skills[skillKey++] = skill;
        } else {
            skills[talentKey++] = skill;
        }

        (skill, isSpell) = getSkill2(tokenId);
        if (isSpell) {
            skills[skillKey++] = skill;
        } else {
            skills[talentKey++] = skill;
        }

        (skill, isSpell) = getSkill3(tokenId);
        if (isSpell) {
            skills[skillKey++] = skill;
        } else {
            skills[talentKey++] = skill;
        }

        (skill, isSpell) = getSkill4(tokenId);
        if (isSpell) {
            skills[skillKey++] = skill;
        } else {
            skills[talentKey++] = skill;
        }

        (skill, isSpell) = getSkill5(tokenId);
        if (isSpell) {
            skills[skillKey++] = skill;
        } else {
            skills[talentKey++] = skill;
        }

        (skill, isSpell) = getSkill6(tokenId);
        if (isSpell) {
            skills[skillKey++] = skill;
        } else {
            skills[talentKey++] = skill;
        }

        (skill, isSpell) = getSkill7(tokenId);
        if (isSpell) {
            skills[skillKey++] = skill;
        } else {
            skills[talentKey++] = skill;
        }

        (skill, isSpell) = getSkill8(tokenId);
        if (isSpell) {
            skills[skillKey++] = skill;
        } else {
            skills[talentKey++] = skill;
        }

        return skills;
    }

    function pluck(uint tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory, bool) {
        uint rand = random(string(abi.encodePacked(keyPrefix, tokenId.toString())));
        uint key = rand % sourceArray.length;

        return (sourceArray[key], (key) < 5);
    }

    function tokenURI(uint tokenId) override public view returns (string memory) {
        string[16] memory skills = getSkills(tokenId);
        uint y = 0;
        uint key = 1;

        string[10] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';

        for (uint i = 0; i < skills.length; i++) {
            if (bytes(skills[i]).length == 0) {
                continue;
            }

            y += 20;
            parts[key++] = string(abi.encodePacked('<text x="10" y="', y.toString(), '" class="base">', skills[i], '</text>'));
        }

        parts[9] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', tokenId.toString(), '", "description": "Spell & Talent is randomly generated skills for adventurers. Combine them with any other #loot or #n ... and gain power beyond the imagination! Mixing them together let you overcome all the difficulties and create the greatest stories.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function price(uint256 numberOfTokens) public pure returns (uint256) {
        return PRICE.mul(numberOfTokens);
    }

    function increment() public onlyOwner {
        _maxProjectSupply++;
    }

    function reserve() public onlyOwner {
        _mintTokens(MAX_RESERVE);
    }

    function mint(uint numberOfTokens) public payable {
        require(numberOfTokens <= MAX_PURCHASE, "E:MAX_PURCHASE"); // Can only mint 50 tokens at a time
        require(totalSupply().add(numberOfTokens) < MAX_SUPPLY, "E:INVALID_SUPPLY"); // Purchase would exceed max supply of tokens
        require(price(numberOfTokens) <= msg.value, "E:INVALID_ETH_VALUE"); // Ether value sent is not correct

        _mintTokens(numberOfTokens);
    }

    function lootOwnerMint(uint tokenId) public nonReentrant {
        require(_lootSupply < _maxProjectSupply, "E:NO_MORE"); // No more token for loot owner
        require(!_loot[tokenId], "E:TOKEN_EXISTS"); // Only one token per loot token is available

        _projectOwnerMint(tokenId, MAX_LOOT, lootContract);

        _loot[tokenId] = true;
        _lootSupply++;
    }

    function nOwnerMint(uint tokenId) public nonReentrant {
        require(_nSupply < _maxProjectSupply, "E:NO_MORE"); // No more token for n owner
        require(!_n[tokenId], "E:TOKEN_EXISTS"); // Only one token per n token is available

        _projectOwnerMint(tokenId, MAX_N, nContract);

        _n[tokenId] = true;
        _nSupply++;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _mintTokens(uint numberOfTokens) private {
        for (uint i = 0; i < numberOfTokens; i++) {
            uint supply = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, supply);
            }
        }
    }

    function _projectOwnerMint(uint tokenId, uint max, ProjectInterface projectContract) private {
        require(tokenId > 0 && tokenId < max, "E:INVALID_TOKEN"); // Invalid token id
        require(totalSupply() <= MAX_SUPPLY, "E:INVALID_SUPPLY"); // Purchase would exceed max supply of tokens
        require(projectContract.balanceOf(msg.sender) > 0 && projectContract.ownerOf(tokenId) == _msgSender(), "E:WRONG_OWNER"); // Wrong token owner

        _safeMint(_msgSender(), totalSupply());
    }

    constructor() ERC721("SpellAndTalent", "SAT") Ownable() {}
}
