// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./base64.sol";

contract Brainfck is ERC721 {
    string private baseURL = 'ipfs://QmZoUjQz8oEbhsMBVgLKupUFHVtq1TBJWXvwCvmhcJKTnV/';

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {
        for (uint i = 0; i < 100; i++) {
            _mint(msg.sender, i);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Brainfck: URI query for nonexistent token");
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "', 
            _tokenNames[tokenId], 
            '", "image": "', 
            baseURL, 
            Strings.toString(tokenId), 
            '.svg', '"}'
        ))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function imageURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "Brainfck: URI query for nonexistent token");
        return string(abi.encodePacked(
            baseURL, 
            Strings.toString(tokenId),
            '.svg'
        ));
    }

    string[100] private _tokenNames = [
        "Civil Unrest",
        "Pizzagate",
        "False Flag",
        "Jewish Space Lasers",
        "Sheeple",
        "Liberal Hoax",
        "Trump Pee Pee Tape",
        "Deep State",
        "Plandemic",
        "Stop The Steal",
        "Defund The Police",
        "Crisis Actor",
        "Troll Factory",
        "Horse Dewormer",
        "Hillary Emails",
        "Brain Fck",
        "Fake News",
        "Post Truth",
        "Collateral Murder",
        "Inside Job",
        "Person, Woman, Man, Camera, TV",
        "Vaccine Microchip",
        "5G Vaccine",
        "Alt Right",
        "Flat Earth",
        "Anti Vaxx",
        "Cancel Culture",
        "Anti Masker",
        "Voter Fraud",
        "OK Boomer",
        "Fact Checker",
        "Orange Man Bad",
        "Let's Go Brandon",
        "Critical Race Theory",
        "Thoughts And Prayers",
        "Insurrection",
        "Antifa",
        "Covfefe",
        "Wokeness",
        "Trumptard",
        "Own The Libs",
        "Hunter Biden Laptop",
        "Trust The Plan",
        "Lockdown",
        "Covidiot",
        "MAGAts",
        "Adrenochrome",
        "Russiagate",
        "Deplorables",
        "Collusion",
        "Obstruction",
        "Satanic Pedophiles",
        "Save The Children",
        "Epstein Didn't Kill Himself",
        "Guns Don't Kill People",
        "Shelter In Place",
        "The Great Awakening",
        "Libtard",
        "Leftist",
        "Sovereign Citizen",
        "The Storm",
        "The One Percent",
        "My Body My Choice",
        "Culture War",
        "Build The Wall",
        "Police Brutality",
        "Deep Fake",
        "White Privelege",
        "Very Stable Genius",
        "Whistleblower",
        "Big Tech",
        "Social Justice Warrior",
        "Wealth Transfer",
        "Big Lie",
        "Gender Neutral",
        "Big Pharma",
        "Snowflake",
        "MSM",
        "Identity Politics",
        "Delta Variant",
        "Omicron Variant",
        "Safe Space",
        "Gun Control",
        "Grab Them By The Pussy",
        "Trigger Warning",
        "New World Order",
        "Suicide By Cop",
        "Vaccine Mandate",
        "Lock Her Up",
        "Neopronoun",
        "Alternative Facts",
        "Echo Chamber",
        "Bull Market",
        "Disinformation",
        "Antiscience",
        "The Great Reset",
        "Misinformation",
        "Hate Speech",
        "Face Diaper",
        "Mass Shooting"
    ];
}
