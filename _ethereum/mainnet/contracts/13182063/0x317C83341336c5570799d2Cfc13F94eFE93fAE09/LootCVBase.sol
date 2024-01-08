// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./StringUtil.sol";
import "./Randomizer.sol";

contract LootCVBase is ERC721Enumerable, Ownable {

    struct Kingdom {
        string id;
        string name;
        string color;
    }

    struct Education {
        string[2] rareSchools;
        string[2] highSchools;
        string[2] midSchools;
    }
    mapping(string => Education) education;

    struct Work {
        string[4] rareWork;
        string[2] highWork;
        string commonWork;
    }
    mapping(string => Work) work;

    constructor(
        string memory _name,
        string memory _symbol
    ) public ERC721(_name, _symbol) Ownable() {
        education["lissan"] = Education([unicode"Länsän School of Enlightenment", unicode"Military Academy of Bältashal"], [unicode"Lönheum Polytechnic Institute", unicode"Papal Academy of Lissän"], [unicode"Lälma University", unicode"Pönlam College"]);
        education["inpen"] = Education(["Pimnen Institute of Magic Sciences", "Defense Academy of Mintim"], ["National University of Inpen", "The Lallow College of Arts"], ["Monlo School", "Kannin University"]);
        education["koyaro"] = Education(["The Chancellor's School at Mihake, Economics", "The Chancellor's School at Nasunpo, Law"], ["Vanguard University of Koyaro", "Konlotu School for the Gifted"], ["Nihahe University", "Pusipe University"]);
        education["mage"] = Education(["Pedagogical School of Free Thought", "Pedagogical School of the Great Divine"], ["Pedagogical School of Egalitarianism", "Pedagogical School of the Proletariat"], ["Pedagogical School of Egalitarianism", "Pedagogical School of the Proletariat"]);

        work["lissan"] = Work([unicode"Grand Papal Mage of Lissän + 1", unicode'Crusader of Lissän, "The Second Dragon Wars" +1', unicode'High Bishop, "Third Treatise of Länsän" +1', unicode'Cardinal to the Grand Papal Mage of Lissän'], ["High Troubadour of the Papacy","High Wandmaker to the Papacy"], unicode"Soldier of Lissän");
        work["inpen"] = Work(["Senate Premier of Inpen Parliament +1", "Commander of the Inpen United Forces", 'Veteran of the Inpen United Forces, "Siege of Parota" +1', "High Cabinet Member of Inpen"], ["Council Mage of Monlo","Council Mage of Kannin"], "Soldier of the Inpen United Forces");
        work["koyaro"] = Work(["Supreme Chancellor of Koyaro +1", 'General of the Koyaro Imperial Army, "Siege of Parota" +1','Koyaro Minister Premier of Finance','Koyaro Minister Premier of Defense'], ["Lieutenant of the Koyaro Imperial Army","Koyaro Defense Administrator"], "Recruit of the Koyaro Imperial Army");
        work["mage"] = Work(["Grand Spirit Shaman of the Free Mages +1", unicode'Proletariat of the Free Mages, "Third Treatise of Länsän" +1','Military General of the Free Mages, "Siege of Parota" +1','Military General of the Free Mages'], ["Council Member of the Free Mages", "Delegate of the Free Mages"], "Military Volunteer of the Free Mages");
    }

    // KINGDOM

    function pluckKingdom(uint256 tokenId) internal view returns (Kingdom memory) {
        uint256 rand = Randomizer.random(string(abi.encodePacked("KINGDOM", StringUtil.toString(tokenId))));
        if (rand % 10 <= 1) { //20%
            return Kingdom("lissan", unicode"Kingdom of Lissän", "#1B0630");
        } else if (rand % 10 <= 5) { //40%
            return Kingdom("inpen", "United Principality of Inpen", "#053525");
        } else if (rand % 10 <= 8) { //30%
            return Kingdom("koyaro", "Royal Koyaro Empire", "#330606");
        } else { // 10%
            return Kingdom("mage", "Commune of Free Mages", "#083042"); 
        }
    }

    // UNIVERSITIES

    function pluckUniversity(uint256 tokenId) internal view returns (string memory) {
        uint256 rand = Randomizer.random(string(abi.encodePacked("UNIVERSITY", StringUtil.toString(tokenId))));
        if (rand % 100 == 0) {
            return education[pluckKingdom(tokenId).id].rareSchools[tokenId % 2];
        } else if (rand % 100 <= 10) {
            return education[pluckKingdom(tokenId).id].highSchools[tokenId % 2];
        } else if (rand % 100 <= 35) {
            return education[pluckKingdom(tokenId).id].midSchools[tokenId % 2];
        }
        return "Trade School";
    }

    // SOCIETIES

    string [] private rareSocieties = [
        '"World Dragon Racing" League +1',
        '"Grand Mages" Council of Shared Prosperity +1',
        '"Holy Trinity" Society +1',
        '"Dragon Preservation" Sanctuary',
        unicode'Disciples of Bältashal',
        'The Sect of Fading Yew'
    ];

    string [] private highSocieties = [
        "Wandmakers Guild",
        "Artisan Guild",
        "Alchemy Guild",
        "Chess Guild",
        "Dragon Guild"
    ];

    function pluckSociety(uint256 tokenId) internal view returns (string memory) {
        uint256 rand = Randomizer.random(string(abi.encodePacked("SOCIETY", StringUtil.toString(tokenId))));
        if (rand % 100 <= 4) { // (5%)
            return Randomizer.pluck(tokenId, "RARESOCIETY", rareSocieties);
        } else if (rand % 100 <= 29){ // (25%)
            return Randomizer.pluck(tokenId, "HIGHSOCIETY", highSocieties);
        }
        return "Guild";
    }

    // PROFESSIONS

    string [] private generalProfessions = [
       "Healer","Historian","Philosopher","Architect","Translator","Wandmaker","Blacksmith","Magistrate","Alchemist","Astronomer","Diplomat","Professor","Scribe","Stonemason","Jewelry Maker","Guard","Potioneer", "Weaver", "Herbologist", "Librarian"
    ];

    string [] private rareNotableProfs = [
        'Philosopher, "On the Marriage of Disciplines" +1',
        'Historian, "Legend of the Sacred Yew" +1',
        unicode'Historian, "Disgrace of the Lissän Papacy" +1',
        'Historian, "The Second Dragon Wars" +1',
        'Alchemist, "Dragonskin-Mithral Conversion" +1'
    ];

    string [] private highNotableProfs = [
        'Olympian, "Rune Jousting"',
        'Olympian, "Dragon Racing"',
        unicode'Architect, "Grand Cathedral of Länsän"',
        'Architect, "Royal Palace of Koyaro"'
    ];

    string [] private midNotableProfs = [
        'Philosopher, "Criticism of Logical Thought"',
        'Philosopher, "The Great Reformation"',
        'Alchemist, "Dragonskin Life Rune"',
        'Alchemist, "Koyaro Mithral Conversion"',
        'Historian, "The Fall of the Dragon King"',
        'Historian, "The First Founders of Magic"',
        unicode'Diplomat, "Third Treatise of Länsän"',
        unicode'Diplomat, "Grand Council at Bältashal"',
        'Diplomat, "The Inpen Declaration of Union"'
    ];

    function pluckProfession(uint256 tokenId, uint count) internal view returns (string memory) {
        uint256 rand = Randomizer.random(string(abi.encodePacked("PROFESSION", StringUtil.toString(count * 1000 + tokenId))));
        if (rand % 10 <= 1) { // Kingdom profession (20%)
            uint256 kingdomRand = Randomizer.random(string(abi.encodePacked("KINGDOMPROF", StringUtil.toString(count * 1000 + tokenId))));
            if (kingdomRand % 100 <= 9) { // (10%)
                return work[pluckKingdom(tokenId).id].rareWork[(tokenId + count) % 4];
            } else if (kingdomRand % 100 <= 34) { // (25%)
                return work[pluckKingdom(tokenId).id].highWork[(tokenId + count) % 2];
            }
            return work[pluckKingdom(tokenId).id].commonWork; // (65%)
        } else if (rand % 10 <= 2) { // Notable profession (10%)
            uint256 notableRand = Randomizer.random(string(abi.encodePacked("SPECIALPROF", StringUtil.toString(count * 1000 + tokenId))));
            if (notableRand % 10 == 0) { 
                return rareNotableProfs[(tokenId + count) % rareNotableProfs.length]; // (10%)
            } else if (notableRand % 10 <= 4) { // (40%)
                return highNotableProfs[(tokenId + count) % highNotableProfs.length];
            }
            return midNotableProfs[(tokenId + count) % midNotableProfs.length]; // (50%)
        }   
        return generalProfessions[(tokenId + count) % generalProfessions.length]; // (70%)
    }

    // HOBBIES

    string [] private generalHobbies = [
        "Painter",
        "Singer",
        "Musician",
        "Sculptor",
        "Jeweler",
        "Dancer",
        "Playwright",
        "Winemaker",
        "Composer",
        "Novelist",
        "Rune Crafter",
        "Rune Jouster",
        "Spell Wrestler"
    ];
    
    string [] private notableHobbies = [
        unicode'Painter, "Grand Cathedral of Länsän"',
        'Painter, "The Purgatory of Magic"',
        "Sculptor, The Chancellor's Last Stand",
        "Sculptor, The Formation of the First Commune",
        "Novelist, Viceroy's Revenge",
        unicode'Novelist, "The Länsän School of Destruction"',
        'Singer, "The Song under the Sacred Yew"'
    ];

    string [] private rareHobbies = [
        'Painter, "Four Lilac Angels" +1',
        'Painter, "The Lamentation of Life" +1',
        unicode'Sculptor, "Remembering Old Bältashal" +1',
        unicode'Playwright, "Grand Council at Bältashal" +1',
        'Novelist, "The Great Papal Scandal" +1',
        'Singer, "The Ballad of Parota" +1'
    ];

    function pluckHobby(uint256 tokenId) internal view returns (string memory) {
        uint256 rand = Randomizer.random(string(abi.encodePacked("HOBBY", StringUtil.toString(tokenId))));
        if (rand % 100 <= 95) {
            return Randomizer.pluck(tokenId, "GENHOBBY", generalHobbies);
        } else if (rand % 100 <= 98){
            return Randomizer.pluck(tokenId, "SPECHOBBY", notableHobbies);
        }
        return Randomizer.pluck(tokenId, "RAREHOBBY", rareHobbies);
    }
}