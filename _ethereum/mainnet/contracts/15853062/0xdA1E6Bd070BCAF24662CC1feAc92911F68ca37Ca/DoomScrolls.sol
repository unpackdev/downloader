// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Base64.sol";
import "./SSTORE2.sol";

interface IWassieParts {
    function burn(uint256 tokenId) external;
}

/*-----------------------------ERRORS---------------------------------*/
error InsufficientAmountSent();
error MintInactive();
error InvalidTokensToBurn();
error NotPayee();
error NotOnFreeMintList();

contract DoomScrolls is ERC721AQueryable, ERC721ABurnable, Ownable, PaymentSplitter {
    /*-----------------------------VARIABLES------------------------------*/
    uint256 public mintPrice = 0.02 ether;
    bool public isMintActive = true;
    bool public burnWassies = true;
    address public wassiePartsAddress;
    string public baseTokenURI;
    bytes32 public merkleRoot;
    mapping(uint256 => address) public svgAttachments;

    /*-------------------------------EVENTS--------------------------------*/
    event Minted(address indexed receiver, uint256 amount);

    string[] private _scrollColors1 = [
        "#BB0000",
        "#674141",
        "#ca5d5d",
        "#6c591f",
        "#5f573f",
        "#3d5338",
        "#545e51",
        "#BB0000",
        "#1d495c",
        "#1660bb",
        "#281870",
        "#292050",
        "#312d42",
        "#484554",
        "#583830",
        "#4f1607",
        "#593960",
        "#2f5030",
        "#781f4a",
        "#670505",
        "#b94646",
        "#BB0000"
    ];
    string[] private _scrollColors2 = [
        "#FFD3AB",
        "#a9a39e",
        "#e0a87a",
        "#bb906d",
        "#858585",
        "#ab8d8d",
        "#969997",
        "#FFD3AB",
        "#a3ada6",
        "#767885",
        "#bdb4a8",
        "#bda8a8",
        "#b1a8a8",
        "#FFD3AB",
        "#bac2c0",
        "#b8b4b9"
    ];

    /*-------------------------------TRAITS--------------------------------*/
    string[][] private _seasonTexts = [
        ["it will be spring", ""],
        ["it will be summer", ""],
        ["it will be winter", ""],
        ["it will be autumn", ""],
        ["it will happen during the rainy season", ""],
        ["there will be a monsoon", ""],
        ["it will be hurricane season", ""],
        ["it will be during the Ukrainian mud season", ""],
        ["it will be allergy season", ""],
        ["it will transpire", "in the time between thanksgiving and christmas"],
        ["it will take place as the humpback whales", "migrate to warmer waters"],
        ["it will be Songkran, the Thai new year", "(when they have the big waterfight)"],
        ["it will happen during the summer festival season,", "after Coachella but before Lollapalooza"],
        ["it will be a week before comic-con", ""],
        ["it will transpire", "in the season astrologists call 'the yahoo equinox'"]
    ];

    string[][] private _timeOfDayTexts = [
        ["in the morning", ""],
        ["in the afternoon", ""],
        ["at night", ""],
        ["around 3 am", ""],
        ["right after you wake up", ""],
        ["just before dinner", ""],
        ["at high noon", ""],
        ["during magic hour", ""],
        ["at the stroke of midnight", ""],
        ["at nap time", ""],
        ["around when you typically go to the gym", ""],
        ["before you eat breakfast", ""],
        ["halfway through rush hour", ""],
        ["it will be late morning/early afternoon", ""],
        ["during your lunch break", ""]
    ];

    string[][] private _whatYoullWearTexts = [
        ["you'll be wearing a suit", ""],
        ["you'll be wearing a dress", ""],
        ["you'll be wearing clown shoes and a top hat", ""],
        ["you'll be wearing burberry's 1997 collection", ""],
        ["you'll be wearing a stained american eagle", "polo shirt that hasn't fit for years"],
        ["you'll be wearing everything but pants", ""],
        ["you'll be wearing someone else's underwear", ""],
        ["you'll be wearing the official", "tony the tiger costume (stolen)"],
        ["you'll be wearing the map of ", "Africa in body paint "],
        ["you'll be wearing your favorite jeans", ""],
        ["you'll be dressed as a movie cowboy ", ""],
        ["you'll be wearing nothing but a sarong", ""],
        ["you'll be cosplaying the Princess Zelda", ""],
        ["you'll be draped", "in the robes of an ancient priest"],
        ["you'll be wearing a pink hoodie", "that just says 'SPICY'"]
    ];

    string[][] private _chaseSceneTexts = [
        ["when you're chased by snowmobiles", "across a glacier"],
        ["when you're hunted through the jungle", "like a tiger's prey"],
        ["when you're chased", "through the food court by mall cops"],
        ["when you're followed home", "by a spooky librarian"],
        ["when you're stalked by a drone", "300 feet above"],
        ["when you're racing", "through a mountain village on skis"],
        ["when you're shot out of a cannon", ""],
        ["when you're dragged behind a mini cooper", "for six miles"],
        ["when you're crossing the Sahara by camel", ""],
        ["when you're traveling coast to coast", "by horseback"],
        ["when you're chased by ninjas", "across the rooftops of Tokyo"],
        ["when you're skydiving", "to escape the Yakuza"],
        ["when you're scaling the Burj Khalifa", "with suction cup gloves"],
        ["when you're hopelessly lost in the suburbs", ""],
        ["when you're chased from your hometown", "by angry highschoolers with pitchforks"]
    ];

    string[][] private _causeOfDeathTexts = [
        ["and thrown from the roof", "of a very tall building-"],
        ["and stabbed with a nine foot long", "decorative katana sword-"],
        ["and lowered into a vat of burning oil-", ""],
        ["and burned alive-", ""],
        ["and executed by firing squad", "of disappointed former lovers-"],
        ["and squashed beneath a falling piano-", ""],
        ["and devoured by hungry piranhas-", ""],
        ["and trampled by black friday shoppers-", ""],
        ["and roasted like a rotisserie chicken-", ""],
        ["and pass gently in your sleep-", ""],
        ["and strangled by your own intestines-", ""],
        ["and guillotine'd by cheering townsfolk-", ""],
        ["and bitten by an enormous cobra-", ""],
        ["and poisoned", "by the person you love the most-"],
        ["and buried alive-", ""]
    ];
    string[][] private _burialTexts = [
        ["your body will be burnt like a viking", ""],
        ["you will be cremated and stored", "in a cat shaped jar"],
        ["you will be mummified", ""],
        ["your body will be wrapped", "in a weighted blanket and cast into the sea"],
        ["you will be laid to rest in the family plot", ""],
        ["left in a shallow grave and forgotten", ""],
        ["your body will be embalmed and displayed", "for strangers to throw coins at"],
        ["your body loaded onto a satellite", "and blasted into space"],
        ["your body will be dissolved in acid", ""],
        ["your body will be hung", "in the town square as an example to others"],
        ["your body will be fed to bears at the zoo", ""],
        ["your body will be cast into a volcano", "as a sacrifice"],
        ["your body will be pickled", "and served at the funeral"],
        ["your body will be hidden under the floorboards", "in the abandoned house down the street"],
        ["your body will be stuffed in a trunk", "and driven into the river"]
    ];
    string[][] private _whoWillMissYouTexts = [
        ["as you're remembered fondly by all", ""],
        ["your bloodline ended;", "your name erased from history"],
        ["as you are mourned by three loving children ", ""],
        ["the IRS is still looking for you", "but that's kinda it"],
        ["your dog won't even realize you're gone", ""],
        ["as you're forgotten", "by everyone who knew you"],
        ["leaving behind a mountain", "of debt for your kids"],
        ["as you're reduced to a commemorative", "plaque on a bench"],
        ["as a wing of the new public library", "is dedicated to your memory"],
        ["as they misspell your name in the obituary", "and nobody notices"],
        ['as people say "who?"', "whenever you're brought up"],
        ["as you're remembered", "by all the friends you still owe money to"],
        ["as your children fight", "over your estate in the absence of a will"],
        ["as junk mail continues", "to be delivered in your name"],
        ["as you become the controversial", '"main character" on twitter for a day']
    ];

    string[] private _seasonTraits = [
        "spring",
        "summer",
        "winter",
        "autumn",
        "rainy season",
        "monsoon",
        "hurricane season",
        "Ukrainian mud season",
        "Allergy season",
        "Between Thanksgiving and Christmas",
        "Humpback whales migration",
        "Songkran",
        "After Coachella but before Lollapalooza",
        "A week before comic-con",
        "'The Yahoo equinox'"
    ];
    string[] private _timeOfDayTraits = [
        "Morning",
        "Afternoon",
        "Night",
        "Around 3 am",
        "After you wake up",
        "Before dinner",
        "High noon",
        "Magic hour",
        "Stroke of midnight",
        "Nap time",
        "Gym",
        "Breakfast",
        "Rush hour",
        "Late morning/early afternoon",
        "Lunch break"
    ];
    string[] private _whatYoullWearTraits = [
        "Suit",
        "Dress",
        "Clown shoes and a top hat",
        "Burberry's 1997 collection",
        "Stained American Eagle polo shirt",
        "Everything but pants",
        "Someone else's underwear",
        "Tony the tiger costume (stolen)",
        "Map of Africa in body paint ",
        "Favorite jeans",
        "Movie cowboy ",
        "Sarong",
        "Princess Zelda cosplay",
        "Robes of an ancient priest",
        "'SPICY' pink hoodie"
    ];
    string[] private _chaseSceneTraits = [
        "chased by snowmobiles across a glacier",
        "hunted through the jungle like a tiger's prey",
        "chased through the food court by mall cops",
        "followed home by a spooky librarian",
        "stalked by a drone 300 feet above",
        "racing through a mountain village on skis",
        "shot out of a cannon",
        "dragged behind a mini cooper for six miles",
        "crossing the Sahara by camel",
        "traveling coast to coast by horseback",
        "chased by ninjas across the rooftops of Tokyo",
        "skydiving to escape the Yakuza",
        "scaling the Burj Khalifa with suction cup gloves",
        "hopelessly lost in the suburbs",
        "chased from your hometown by angry highschoolers with pitchforks"
    ];
    string[] private _causeOfDeathTraits = [
        "thrown from the roof of a very tall building-",
        "stabbed with a nine foot long decorative katana sword-",
        "lowered into a vat of burning oil-",
        "burned alive-",
        "executed by firing squad of disappointed former lovers-",
        "squashed beneath a falling piano-",
        "devoured by hungry piranhas-",
        "trampled by black friday shoppers-",
        "roasted like a rotisserie chicken-",
        "pass gently in your sleep-",
        "strangled by your own intestines-",
        "guillotine'd by cheering townsfolk-",
        "bitten by an enormous cobra-",
        "poisoned by the person you love the most-",
        "buried alive-"
    ];
    string[] private _burialTraits = [
        "body will be burnt like a viking",
        "cremated and stored in a cat shaped jar",
        "mummified",
        "body will be wrapped in a weighted blanket and cast into the sea",
        "laid to rest in the family plot",
        "left in a shallow grave and forgotten",
        "body will be embalmed and displayed for strangers to throw coins at",
        "body loaded onto a satellite and blasted into space",
        "body will be dissolved in acid",
        "body will be hung in the town square as an example to others",
        "body will be fed to bears at the zoo",
        "body will be cast into a volcano as a sacrifice",
        "body will be pickled and served at the funeral",
        "body will be hidden under the floorboards in the abandoned house down the street",
        "body will be stuffed in a trunk and driven into the river"
    ];
    string[] private _whoWillMissYouTraits = [
        "as you're remembered fondly by all",
        "your bloodline ended; your name erased from history",
        "as you are mourned by three loving children ",
        "The IRS",
        "Not even your dog",
        "as you're forgotten by everyone who knew you",
        "leaving behind a mountain of debt for your kids",
        "as you're reduced to a commemorative plaque on a bench",
        "as a wing of the new public library is dedicated to your memory",
        "as they misspell your name in the obituary and nobody notices",
        "Who?",
        "all the friends you still owe money to",
        "as your children fight over your estate in the absence of a will",
        "as junk mail continues to be delivered in your name",
        "Main character"
    ];

    /*--------------------------CONSTRUCTOR-------------------------------*/
    constructor(
        address _wassiePartsAddress,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721A("DoomScrolls", "DOOMSCROLLS") PaymentSplitter(payees, shares) {
        wassiePartsAddress = _wassiePartsAddress;
    }

    /*--------------------------ON-CHAIN GENERATION----------------------------*/
    function getRandomInt(string memory input) internal pure returns (uint256) {
        // Pseudo-random integer
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getRandomIndex(
        uint256 tokenId,
        string[][] memory traits,
        string memory key
    ) internal pure returns (uint256) {
        uint256 randomInt = getRandomInt(string(abi.encodePacked(key, _toString(tokenId))));
        return randomInt % traits.length;
    }

    function getRandomScrollColor(uint256 tokenId, string[] memory _arrayOfColors) internal pure returns (string memory) {
        uint256 randomInt = getRandomInt(string(abi.encodePacked("scrollColor", _toString(tokenId))));
        return _arrayOfColors[randomInt % _arrayOfColors.length];
    }

    function getAttributes(string[7] memory traits) internal pure returns (string memory) {
        string memory attributes;

        attributes = string(
            abi.encodePacked(
                '[{"trait_type": "Season", "value": "',
                traits[0],
                '"},',
                '{"trait_type": "Time of Day", "value": "',
                traits[1],
                '"},',
                '{"trait_type": "What You\'ll wear", "value": "',
                traits[2],
                '"},',
                '{"trait_type": "Chase Scene", "value": "',
                traits[3],
                '"},'
            )
        );
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type": "Cause of Death", "value": "',
                traits[4],
                '"},',
                '{"trait_type": "Burial", "value": "',
                traits[5],
                '"},',
                '{"trait_type": "Who Will Miss You", "value": "',
                traits[6],
                '"}]'
            )
        );
        return attributes;
    }

    function getSpacer(uint256 xOffset, uint256 yOffset) internal pure returns (string memory) {
        // Get HTML strings with x and y spacing, and font
        return string.concat('</text><text x="', _toString(xOffset), '" y= "', _toString(yOffset), '" class="base">');
    }

    function getLine(
        string memory line,
        uint256 xOffset,
        uint256 yOffset
    ) internal pure returns (string memory) {
        return string.concat('<tspan x="', _toString(xOffset), '" y="', _toString(yOffset), '" class="line">', line, "</tspan>");
    }

    function addLine(
        string[][] storage theArray,
        uint256 theIndex,
        uint256 yOffset
    ) internal view returns (string memory) {
        string memory line = getLine(theArray[theIndex][0], 0, yOffset);
        yOffset += 84;
        if (bytes(theArray[theIndex][1]).length > 0) {
            line = string(abi.encodePacked(line, getLine(theArray[theIndex][1], 0, yOffset)));
            yOffset += 84;
        }
        return line;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 yOffset = 0;
        uint256 lineDistance = 84;

        string[7] memory texts;
        string[7] memory traits;

        // Get random scroll traits
        uint256 randomIndex = getRandomIndex(tokenId, _seasonTexts, "SEASON");
        texts[0] = addLine(_seasonTexts, randomIndex, yOffset);
        traits[0] = _seasonTraits[randomIndex];
        yOffset += lineDistance;
        if (bytes(_seasonTexts[randomIndex][1]).length > 0) yOffset += lineDistance;

        randomIndex = getRandomIndex(tokenId, _timeOfDayTexts, "TIME OF DAY");
        texts[1] = addLine(_timeOfDayTexts, randomIndex, yOffset);
        traits[1] = _timeOfDayTraits[randomIndex];
        yOffset += lineDistance;
        if (bytes(_timeOfDayTexts[randomIndex][1]).length > 0) yOffset += lineDistance;

        randomIndex = getRandomIndex(tokenId, _whatYoullWearTexts, "WHAT YOU'LL WEAR");
        texts[2] = addLine(_whatYoullWearTexts, randomIndex, yOffset);
        traits[2] = _whatYoullWearTraits[randomIndex];
        yOffset += lineDistance;
        if (bytes(_whatYoullWearTexts[randomIndex][1]).length > 0) yOffset += lineDistance;

        randomIndex = getRandomIndex(tokenId, _chaseSceneTexts, "CHASE SCENE");
        texts[3] = addLine(_chaseSceneTexts, randomIndex, yOffset);
        traits[3] = _chaseSceneTraits[randomIndex];
        yOffset += lineDistance;
        if (bytes(_chaseSceneTexts[randomIndex][1]).length > 0) yOffset += lineDistance;

        randomIndex = getRandomIndex(tokenId, _causeOfDeathTexts, "CAUSE OF DEATH");
        texts[4] = addLine(_causeOfDeathTexts, randomIndex, yOffset);
        traits[4] = _causeOfDeathTraits[randomIndex];
        yOffset += lineDistance;
        if (bytes(_causeOfDeathTexts[randomIndex][1]).length > 0) yOffset += lineDistance;

        randomIndex = getRandomIndex(tokenId, _burialTexts, "BURIAL");
        texts[5] = addLine(_burialTexts, randomIndex, yOffset);
        traits[5] = _burialTraits[randomIndex];
        yOffset += lineDistance;
        if (bytes(_burialTexts[randomIndex][1]).length > 0) yOffset += lineDistance;

        randomIndex = getRandomIndex(tokenId, _whoWillMissYouTexts, "WHO WILL MISS YOU");
        texts[6] = addLine(_whoWillMissYouTexts, randomIndex, yOffset);

        traits[6] = _whoWillMissYouTraits[randomIndex];
        yOffset += lineDistance;
        if (bytes(_whoWillMissYouTexts[randomIndex][1]).length > 0) yOffset += lineDistance;

        string memory attributes = getAttributes(traits);

        string memory completeText = string(abi.encodePacked(texts[0], texts[1], texts[2], texts[3], texts[4], texts[5], texts[6]));

        // Concatenation needs to be split up because there's a limit to the number of inputs
        string memory output = string(
            abi.encodePacked(
                string(SSTORE2.read(svgAttachments[2])), // SVG of the scroll
                string(SSTORE2.read(svgAttachments[3])), // SVG of the scroll
                string(SSTORE2.read(svgAttachments[4])), // SVG of the blood splatters
                '<text transform="matrix(1 0 0 1 330 450)">', // SVG of the text
                completeText
            )
        );

        output = string(abi.encodePacked(output, '</text><rect x="1895.6" y="982.6" class="st7" width="2.2" height="0"/>'));

        output = string(
            abi.encodePacked(
                output,
                "<style>",
                "@font-face{"
                "font-family:Alagard;"
                "font-style:normal;"
                "src:url(",
                string(SSTORE2.read(svgAttachments[0])), // Read font SVG (file split into 2)
                string(SSTORE2.read(svgAttachments[1])), // Read font SVG (second half)
                ") format('truetype')"
                "}",
                ".st1{fill:",
                string(getRandomScrollColor(tokenId, _scrollColors1)),
                "}",
                ".st0{fill:",
                string(getRandomScrollColor(tokenId, _scrollColors2)),
                "}",
                "</style>"
                "</svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Doom Scroll #',
                        _toString(tokenId),
                        '", "description": "Doom Scrolls are blockchain prophecies, divined by an evil Tubby Cat, brewed with powdered wolfsbane and the body of a Wassie (diced). Fully on-chain, immutable, visions of your demise. Death is the utility, beware!!", "attributes":',
                        attributes,
                        ', "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    /*--------------------------MINT FUNCTIONS----------------------------*/

    function mint(uint256 nMints, uint256[] calldata tokenIdsToBurn) external payable {
        if (!isMintActive) revert MintInactive();
        if (msg.value != mintPrice * nMints) revert InsufficientAmountSent();
        if (burnWassies) {
            if (tokenIdsToBurn.length == 0) revert InvalidTokensToBurn();

            unchecked {
                for (uint256 i = 0; i < nMints; ++i) {
                    IWassieParts(wassiePartsAddress).burn(tokenIdsToBurn[i]);
                }
            }
        }
        _safeMint(msg.sender, nMints);
    }

    function mintFreeClaim(
        uint256 nMints,
        uint256[] calldata tokenIdsToBurn,
        bytes32[] calldata _proof
    ) external {
        if (!isMintActive) revert MintInactive();
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, merkleRoot, node)) revert NotOnFreeMintList();
        if (burnWassies) {
            if (tokenIdsToBurn.length == 0) revert InvalidTokensToBurn();
            unchecked {
                for (uint256 i = 0; i < nMints; ++i) {
                    IWassieParts(wassiePartsAddress).burn(tokenIdsToBurn[i]);
                }
            }
        }
        _safeMint(msg.sender, nMints);
    }

    function mintAirdrop(address recipient, uint256 nMints) external onlyOwner {
        _safeMint(recipient, nMints);
    }

    function mintReserve(uint256 nMints) external onlyOwner {
        _safeMint(msg.sender, nMints);
    }

    /*-------------------------------ADMIN--------------------------------*/

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function toggleMintActive() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function toggleBurnWassies() external onlyOwner {
        burnWassies = !burnWassies;
    }

    function saveAttachment(uint256 index, string calldata fileContent) public onlyOwner {
        svgAttachments[index] = SSTORE2.write(bytes(fileContent));
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function release(address payable account) public override {
        if (msg.sender != account && msg.sender != owner()) revert NotPayee();
        super.release(account);
    }
}
