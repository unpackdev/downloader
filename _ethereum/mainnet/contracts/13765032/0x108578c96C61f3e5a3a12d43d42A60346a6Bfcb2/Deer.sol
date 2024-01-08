// SPDX-License-Identifier: AGPL-3.0-only

/*
*  \_\_     _/_/
*      \___/
*     ~(0 0)~
* ____/(._.)
*       /
* ___  /
*    ||
*    ||
* 
*/

pragma solidity 0.8.9;
import "./base64.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

interface ISpriteRouter {
    function getSprite(uint8 partId, uint8 typeId, uint8 spriteId) external view returns (string memory);
}

contract DearDeer is ERC721Enumerable {

    mapping(uint => bool) DNAMinted;
    mapping(uint => uint) DeerDNA;

    uint public MINT_PRICE = 0.05 ether;
    uint public MAX_SUPPLY = 5000;

    uint public MAX_MINT_PER_WALLET = 5;
    uint public MAX_MINT_PER_TX = 5;

    uint PRNG_ENT = 27;

    bool public MINT_IS_ON;
    bool public MINT_IS_PUBLIC;
    bool public REVEALED;

    bytes32 merkleRoot;

    address public owner;
    address public dao;

    uint16[][46] WEIGHTS;

    string[] GENDER           = ["Male", "Female"];
    string[] FUR              = ["Beastie", "Brown", "Elfie", "Frosty", "Ghost", "Golden", "Grey", "Pink", "Dr. Quantum"];
    string[] HAIR_COLOR       = ["Black", "Blonde", "Brown", "Bubblegum", "Night", "Purple", "Red", "Shameless", "Sh\xC5\x8Dsa", "Swampy", "White"];
    string[] HAIR_STYLE       = ["Average Dystopian Choice", "Elizabeth Theorem", "My Beloved", "Nuke 'Em", "Ouch", "Simply Free", "Spiky Originality", "Straight Grace", "Straight Grace With Curl", "The Princess", "Two Hot Buns", "Wine Consequence"];
    string[] FRECKLES         = ["Yes", "No"];
    string[] EYES             = ["Beyond Your Glasses", "Donate Me", "Hasta la Vista Baby", "I'm Tired", "Jazz", "Lively", "Lookers", "Midnight Movie", "Mildly Lovable", "Nuke Protectors", "Our Mutual Friend", "Pass the Boof", "Rectangular", "Red Menace", "Seduction", "Tired of Being Beautiful", "Unforgettable Moment"];
    string[] BROWS            = ["A Little Nervous", "Are They Drawn", "Be Gentle", "Be Harsh", "Big One", "Just Looking", "Seriously"];
    string[] BEARD            = ["A Brick of Hair", "Czar", "Hobo", "No Match", "Stasis", "Time Traveler", "None"];
    string[] MOUTH            = ["A Bit Happy", "Big Smile", "Confused", "Doomer", "Froggy", "No Mercy", "Not Too Pathetic", "Sheep Ancestors", "Smug", "Stunned", "Subscribe to My OnlyDeers", "Sweet Tooth"];
    string[] EARS             = ["Floppers", "I'm All Ears", "Little Cutie", "Mildly Cuter"];
    string[] EARRINGS         = ["Cheap Diamonds", "Praise ETH", "Thunderstorm", "Triple Pierce", "None"];
    string[] NOSE             = ["Bridged", "Cute-N-Small", "Flat Pierced", "Northern Hint", "Nosey", "Santa's Helper", "Second Heart", "Silver for Deers"];
    string[] ANTLERS          = ["Brave One", "Devil Within", "Hard Fought", "Lovable", "Pointers", "Shroom Blue", "Shroom Noisy", "Shroom Red", "Sigma", "Spy Among Us"];
    string[] ANTLER_ACCESSORY = ["4 Star Hotel", "That'll Do", "Desperate", "Afterparty", "Antennas", "Occasional Forager", "Plastic World", "None"];
    string[] CLOTHES          = ["A Link", "Apples", "Cheapest Choice", "Deers in Black", "Easy to Stain", "Favourite Servant", "Fountain Lover", "Heavy Suit", "I Live For This Shit", "Junkie", "Nuke Pack", "Ode to the Carpet", "Opened Up", "Smells Like Teen Spirit", "Spider Silk", "Surprise!", "Teufort Classic", "Too Tight for Space", "Upper Gift", "What Sweet Dreams Are Made Of", "Worker", "Young Producer", "Naked"];  // He-he naked
    string[] BACKGROUND       = ["Blue", "Dark Blue", "Green", "Lime", "Pink", "Red", "Violet", "Yellow"];

    string SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" id="deer">';
    string SVG_FOOTER = '<style>#deer {image-rendering: pixelated; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';
    string SVG_IMAGE_TAG = '<image width="100%" height="100%" href="data:image/png;base64,';

    string description = 'Dear Deer is a collection of hardcore onchain pixel art PFPs. Each deer is generated at the time of mint. No IPFS, no API, both metadata and graphics are stored on Ethereum forever.';

    ISpriteRouter spriteRouter;

    constructor() ERC721("Dear Deer", "DEER") {
        owner = msg.sender;

        WEIGHTS[0] = [5000, 5000];                                                          // gender
        WEIGHTS[1] = [300, 2500, 400, 400, 300, 1500, 3000, 1500, 100];                     // fur_m
        WEIGHTS[2] = [300, 3000, 400, 400, 300, 1500, 2500, 1500, 100];                     // fur_f
        WEIGHTS[3] = [1200, 3000, 3000, 100, 500, 500, 500, 500, 100, 500, 100];            // hair_color_m
        WEIGHTS[4] = [1100, 3000, 2000, 400, 800, 800, 800, 500, 200, 200, 200];            // hair_color_f
        WEIGHTS[5] = [2000, 0, 0, 1000, 2000, 2300, 2700, 0, 0, 0, 0, 0];                   // hair_style_m
        WEIGHTS[6] = [1200, 1300, 1300, 0, 200, 0, 800, 1100, 800, 1100, 1100, 1100];       // hair_style_f
        WEIGHTS[7] = [1000, 9000];                                                          // freckles_m
        WEIGHTS[8] = [5000, 5000];                                                          // freckles_f
        
        // eyes_m
        WEIGHTS[9] = [900, 0, 10, 1100, 300, 1800, 1000, 100, 0, 1000, 1000, 500, 1890, 200, 0, 200, 0];
        // eyes_f
        WEIGHTS[10] = [1200, 1000, 0, 100, 200, 1000, 1200, 100, 1500, 100, 700, 100, 100, 100, 1400, 700, 500];

        WEIGHTS[11] = [1000, 1000, 1000, 2000, 2000, 1500, 1500];                           // brows_m
        WEIGHTS[12] = [1500, 1000, 2000, 1000, 1000, 1500, 2000];                           // brows_f
        WEIGHTS[13] = [1000, 500, 700, 400, 1400, 1000, 5000];                              // beard_m
        WEIGHTS[14] = [0, 0, 0, 0, 0, 0, 10000];                                            // beard_f
        WEIGHTS[15] = [2000, 0, 1300, 0, 0, 0, 6700];                                       // beard_confused
        WEIGHTS[16] = [2000, 0, 1300, 0, 0, 0, 6700];                                       // beard_doomer
        WEIGHTS[17] = [2000, 0, 1300, 0, 0, 0, 6700];                                       // beard_froggy
        WEIGHTS[18] = [1100, 500, 900, 100, 0, 1000, 6400];                                 // beard_not_too_pathetic
        WEIGHTS[19] = [1100, 200, 800, 0, 0, 1000, 6900];                                   // beard_smug
        WEIGHTS[20] = [1200, 200, 1200, 400, 0, 100, 6900];                                 // beard_sweet_tooth
        WEIGHTS[21] = [1200, 1000, 900, 800, 1000, 1000, 700, 600, 700, 1500, 100, 500];    // mouth_m
        WEIGHTS[22] = [1000, 1500, 800, 300, 600, 200, 1000, 800, 900, 1200, 500, 1200];    // mouth_f
        WEIGHTS[23] = [3000, 3000, 2000, 2000];                                             // ears_m
        WEIGHTS[24] = [2000, 2000, 3000, 3000];                                             // ears_f
        WEIGHTS[25] = [0, 10, 0, 900, 9090];                                                // earrings_m
        WEIGHTS[26] = [1300, 200, 1100, 1400, 6000];                                        // earrings_f
        WEIGHTS[27] = [500, 2000, 500, 1000, 4000, 500, 1000, 500];                         // nose_m
        WEIGHTS[28] = [500, 2000, 500, 1000, 4000, 500, 1000, 500];                         // nose_f
        WEIGHTS[29] = [0, 2300, 600, 800, 4000, 600, 1100, 600];                            // nose_bridged
        WEIGHTS[30] = [2500, 1100, 2000, 800, 2100, 75, 50, 150, 1025, 200];                // antlers_m
        WEIGHTS[31] = [2250, 1050, 1650, 2000, 1650, 75, 50, 150, 925, 200];                // antlers_f
        WEIGHTS[32] = [400, 1000, 0, 0, 0, 0, 0, 8600];                                     // antler_accessory_brave_one_m
        WEIGHTS[33] = [300, 500, 0, 0, 0, 0, 0, 9200];                                      // antler_accessory_brave_one_f
        WEIGHTS[34] = [0, 0, 500, 0, 0, 0, 0, 9500];                                        // antler_accessory_hard_fought_m
        WEIGHTS[35] = [0, 0, 100, 0, 0, 0, 0, 9900];                                        // antler_accessory_hard_fought_f
        WEIGHTS[36] = [0, 0, 0, 200, 200, 0, 0, 9600];                                      // antler_accessory_lovable_m
        WEIGHTS[37] = [0, 0, 0, 400, 400, 0, 0, 9200];                                      // antler_accessory_lovable_f
        WEIGHTS[38] = [0, 0, 0, 0, 0, 300, 100, 9600];                                      // antler_accessory_pointers_m
        WEIGHTS[39] = [0, 0, 0, 0, 0, 500, 100, 9400];                                      // antler_accessory_pointers_f

        // clothes_m
        WEIGHTS[40] = [700, 0, 1600, 400, 400, 0, 300, 100, 500, 800, 100, 100, 1100, 300, 0, 0, 200, 0, 0, 100, 1400, 1000, 900];
        // clothes_f
        WEIGHTS[41] = [700, 400, 1400, 400, 400, 200, 0, 0, 500, 800, 0, 0, 700, 300, 300, 300, 200, 200, 400, 100, 1400, 1100, 200];

        WEIGHTS[42] = [1250, 1250, 1250, 1250, 1250, 1250, 1250, 1250];                     // background
        WEIGHTS[43] = [1700, 1700, 1700, 1700, 0, 0, 1500, 1700];                           // background_bubblegum
        WEIGHTS[44] = [1450, 1500, 1450, 1400, 1400, 1400, 1400, 0];                        // background_blonde
        WEIGHTS[45] = [1450, 0, 1450, 1400, 1400, 1450, 1450, 1400];                        // background_white

        devMint();
    }


    // MINT FUNCTIONS

    function whiteListMint(uint deer_num, bytes32[] calldata merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not whitelisted");

        require(MINT_IS_ON, "Mint is off");
        require(deer_num <= MAX_MINT_PER_TX, "Mint per tx cap");
        require(balanceOf(msg.sender) + deer_num <= MAX_MINT_PER_WALLET, "Mint per wallet cap");
        require(totalSupply() + deer_num <= MAX_SUPPLY, "Supply cap");
        require(MINT_PRICE * deer_num <= msg.value, "Not enough ETH");
        require(!isContract(msg.sender));

        for (uint i = 0; i < deer_num; i++) {
            mintDeer();
        }
    }

    function mint(uint deer_num) external payable {
        require(MINT_IS_ON, "Mint is off");
        require(MINT_IS_PUBLIC, "Public mint not started");
        require(deer_num <= MAX_MINT_PER_TX, "Mint per tx cap");
        require(balanceOf(msg.sender) + deer_num <= MAX_MINT_PER_WALLET, "Mint per wallet cap");
        require(totalSupply() + deer_num <= MAX_SUPPLY, "Supply cap");
        require(MINT_PRICE * deer_num <= msg.value, "Not enough ETH");
        require(!isContract(msg.sender));

        for (uint i = 0; i < deer_num; i++) {
            mintDeer();
        }
    }

    function devMint() internal {
        for (uint i = 0; i < 100; i++) {
            mintDeer();
        }
    }

    function mintDeer() internal {
        uint tokenId = totalSupply();
        uint DNA = generateDNA(tokenId);
        DeerDNA[tokenId] = DNA;
        DNAMinted[DNA] = true;

        _mint(msg.sender, tokenId);
    }

    function generateDNA(uint tokenId) internal returns (uint) {
        PRNG_ENT++; 
        uint DNA = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, tokenId, PRNG_ENT)));
        if (DNAMinted[DNA]) return generateDNA(tokenId);
        return DNA;
    }


    // VIEW FUNCTIONS

    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!REVEALED) {
            return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"description": "',
                                description,
                                '",',
                                '"image": "ipfs://bafybeifywnwas6zc3nim6eil76kkdgvfpctkr6ngy7sjiogj7losr4kdya/"}'   // the only use of IPFS is this temp placeholder gif before reveal
                            )
                        )
                    )
                )
            );
        }

        uint8[16] memory deer = getDeer(tokenId);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "Dear Deer #',
                            uintToString(tokenId),
                            '",',
                            '"description": "',
                            description,
                            '",',
                            '"image": "',
                            renderImage(deer),
                            '",',
                            formatTraits(deer),
                            '}'
                        )
                    )
                )
            )
        );
    }

    function getDeer(uint tokenId) public view returns (uint8[16] memory) {
        uint16[16] memory genes = sequenceDNA(DeerDNA[tokenId]);
        uint8[16] memory deer;

        // 0 gender
        // 1 fur
        // 2 hair_color
        // 3 hair_style
        // 4 freckles
        // 5 eyes
        // 6 brows
        // 7 beard
        // 8 mouth
        // 9 ears
        // 10 earrings
        // 11 nose
        // 12 antlers
        // 13 antler_accessory
        // 14 clothes
        // 15 background

        deer[0] = wrand(genes[0], 0);

        if (deer[0] == 0) {

            deer[1] = wrand(genes[1], 1);
            deer[2] = wrand(genes[2], 3);
            deer[3] = wrand(genes[3], 5);
            deer[4] = wrand(genes[4], 7);
            deer[5] = wrand(genes[5], 9);
            deer[6] = wrand(genes[6], 11);

            deer[8] = wrand(genes[8], 21);
            if (deer[8] == 2) {
                deer[7] = wrand(genes[7], 15);
            } else if (deer[8] == 3) {
                deer[7] = wrand(genes[7], 16);
            } else if (deer[8] == 4) {
                deer[7] = wrand(genes[7], 17);
            } else if (deer[8] == 6) {
                deer[7] = wrand(genes[7], 18);
            } else if (deer[8] == 8) {
                deer[7] = wrand(genes[7], 19);
            } else if (deer[8] == 11) {
                deer[7] = wrand(genes[7], 20);
            } else {
                deer[7] = wrand(genes[7], 13);
            }

            deer[9] = wrand(genes[9], 23);
            deer[10] = wrand(genes[10], 25);

            if (deer[5] == 0 || deer[5] == 4 || deer[5] == 7 || deer[5] == 9 || deer[5] == 10 || deer[5] == 13) {
                deer[11] = wrand(genes[11], 29);
            } else {
                deer[11] = wrand(genes[11], 27);
            }

            deer[12] = wrand(genes[12], 30);

            if (deer[12] == 0) {
                deer[13] = wrand(genes[13], 32);
            } else if (deer[12] == 2) {
                deer[13] = wrand(genes[13], 34);
            } else if (deer[12] == 3) {
                deer[13] = wrand(genes[13], 36);
            } else if (deer[12] == 4) {
                deer[13] = wrand(genes[13], 38);
            } else {
                deer[13] = 7;
            }

            deer[14] = wrand(genes[14], 40);

        } else {
            deer[1] = wrand(genes[1], 2);
            deer[2] = wrand(genes[2], 4);
            deer[3] = wrand(genes[3], 6);
            deer[4] = wrand(genes[4], 8);
            deer[5] = wrand(genes[5], 10);
            deer[6] = wrand(genes[6], 12);
            deer[7] = wrand(genes[7], 14);
            deer[8] = wrand(genes[8], 22);
            deer[9] = wrand(genes[9], 24);
            deer[10] = wrand(genes[10], 26);
            
            if (deer[5] == 0 || deer[5] == 4 || deer[5] == 7 || deer[5] == 9 || deer[5] == 10 || deer[5] == 13) {
                deer[11] = wrand(genes[11], 29);
            } else {
                deer[11] = wrand(genes[11], 28);
            }

            deer[12] = wrand(genes[12], 31);

            if (deer[12] == 0) {
                deer[13] = wrand(genes[13], 33);
            } else if (deer[12] == 2) {
                deer[13] = wrand(genes[13], 35);
            } else if (deer[12] == 3) {
                deer[13] = wrand(genes[13], 37);
            } else if (deer[12] == 4) {
                deer[13] = wrand(genes[13], 39);
            } else {
                deer[13] = 7;
            }

            deer[14] = wrand(genes[14], 41);
        }

        if (deer[2] == 3) {
            deer[15] = wrand(genes[15], 43);
        } else if (deer[2] == 1) {
            deer[15] = wrand(genes[15], 44);
        } else if (deer[2] == 10) {
            deer[15] = wrand(genes[15], 45);
        } else {
            deer[15] = wrand(genes[15], 42);
        }

        return deer;

        // Oh, deer, head hurts. But it works.
    }
    
    function sequenceDNA(uint DNA) internal pure returns (uint16[16] memory) {
        uint16[16] memory genes;
        for (uint8 i = 0; i < 16; i++) {
            genes[i] = uint16(DNA % 10000);
            DNA /= 10000;
        }
        return genes;
    }

    function wrand(uint16 gene, uint8 weightsListIndex) internal view returns (uint8 trait_index) {
        for (uint8 i = 0; i < WEIGHTS[weightsListIndex].length; i++) {
            uint16 current = WEIGHTS[weightsListIndex][i];
            if (gene < current) {
                return i;
            }
            gene -= current;
        }
        revert();
    }

    function renderImage(uint8[16] memory deer) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            SVG_HEADER,
                            composeSprites(deer),
                            SVG_FOOTER
                        )
                    )
                )
            )
        );
    }

    function composeSprites(uint8[16] memory deer) internal view returns (string memory) {

        string memory comp1 = string(abi.encodePacked(
            renderSprite(spriteRouter.getSprite(0, 0, deer[15])),                                   // background
            renderSprite(spriteRouter.getSprite(1, deer[0], deer[1])),                              // body
            renderSprite(spriteRouter.getSprite(3, deer[1], deer[6])),                              // brows
            deer[4] == 0 ? renderSprite(spriteRouter.getSprite(2, 0, 0)) : ''                       // freckles
        ));

        string memory comp2 = '';
        if (deer[3] == 0 || deer[3] == 9 || deer[3] == 11) {                                        // if over ear hair style
            comp2 = string(abi.encodePacked(                                                           
                renderSprite(spriteRouter.getSprite(5, deer[1], deer[9])),                          // ears
                deer[10] != 4 ? renderSprite(spriteRouter.getSprite(6, deer[9], deer[10])) : '',    // earrings
                renderSprite(spriteRouter.getSprite(7, 0, deer[5])),                                // eyes
                renderSprite(spriteRouter.getSprite(4, deer[2], deer[3]))                           // hair
            ));
        } else {                                                                                    // if regular hair style
            comp2 = string(abi.encodePacked(
                renderSprite(spriteRouter.getSprite(4, deer[2], deer[3])),                          // hair
                renderSprite(spriteRouter.getSprite(5, deer[1], deer[9])),                          // ears
                deer[10] != 4 ? renderSprite(spriteRouter.getSprite(6, deer[9], deer[10])) : '',    // earrings
                renderSprite(spriteRouter.getSprite(7, 0, deer[5]))                                 // eyes
            ));
        }

        bool overmouth;
        if ((deer[7] == 1 || deer[7] == 5) && (deer[8] != 5)) {
            overmouth = true;
        }

        string memory comp3 = string(abi.encodePacked(
            deer[14] != 22 ? renderSprite(spriteRouter.getSprite(8, deer[0], deer[14])) : '',       // clothes
            deer[7] != 6 ? renderSprite(spriteRouter.getSprite(9, deer[2], deer[7])) : '',          // beard
            renderSprite(spriteRouter.getSprite(10, 0, deer[8])),                                   // mouth
            overmouth ? renderSprite(spriteRouter.getSprite(9, deer[2], 5)) : ''                    // check over mouth beard style
        ));

        string memory comp4 = string(abi.encodePacked(
            renderSprite(spriteRouter.getSprite(11, deer[1], deer[11])),                            // nose
            renderSprite(spriteRouter.getSprite(12, 0, deer[12])),                                  // antlers
            deer[13] != 7 ? renderSprite(spriteRouter.getSprite(13, 0, deer[13])) : ''              // antler_accessory
        ));

        return string(abi.encodePacked(comp1, comp2, comp3, comp4));
    }

    function renderSprite(string memory sprite) internal view returns (string memory) {
        return string(abi.encodePacked(
            SVG_IMAGE_TAG,
            sprite,
            '"/>'
        ));
    }

    function formatTraits(uint8[16] memory deer) internal view returns (string memory) {
        string memory part1 = string(abi.encodePacked(
            '"attributes": [',
            '{"trait_type": "Gender", "value": "',           GENDER[deer[0]], '"},',
            '{"trait_type": "Fur", "value": "',              FUR[deer[1]], '"},',
            '{"trait_type": "Hair Color", "value": "',       HAIR_COLOR[deer[2]], '"},',
            '{"trait_type": "Hair Style", "value": "',       HAIR_STYLE[deer[3]], '"},',
            '{"trait_type": "Freckles", "value": "',         FRECKLES[deer[4]], '"},'
        ));
        string memory part2 = string(abi.encodePacked(
            '{"trait_type": "Eyes", "value": "',             EYES[deer[5]], '"},',
            '{"trait_type": "Brows", "value": "',            BROWS[deer[6]], '"},'
            '{"trait_type": "Beard", "value": "',            BEARD[deer[7]], '"},',
            '{"trait_type": "Mouth", "value": "',            MOUTH[deer[8]], '"},',
            '{"trait_type": "Ears", "value": "',             EARS[deer[9]], '"},',
            '{"trait_type": "Earrings", "value": "',         EARRINGS[deer[10]], '"},'
        ));
        string memory part3 = string(abi.encodePacked(
            '{"trait_type": "Nose", "value": "',             NOSE[deer[11]], '"},',
            '{"trait_type": "Antlers", "value": "',          ANTLERS[deer[12]], '"},',
            '{"trait_type": "Antler Accessory", "value": "', ANTLER_ACCESSORY[deer[13]], '"},',
            '{"trait_type": "Clothes", "value": "',          CLOTHES[deer[14]], '"},',
            '{"trait_type": "Background", "value": "',       BACKGROUND[deer[15]], '"}]'
        ));
        return string(abi.encodePacked(part1, part2, part3));
    }


    // OWNER STUFF

    function reveal() external onlyOwner {
        REVEALED = true;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setDAO(address dao_) external onlyOwner {
        dao = dao_;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Can't be zero address");
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner lmao");
        _;
    }


    // DAO STUFF

    function setMerkleRoot(bytes32 root) external onlyOwnerOrDAO {
        merkleRoot = root;
    }

    function turnMintOn() external onlyOwnerOrDAO {
        MINT_IS_ON = true;
    }

    function turnMintOff() external onlyOwnerOrDAO {
        MINT_IS_ON = false;
    }

    function setMintPublic() external onlyOwnerOrDAO {
        MINT_IS_PUBLIC = true;
    }

    function setMintWhitelisted() external onlyOwnerOrDAO {
        MINT_IS_PUBLIC = false;
    }

    function setPrice(uint price) external onlyOwnerOrDAO {
        MINT_PRICE = price;
    }

    function setMaxSupply(uint max_supply) external onlyOwnerOrDAO {
        MAX_SUPPLY = max_supply;
    }

    function setMaxMintPerTx(uint maxMintPerTx) external onlyOwnerOrDAO {
        MAX_MINT_PER_TX = maxMintPerTx;
    }

    function setMaxMintPerWallet(uint maxMintPerWallet) external onlyOwnerOrDAO {
        MAX_MINT_PER_WALLET = maxMintPerWallet;
    }

    function setSpriteRouter(address ISpriteRouterAddress) external onlyOwnerOrDAO {
        spriteRouter = ISpriteRouter(ISpriteRouterAddress);
    }

    function setDescription(string calldata description_) external onlyOwnerOrDAO {
        description = description_;
    }

    function setSVGHeader(string calldata SVGHeader) external onlyOwnerOrDAO {
        SVG_HEADER = SVGHeader;
    }

    function setSVGFooter(string calldata SVGFooter) external onlyOwnerOrDAO {
        SVG_FOOTER = SVGFooter;
    }

    function setSVGImageTag(string calldata imageTag) external onlyOwnerOrDAO {
        SVG_IMAGE_TAG = imageTag;
    }

    function withdrawDAO() external onlyOwnerOrDAO {
        payable(dao).transfer(address(this).balance);
    }

    modifier onlyOwnerOrDAO {
        require(msg.sender == owner || msg.sender == dao, "only owner or dao");
        _;
    }


    // HELPER FUNCTIONS

    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function uintToString(uint256 num) internal pure returns (string memory) {
        if (num == 0) {
            return "0";
        }
        uint256 temp = num;
        uint256 len;
        while (temp != 0) {
            len++;
            temp /= 10;
        }
        bytes memory strBuffer = new bytes(len);
        while (num != 0) {
            len -= 1;
            strBuffer[len] = bytes1(uint8(48 + uint256(num % 10)));
            num /= 10;
        }
        return string(strBuffer);
    }

}


/*
*     \_\_     _/_/
*         \___/
*        ~(0 0)~
*         (._.)\_________
*             \          \~
*              \  _____(  )
*               ||      ||
*               ||      ||
*
* HELLO DEER, NICE TO SEE YOU HERE :)
*/