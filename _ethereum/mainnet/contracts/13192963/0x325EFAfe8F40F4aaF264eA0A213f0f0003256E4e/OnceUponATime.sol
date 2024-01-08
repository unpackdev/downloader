// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract RobotosContract {
    function balanceOf(address owner)
        external
        view
        virtual
        returns (uint256 balance);
}

contract OnceUponATime is ERC721Enumerable, ReentrancyGuard, Ownable {
    string[] private adjective = [
        " a fearless",
        " a brave",
        " a timid",
        " a bold",
        " a witty",
        " an adventurous",
        " a silly",
        " an abrasive",
        " a paranormal",
        " a rogue",
        " a peculiar",
        " a courageous",
        " a mighty",
        " a charismatic",
        " a sharp",
        " a clever",
        " a curious",
        " a misunderstood",
        " a wise",
        " an unemployed",
        " a selfless",
        " a disillusioned",
        " a humble",
        " an honest",
        " a cheerful",
        " a creative",
        " a friendly"
    ];

    string[] private hero = [
        " astronaut",
        " wizard",
        " robot",
        " soldier",
        " scientist",
        " Viking",
        " samurai",
        " ninja",
        " pirate",
        " cyborg",
        " chef",
        " pilot",
        " captain",
        " teacher",
        " plumber",
        " carpenter",
        " artist",
        " sheriff",
        " warrior",
        " farmer",
        " janitor",
        " gardener",
        " cab driver",
        " blacksmith",
        " fisherman",
        " general",
        " investigator",
        " magician",
        " sailor",
        " waitress",
        " alchemist",
        " duke"
    ];

    string[] private description = [
        " always dreamed of traveling the universe.",
        " lived on a distant planet.",
        " wanted to overcome their fears.",
        " lived by the beach.",
        " had a mysterious tattoo on their hand.",
        " worked in an enchanted forest.",
        " was retired.",
        " lived in a cursed cemetery.",
        " had a double life as a paid assassin.",
        " worked on a distant star.",
        " took care of an abandoned space station.",
        " had a laboratory in a castle.",
        " had a home by an active volcano.",
        " was born into a poor family.",
        " had a double life as an undercover detective.",
        " took care of an underground cavern.",
        " used to live on the outskirts of town.",
        " was captive in a cave.",
        " had been separated from society.",
        " habitated an abandoned sanatorium.",
        " was banished from the city.",
        " owned a junkyard.",
        " worked in a burrito shop.",
        " had a photographic memory.",
        " lived a quiet life.",
        " served time at a mental hospital.",
        " lived in a futuristic city."
    ];

    string[] private routine = [
        " grew more and more frustrated with their boring life.",
        " looked at the stars and pondered about other worlds.",
        " aspired to explore the galaxy.",
        " wanted to escape their dull existence.",
        " fantasized about discovering a new planet.",
        " grew more disappointed with their existence.",
        " dreamt of escaping their monotonous routine.",
        " fantasized about doing extraordinary feats.",
        " practiced their craft.",
        " wrote fantastical stories wishing they became real.",
        " heard the distant bombs from the raging civil war.",
        " snooped on the neighbors' lives.",
        " struggled to live in a modern technological society.",
        " yearned not to feel lonely.",
        " felt frustrated from their work not being recognized.",
        " craved vengeance upon their old enemies.",
        " worried about protecting their business.",
        " felt like a reason to live was nowhere to be found.",
        " sought forgiveness for their past mistakes.",
        " hoped of starting a new life.",
        " craved learning new powers.",
        " pondered how it would feel to not be a robot.",
        " yearned to become a professional reggaeton dancer.",
        " consistently pursued perfection in everything.",
        " photographed their surroundings.",
        " solved sudokus to pass the time.",
        " celebrated the miracle of life. ",
        " ran around between hobbies and duties.",
        " listened to podcasts and drank lots of coffee.",
        " passed the time playing video games.",
        " invested time doing research.",
        " read complicated philosophical books.",
        " devoted time to meditation.",
        " went to parties to meet new people.",
        " invented new objects in the laboratory.",
        " took care of the wildlife around.",
        " composed music in a secret studio.",
        " studied people from a long distance.",
        " day-dreamed about an imaginary lover."
    ];

    string[] private eventDescription = [
        " a secret mission was assigned to them.",
        " a mysterious spaceship emerged from the clouds.",
        " an evil force started terrorizing the village.",
        " an enemy ship sailed into the harbor.",
        " a revolution by the underground fighters erupted.",
        " strange creatures emerged from the earth.",
        " a blinding light appeared in the sky.",
        " an unusual noise made people hallucinate.",
        " our hero was wrongfully accused of a crime.",
        " a beast visited at night with an unexpected proposition.",
        " a ghost appeared with an unusual mission.",
        " a relative from the future came with a terrible announcement.",
        " the living dead started terrorizing the town.",
        " a mysterious deadly virus took over the world.",
        " a radioactive lightning bolt hit our hero in the head.",
        " an alien ship fired a laser beam to the center of the earth.",
        " a serial killer started random attacks.",
        " acid rain started falling from the sky.",
        " a failed experiment brought chaos everywhere.",
        " our hero was called to fight a mysterious enemy.",
        " our hero was betrayed by their most trusted partner.",
        " a strange being started terrorizing people.",
        " our hero's family was in danger.",
        " a nearby village needed protection from evil forces.",
        " the opportunity to find hidden treasure presented itself.",
        " our hero became trapped in a strange world of spirits.",
        " our hero's former lover appeared with unpredicted complications.",
        " they were left stranded in a haunted house.",
        " our hero was sent on a dangerous mission.",
        " all their savings disappeared and trouble began.",
        " an identical person came to tell them that they're a clone.",
        " they received a distress signal from a distant planet.",
        " the king got captured and was being held hostage.",
        " they discovered a secret and mysterious door to a different dimension.",
        " our hero was mistaken for a spy.",
        " a conflict between the classes broke out.",
        " an old classmate showed up.",
        " a political scandal erupted.",
        " our hero was accidentally sent back in time.",
        " a full-scale gang war was set in motion."
    ];

    string[] private personalConsequence = [
        " was imprisoned",
        " had to flee their world",
        " was transferred to another dimension",
        " began to feel weak and confused",
        " had to hide their identity",
        " was thrown into the catacombs",
        " was taken captive",
        " was blackmailed",
        " was nearly killed",
        " had to escape their planet",
        " had to get protection from bioattacks",
        " got a genetic modification",
        " began to decompose",
        " lost their faith",
        " was tempted to use sinister forces",
        " had a creature hatch inside of their system",
        " teamed up with an unsual crew",
        " joined a fellowship",
        " had to join the resistance",
        " had to go undercover in a punk band",
        " was being chased",
        " fell on a trap",
        " felt tormented"
    ];

    string[] private externalConsequence = [
        " multiple people died.",
        " their family was captured.",
        " people began to disappear.",
        " was separated from everyone on Earth.",
        " their best friend was kidnapped.",
        " they became hypnotized.",
        " their pet was tortured.",
        " their family was murdered.",
        " a robot machine started plotting to kill them.",
        " an AI took over all intelligent appliances.",
        " a hunt for their head began.",
        " the entire crew got infected.",
        " an imminent nightmare dropped on them.",
        " everyone went on a dangerous adventure.",
        " found their family and friends slaughtered.",
        " many people were hurt along the way.",
        " a child was taken hostage.",
        " greed took over everyone.",
        " was betrayed by their best friend.",
        " was double-crossed by their family."
    ];

    string[] private climax = [
        " overcame their fears and destroyed",
        " escaped from capture and defeated",
        " sacrificed themselves to",
        " grabbed a magical sword and defeated",
        " courageously faced",
        " regained sanity and shot down",
        " acquired a mystical force and beat",
        " accepted their destiny and fought",
        " inspired their companions to rebel against",
        " found the courage to fight and defeat",
        " finally confronted",
        " picked up their magical weapon to conquer",
        " found an inner superpower to overcome",
        " uncovered the capacity of the team to beat",
        " discovered their brutal nature to kill",
        " was consumed by rage and defeated",
        " broke their chains and gave a deadly kick to",
        " summoned the courage to disrupt the plan of",
        " recovered strength and demolished"
    ];

    string[] private enemyAdjective = [
        " the evil",
        " the vicious",
        " the demonic",
        " the wicked",
        " the corrupt",
        " the malicious",
        " the violent",
        " the giant",
        " the one-eyed",
        " the eight-legged",
        " the smelly",
        " the shadowy",
        " the venom-infested",
        " the deadly",
        " the merciless",
        " the violent",
        " the creepy",
        " the sadistic",
        " the psychotic",
        " the misunderstood",
        " the supernatural",
        " the manipulative",
        " the paranormal"
    ];

    string[] private enemy = [
        " witch",
        " robot",
        " ghost",
        " monster",
        " war criminal",
        " warlord",
        " giant beast",
        " girl scouts",
        " druglord",
        " clone",
        " supercomputer",
        " toaster",
        " killer rabbit",
        " forest critters",
        " beast",
        " clown",
        " slayer",
        " baby penguins",
        " babies",
        " psychic",
        " terrorist",
        " chihuahua",
        " skeleton",
        " king",
        " bully",
        " corporate executive",
        " sorcerer",
        " murderer",
        " agent",
        " alien",
        " hunter",
        " gangster",
        " lord",
        " doppelganger",
        " cannibal",
        " bounty hunter"
    ];

    string[] private conclusion = [
        " saved the planet.",
        " found inner peace.",
        " brought balance to the force.",
        " peace returned.",
        " was reunited with their lost love.",
        " died a hero.",
        " saved the people.",
        " was rewarded treasure.",
        " died in obscurity.",
        " lived in obscurity.",
        " became corrupted by evil.",
        " learned it was all a dream.",
        " returned home peacefully.",
        " maintained a tormented life.",
        " found the courage they never knew had.",
        " found the true meaning of their existence.",
        " restored peace and justice.",
        " lost their humanity in the process.",
        " regained their humanity at last.",
        " started seeing life through different eyes.",
        " was finally free.",
        " found that everything was pointless.",
        " realized that revenge is not the answer.",
        " recovered their self-esteem.",
        " discovered a sense of belonging.",
        " won the respect they longed for."
    ];

    RobotosContract private ROBO;

    constructor(address dependentContractAddress)
        ERC721("OnceUponATime", "OUAT")
    {
        ROBO = RobotosContract(dependentContractAddress);
    }

    function getAdjective(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ADJECTIVE", adjective);
    }

    function getHero(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HERO", hero);
    }

    function getRoutine(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ROUTINE", routine);
    }

    function getEvent(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "EVENT", eventDescription);
    }

    function getPersonalConsequence(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "PERSONAL_CONSEQUENCE", personalConsequence);
    }

    function getExternalConsequence(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "EXTERNAL_CONSEQUENCE", externalConsequence);
    }

    function getDescription(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "DESCRIPTION", description);
    }

    function getClimax(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CLIMAX", climax);
    }

    function getEnemyAdjective(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "ENEMY_ADJECTIVE", enemyAdjective);
    }

    function getEnemy(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ENEMY", enemy);
    }

    function getConclusion(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "CONCLUSION", conclusion);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    keyPrefix,
                    tokenId,
                    block.timestamp,
                    block.difficulty
                )
            )
        );
        string memory output = sourceArray[rand % sourceArray.length];

        return output;
    }

    function getPart1(uint256 tokenId) internal view returns (string memory) {
        string[11] memory parts;
        parts[0] = "Once upon a time, there was";
        parts[1] = getAdjective(tokenId);
        parts[2] = getHero(tokenId);
        parts[3] = " who";
        parts[4] = getDescription(tokenId);
        parts[5] = " Every day, the";
        parts[6] = getHero(tokenId);
        parts[7] = getRoutine(tokenId);
        parts[8] = " But one day,";
        parts[9] = getEvent(tokenId);
        parts[10] = " Because of that, the";

        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4],
                    parts[5],
                    parts[6],
                    parts[7],
                    parts[8],
                    parts[9],
                    parts[10]
                )
            );
    }

    function getPart2(uint256 tokenId) internal view returns (string memory) {
        string[10] memory parts;

        parts[0] = getHero(tokenId);
        parts[1] = getPersonalConsequence(tokenId);
        parts[2] = " and";
        parts[3] = getExternalConsequence(tokenId);
        parts[4] = " Until finally, our hero";
        parts[5] = getClimax(tokenId);
        parts[6] = getEnemyAdjective(tokenId);
        parts[7] = getEnemy(tokenId);
        parts[8] = " and";
        parts[9] = getConclusion(tokenId);

        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4],
                    parts[5],
                    parts[6],
                    parts[7],
                    parts[8],
                    parts[9]
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[4] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.font { fill: black; font-family: sans-serif; font-size: 15px; line-height: 24px; letter-spacing: -0.01em; } foreignObject { padding: 24px; }</style><rect width="100%" height="100%" fill="white" /><foreignObject x="0" y="0" class="font" width="350" height="350">';
        parts[1] = getPart1(tokenId);
        parts[2] = getPart2(tokenId);
        parts[3] = "</foreignObject></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3])
        );

        string memory story = string(abi.encodePacked(parts[1], parts[2]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Once Upon A Time #',
                        toString(tokenId),
                        '", "description": "',
                        story,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId >= 0 && tokenId < 4700, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    modifier onlyAdmin() {
        require(
            _msgSender() == 0x273Dc0347CB3AbA026F8A4704B1E1a81a3647Cf3 ||
                _msgSender() == 0x63989a803b61581683B54AB6188ffa0F4bAAdf28,
            "No access"
        );
        _;
    }

    function robotoClaim(uint256 tokenId) public nonReentrant {
        require(tokenId >= 4700 && tokenId < 4900, "Token ID invalid");
        uint256 ownedRobotos = ROBO.balanceOf(_msgSender());
        require(
            ownedRobotos > 0,
            "Must hold at least one Roboto to claim this token"
        );
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyAdmin {
        require(tokenId >= 4900 && tokenId < 5000, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
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
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
