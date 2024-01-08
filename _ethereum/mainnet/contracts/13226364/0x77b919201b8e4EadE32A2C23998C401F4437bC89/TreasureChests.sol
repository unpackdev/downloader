// SPDX-License-Identifier: MIT
// @author 0xski.eth

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

import "./Base64.sol";

// Interface to the original Loot Contract.
interface LootInterface {
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    function getWeapon(uint256 tokenId) external view returns (string memory);

    function getChest(uint256 tokenId) external view returns (string memory);

    function getHead(uint256 tokenId) external view returns (string memory);

    function getWaist(uint256 tokenId) external view returns (string memory);

    function getFoot(uint256 tokenId) external view returns (string memory);

    function getHand(uint256 tokenId) external view returns (string memory);

    function getNeck(uint256 tokenId) external view returns (string memory);

    function getRing(uint256 tokenId) external view returns (string memory);
}

interface SytheticLootInterface {
    function getWeapon(address walletAddress)
        external
        view
        returns (string memory);

    function getChest(address walletAddress)
        external
        view
        returns (string memory);

    function getHead(address walletAddress)
        external
        view
        returns (string memory);

    function getWaist(address walletAddress)
        external
        view
        returns (string memory);

    function getFoot(address walletAddress)
        external
        view
        returns (string memory);

    function getHand(address walletAddress)
        external
        view
        returns (string memory);

    function getNeck(address walletAddress)
        external
        view
        returns (string memory);

    function getRing(address walletAddress)
        external
        view
        returns (string memory);
}

library Svg {
    /**
     * @dev Returns a <line> element giving a straight line between
     the two points specified by (`x1`,`y1`), (`x2`, `y2`). Color can be
     specified with `color` string and `roundLine` is a boolean flag to 
     make the corners of the line rounded.
     */
    function getLine(
        uint256 x1,
        uint256 x2,
        uint256 y1,
        uint256 y2,
        string memory color,
        bool roundLine
    ) public pure returns (string memory) {
        string[11] memory parts;

        parts[0] = '<line x1="';
        parts[1] = Strings.toString(x1);
        parts[2] = '" x2="';
        parts[3] = Strings.toString(x2);
        parts[4] = '" y1="';
        parts[5] = Strings.toString(y1);
        parts[6] = '" y2="';
        parts[7] = Strings.toString(y2);
        parts[8] = '" stroke="';
        parts[9] = color;
        if (roundLine) {
            parts[10] = '" stroke-width="2" stroke-linecap="round"/>';
        } else {
            parts[10] = '" stroke-width="2" stroke-linecap="square"/>';
        }

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(abi.encodePacked(output, parts[9], parts[10]));
        return output;
    }

    /**
     * @dev Returns a <path> element giving a filled curve. The curve is
     specified by start x,y coordinates, end x,y coordinates and a control
     point that controls the curve.
     */
    function getFilledCurve(
        uint256 startX,
        uint256 startY,
        uint256 controlX,
        uint256 controlY,
        uint256 endX,
        uint256 endY
    ) public pure returns (string memory) {
        string[17] memory parts;
        string memory fillColor = "white";

        parts[0] = '<path d="M ';
        parts[1] = Strings.toString(startX);
        parts[2] = " ";
        parts[3] = Strings.toString(startY);
        parts[4] = " Q ";
        parts[5] = Strings.toString(controlX);
        parts[6] = " ";
        parts[7] = Strings.toString(controlY);
        parts[8] = " ";
        parts[9] = Strings.toString(endX);
        parts[10] = " ";
        parts[11] = Strings.toString(endY);
        parts[12] = '" stroke="';
        parts[13] = fillColor;
        parts[14] = '" fill="';
        parts[15] = fillColor;
        parts[16] = '" stroke-linecap="round"/>';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        return output;
    }

    /**
     * @dev Returns a <text> element opening position at `atX` and `atY`
     coordinates with CSS class name specified by `className`.
     */
    function getText(
        uint256 atX,
        uint256 atY,
        string memory className
    ) public pure returns (string memory) {
        string[7] memory parts;
        parts[0] = '<text x="';
        parts[1] = Strings.toString(atX);
        parts[2] = '" y="';
        parts[3] = Strings.toString(atY);
        parts[4] = '" class="';
        parts[5] = className;
        parts[6] = '">';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );
        return output;
    }

    /**
     * @dev Adds the chest to the SVG. Based on whether the treasure
     has been opened, this will be an opened or closed treasure
     chest rendering.
     */
    function __svgAddTreasureChest(bool isOpened)
        public
        pure
        returns (string memory)
    {
        string[30] memory parts;
        string memory chestColor = "white";

        parts[0] = getLine(125, 225, 250, 250, chestColor, true);
        parts[1] = getLine(125, 225, 300, 300, chestColor, true);
        parts[2] = getLine(125, 125, 250, 300, chestColor, true);
        parts[3] = getLine(225, 225, 250, 300, chestColor, true);

        // Corners of chest.
        parts[4] = getLine(125, 135, 290, 300, chestColor, true);
        parts[5] = getLine(225, 215, 290, 300, chestColor, true);

        // Top of chest.
        uint256 chestTopY;
        if (isOpened) {
            chestTopY = 225;
        } else {
            chestTopY = 250;
        }

        parts[6] = getLine(125, 225, chestTopY, chestTopY, chestColor, true);
        parts[7] = getLine(
            125,
            125,
            chestTopY,
            chestTopY - 15,
            chestColor,
            true
        );
        parts[8] = getLine(
            225,
            225,
            chestTopY,
            chestTopY - 15,
            chestColor,
            true
        );
        parts[9] = getLine(
            125,
            225,
            chestTopY - 15,
            chestTopY - 15,
            chestColor,
            true
        );

        if (isOpened) {
            // Connectors from top to bottom.
            parts[10] = getLine(125, 130, 225, 250, chestColor, true);
            parts[11] = getLine(225, 220, 225, 250, chestColor, true);
        }

        // Bottom notch.
        parts[12] = getLine(170, 170, 250, 265, chestColor, true);
        parts[13] = getLine(180, 180, 250, 265, chestColor, true);
        parts[14] = getLine(170, 180, 265, 265, chestColor, true);

        // Top notch.
        parts[15] = getLine(
            170,
            170,
            chestTopY,
            chestTopY - 5,
            chestColor,
            true
        );
        parts[16] = getLine(
            180,
            180,
            chestTopY,
            chestTopY - 5,
            chestColor,
            true
        );
        parts[17] = getLine(
            170,
            180,
            chestTopY - 5,
            chestTopY - 5,
            chestColor,
            true
        );

        if (isOpened) {
            // Top lock.
            parts[18] = getLine(172, 172, 225, 230, chestColor, true);
            parts[19] = getLine(178, 178, 225, 230, chestColor, true);
            parts[20] = getLine(172, 178, 230, 230, chestColor, true);
        }

        // Bottom lock
        parts[21] = getLine(175, 175, 256, 258, chestColor, true);

        // Top corners.
        parts[22] = getLine(
            135,
            125,
            chestTopY - 15,
            chestTopY - 5,
            chestColor,
            true
        );
        parts[23] = getLine(
            215,
            225,
            chestTopY - 15,
            chestTopY - 5,
            chestColor,
            true
        );

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );
        output = string(abi.encodePacked(output, parts[25], parts[26]));
        return output;
    }

    /**
     * @dev Adds a plaque to the SVG for treasures claimed using a Loot bag.
     */
    function __svgAddTreasureChestPlaque() public pure returns (string memory) {
        string[10] memory parts;
        parts[
            0
        ] = '<rect x="165" y="278" width="20" height="10" stroke="white" stroke-width="1" fill="none" />';
        parts[
            1
        ] = '<circle cx="167" cy="280" r="0.5" stroke="white" fill="white" stroke-width="0.25" />';
        parts[
            2
        ] = '<circle cx="167" cy="286" r="0.5" stroke="white" fill="white" stroke-width="0.25" />';
        parts[
            3
        ] = '<circle cx="183" cy="280" r="0.5" stroke="white" fill="white" stroke-width="0.25" />';
        parts[
            4
        ] = '<circle cx="183" cy="286" r="0.5" stroke="white" fill="white" stroke-width="0.25" />';
        parts[5] = getText(171, 284, "small");
        parts[6] = "Loot";
        parts[7] = "</text>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7]
            )
        );
        return output;
    }

    /**
     * @dev Adds the treasure contents to the SVG based on a randomly picked
     composition (either 1, 2x, or 3x). Probabilities are 50% for 1x, 30% for
     2x and 20% for 3x.
     */
    function __svgAddTreasureContents(uint256 randComposition)
        public
        pure
        returns (string memory)
    {
        string[3] memory parts;

        if (randComposition >= 50) {
            parts[0] = getFilledCurve(130, 249, 175, 240, 220, 249);
        } else if (randComposition >= 20) {
            parts[0] = getFilledCurve(130, 249, 152, 240, 175, 249);
            parts[1] = getFilledCurve(175, 249, 197, 240, 220, 249);
        } else {
            parts[0] = getFilledCurve(130, 249, 145, 240, 160, 249);
            parts[1] = getFilledCurve(160, 249, 175, 240, 190, 249);
            parts[2] = getFilledCurve(190, 249, 205, 240, 220, 249);
        }

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );
        return output;
    }

    /**
     * @dev Adds the text for the treasure contents description.
     */
    function __svgAddTreasureContentsDescription(
        uint256 textX,
        uint256 textY,
        string memory description
    ) public pure returns (string memory) {
        string[3] memory parts;
        parts[0] = getText(textX, textY, "base");
        parts[1] = description;
        parts[2] = "</text>";

        return string(abi.encodePacked(parts[0], parts[1], parts[2]));
    }

    /**
     * @dev Adds the text for the treasure location.
     */
    function __svgAddLocation(
        uint256 textX,
        uint256 textY,
        uint256 treasureX,
        uint256 treasureY
    ) public pure returns (string memory) {
        string[7] memory parts;
        parts[0] = getText(textX, textY, "base");
        parts[1] = "Found at: (";
        parts[2] = Strings.toString(treasureX);
        parts[3] = ", ";
        parts[4] = Strings.toString(treasureY);
        parts[5] = ")";
        parts[6] = "</text>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );
        return output;
    }

    /**
     * @dev Adds the text for the random item of Loot or
     Synthetic loot that is recorded when the treasure is minted.
     */
    function __svgAddWearingItem(
        uint256 textX,
        uint256 textY,
        string memory whileWearing
    ) public pure returns (string memory) {
        string[4] memory parts;
        parts[0] = getText(textX, textY, "base");
        parts[1] = "Wearing: ";
        parts[2] = whileWearing;
        parts[3] = "</text>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3])
        );
        return output;
    }

    /**
     * @dev Adds the text for the Loot bag that was used to claim
     the treasure (if any). This is only the case when the treasure
     is claimed with 'mintWithLoot'.
     */
    function __svgAddLootBagRecord(
        uint256 textX,
        uint256 textY,
        uint256 lootBagId
    ) public pure returns (string memory) {
        string[4] memory parts;
        parts[0] = getText(textX, textY, "base");
        parts[1] = "Carrying Loot: Bag #";
        parts[2] = Strings.toString(lootBagId);
        parts[3] = "</text>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3])
        );
        return output;
    }

    /**
     * @dev Adds the text for the weight of the treasure.
     */
    function __svgAddTreasureWeight(
        uint256 textX,
        uint256 textY,
        uint256 weight
    ) public pure returns (string memory) {
        string[5] memory parts;

        parts[0] = getText(textX, textY, "base");
        parts[1] = "Weight: ";
        parts[2] = Strings.toString(weight);
        parts[3] = " kg";
        parts[4] = "</text>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
        );
        return output;
    }

    /**
     * @dev Returns the opening tag of an SVG with some high level properties
     specified.
     */
    function __svgAddBegin() public pure returns (string memory) {
        return
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; } .small {fill: white; font-size: 4px;}</style><rect width="100%" height="100%" fill="black" />';
    }
}

contract TreasureChests is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    // Reference to the 'Loot' contract.
    address private lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    LootInterface private lootContract = LootInterface(lootAddress);

    // Reference to the 'Synthetic Loot' contract.
    address private syntheticLootAddress =
        0x869Ad3Dfb0F9ACB9094BA85228008981BE6DBddE;
    SytheticLootInterface private syntheticLootContract =
        SytheticLootInterface(syntheticLootAddress);

    // Keeping track of which addresses claimed the Treasure (either with
    // 'regular' mint or with Loot).
    mapping(address => bool) private claimedAddresses;

    // Keeping track which treasure locations have been discovered. We hash
    // the (x, y) coordinates and store here.
    mapping(bytes32 => bool) private hasLocationBeenDiscovered;

    // State to keep track of Treasure properties.
    // 1. Whether the treasure has been opened.
    // 2. Where the treasure is located (depends on address minting).
    // 3. Random Synthetic Loot or Loot item recorded when minting
    // 4. Record of which Loot was used to claim treasure if minting
    //    with Loot.
    mapping(uint256 => bool) private isTreasureOpened;
    mapping(uint256 => uint256) private discoveredWithLoot;
    mapping(uint256 => string) private whileWearing;
    mapping(uint256 => bytes) private coordinates;

    // Amount of Ether an account has to send to open the treasure.
    uint256 public constant openTreasurePrice = 20000000000000000; // 0.02 ETH
    uint256 public constant treasureMapSize = 1024;

    constructor() ERC721("Treasure Chests", "CHESTS") {}

    function totalSupply() public view override returns (uint256) {
        return _tokenIds.current();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Function to get a random uint from `input` akin to one in
     dhof's Loot contract.
     */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    modifier oncePerAddress() {
        // This address has already been used to claim a treasure.
        require(
            !claimedAddresses[msg.sender],
            "This address has already been used to claim a treasure"
        );
        _;
    }

    modifier canOpenAtMint() {
        // Send only 0 ETH to mint treasure closed or 0.02 ETH to open the treasure.
        require(
            msg.value == 0 || msg.value == openTreasurePrice,
            "Send only 0 ETH to mint treasure closed or 0.02 ETH to open the treasure"
        );
        _;
    }

    /**
     * @dev 'with Loot' way to claim a treasure that requires the adventurer
     to have a Loot bag that they can specify as the one to use when claiming
     the treasure.
     */
    function mintWithLoot(
        uint256 lootBagId,
        uint256 treasureX,
        uint256 treasureY
    ) public payable oncePerAddress canOpenAtMint {
        require(
            lootContract.ownerOf(lootBagId) == msg.sender,
            "Sender not owner of provided Loot"
        );

        // First verify that a treasure has not yet been discovered at
        // these coordinates and also that the coordinates that the
        // sender is trying to discover the treasure at are correctly
        // derived from the sender's address.
        bytes32 coordHash = keccak256(
            abi.encodePacked(treasureX, ",", treasureY)
        );
        __verifyTreasureCoordinates(treasureX, treasureY, coordHash);

        // Update the state by
        // 1. Marking the (x, y) location as discovered.
        // 2. Marking the address as having claimed a treasure.
        hasLocationBeenDiscovered[coordHash] = true;
        claimedAddresses[msg.sender] = true;

        // Get whatever the next token ID is.
        _tokenIds.increment();
        uint256 newTreasureId = _tokenIds.current();

        // Update metadata for this token at mint:
        // 1. Since this is a 'withLoot' mint, pick a random Loot
        //    item that the adventurer uses to claim the treasure and store
        //    it in the state.
        // 2. Record which Loot bag was used to claim this treasure.
        // 3. Store the coordinates of this treasure.
        // 4. If the adventurer has chosen to open treasure,
        //    record that in the state.

        // Uses the actual Loot bag to pick a random item.
        whileWearing[newTreasureId] = getRandomLootItem(msg.sender, lootBagId);
        discoveredWithLoot[newTreasureId] = lootBagId;
        coordinates[newTreasureId] = abi.encode(treasureX, ",", treasureY);
        if (msg.value == openTreasurePrice) {
            isTreasureOpened[newTreasureId] = true;
        }

        _mint(msg.sender, newTreasureId);
    }

    /**
     * @dev 'Regular' way to claim a treasure that any adventurer with
     an ethereum address can use.
     */
    function mint(uint256 treasureX, uint256 treasureY)
        public
        payable
        oncePerAddress
        canOpenAtMint
        nonReentrant
    {
        // First verify that a treasure has not yet been discovered at
        // these coordinates and also that the coordinates that the
        // sender is trying to discover the treasure at are correctly
        // derived from the sender's address.
        bytes32 coordHash = keccak256(
            abi.encodePacked(treasureX, ",", treasureY)
        );
        __verifyTreasureCoordinates(treasureX, treasureY, coordHash);

        // Update the state by
        // 1. Marking the (x, y) location as discovered.
        // 2. Marking the address as having claimed a treasure.
        hasLocationBeenDiscovered[coordHash] = true;
        claimedAddresses[msg.sender] = true;

        // Get whatever the next token ID is.
        _tokenIds.increment();
        uint256 newTreasureId = _tokenIds.current();

        // Update metadata for this token at mint:
        // 1. Since this is a 'regular' mint, pick a random Synthetic Loot
        //    item that the adventurer uses to claim the treasure and store
        //    it in the state.
        // 2. Store the coordinates of this treasure.
        // 3. If the adventurer has chosen to open treasure,
        //    record that in the state.

        whileWearing[newTreasureId] = getRandomSyntheticLootItem(msg.sender);
        coordinates[newTreasureId] = abi.encode(treasureX, ",", treasureY);
        if (msg.value == openTreasurePrice) {
            isTreasureOpened[newTreasureId] = true;
        }

        _mint(msg.sender, newTreasureId);
    }

    /**
     * @dev If the treasure was not opened at mint, can open it by calling
     this function and sending the same small fee.
     */
    function openTreasure(uint256 tokenId) public payable nonReentrant {
        require(
            msg.value == openTreasurePrice,
            "Fee to the goldsmith to open a treasure is 0.02 ETH"
        );
        require(
            tokenId > 0 && tokenId <= _tokenIds.current(),
            "Token ID invalid"
        );
        require(ownerOf(tokenId) == msg.sender, "Not owner of treasure");
        require(!isTreasureOpened[tokenId], "Treasure already opened");

        isTreasureOpened[tokenId] = true;
    }

    /**
     * @dev Verifies the coordinates of the treasure which are coming as function
     call arguments. Checks that the coordinates are correctly derived from the 
     sender's address and checks to make sure that the treasure at the given
     coordinates has not yet been discovered.
     */
    function __verifyTreasureCoordinates(
        uint256 treasureX,
        uint256 treasureY,
        bytes32 coordHash
    ) private view {
        uint256 computedTreasureX = random(
            string(abi.encodePacked(msg.sender, "x"))
        ) % treasureMapSize;
        uint256 computedTreasureY = random(
            string(abi.encodePacked(msg.sender, "y"))
        ) % treasureMapSize;

        // Treasure x coordinate does not match
        require(
            computedTreasureX == treasureX,
            "Treasure x coordinate does not match"
        );
        // Treasure y coordinate does not match
        require(
            computedTreasureY == treasureY,
            "Treasure y coordinate does not match"
        );
        // Treasure at the provided x, y coordinates has already been discovered
        require(!hasLocationBeenDiscovered[coordHash]);
    }

    /**
     * @dev Returns the weight of a treasure.
     */
    function getTreasureWeight(uint256 tokenId) private pure returns (uint256) {
        return
            random(
                string(abi.encodePacked("WEIGHT", Strings.toString(tokenId)))
            ).mod(100).add(1);
    }

    /**
     * @dev Returns the metal of a given treasure along with a multiplier (if any) based on
     the random composition (2x or 3x). Only called if the treasure is opened.
     */
    function getTreasureMetal(
        uint256 tokenId,
        uint256 treasureX,
        uint256 treasureY
    ) private pure returns (string memory) {
        uint256 randMetal = random(
            string(
                abi.encodePacked(
                    "METAL",
                    treasureX,
                    treasureY,
                    Strings.toString(tokenId)
                )
            )
        ).mod(101);

        // Distribution over 0 - 100.
        string memory metal;
        if (randMetal == 100) {
            metal = "Rhodium";
        } else if (randMetal >= 95) {
            metal = "Platinum";
        } else if (randMetal >= 80) {
            metal = "Gold";
        } else if (randMetal >= 50) {
            metal = "Silver";
        } else {
            metal = "Bronze";
        }

        // Get the composition for the treasure here in order to
        // display it correctly with the metal.
        uint256 randComposition = __getRandomTreasureComposition(
            tokenId,
            treasureX,
            treasureY
        );
        if (randComposition >= 50) {
            return metal;
        } else if (randComposition >= 20) {
            return string(abi.encodePacked("2x", " ", metal));
        } else {
            return string(abi.encodePacked("3x", " ", metal));
        }
    }

    /**
     * @dev Returns a string for the special item contained in the
     treasure. If none, returns empty string.
     */
    function getTreasureSpecialItem(
        uint256 tokenId,
        uint256 treasureX,
        uint256 treasureY
    ) private pure returns (string memory) {
        uint256 special = random(
            string(
                abi.encodePacked(
                    "SPECIAL",
                    treasureX,
                    treasureY,
                    Strings.toString(tokenId)
                )
            )
        ).mod(250);

        // Some rare treasures.
        if (special == 66) {
            return "Sacred Texts";
        }
        if (special == 0) {
            return "Map to Blackbeard's Treasure";
        }
        if (special == 1) {
            return "Ancient Coin";
        }
        if (special == 7) {
            return "Note to a Byzantine General";
        }
        return "";
    }

    /**
     * @dev Returns a random number for a given treasure which is used to
     determine the 'composition' of the treasure. Only called if the treasure
     is opened.
     */
    function __getRandomTreasureComposition(
        uint256 tokenId,
        uint256 treasureX,
        uint256 treasureY
    ) private pure returns (uint256) {
        return
            random(
                string(
                    abi.encodePacked(
                        "COMPOSITION",
                        treasureX,
                        treasureY,
                        Strings.toString(tokenId)
                    )
                )
            ).mod(100);
    }

    /**
     * @dev Returns a composed description of a given treasure. Only called if 
     the treasure is opened.
     */
    function getTreasureContentsDescription(
        uint256 tokenId,
        uint256 treasureX,
        uint256 treasureY
    ) private pure returns (string memory) {
        string[2] memory parts;

        // Either 'Bronze', 'Silver', 'Gold', etc. along with optional
        // multiplier.
        parts[0] = getTreasureMetal(tokenId, treasureX, treasureY);

        // Get a special item (if any).
        string memory specialItem = getTreasureSpecialItem(
            tokenId,
            treasureX,
            treasureY
        );
        if (
            keccak256(abi.encodePacked(specialItem)) !=
            keccak256(abi.encodePacked(""))
        ) {
            parts[1] = string(abi.encodePacked(" + ", specialItem));
        }

        string memory description = string(
            abi.encodePacked(parts[0], parts[1])
        );
        return description;
    }

    /**
     * @dev Returns a string in JSON format for the attributes of the given
     treasure.
     */
    function buildAttributesJSON(
        uint256 tokenId,
        uint256 treasureX,
        uint256 treasureY
    ) private view returns (string memory) {
        string[15] memory parts;
        parts[0] = '[{"trait_type": "Opened", "value": "';
        parts[1] = isTreasureOpened[tokenId] ? "Yes" : "No";
        parts[2] = '"}, {"trait_type": "Weight", "value": "';
        parts[3] = Strings.toString(getTreasureWeight(tokenId));
        parts[4] = '"}, ';
        // These should only be added if the treasure is opened.
        if (isTreasureOpened[tokenId]) {
            parts[5] = '{"trait_type": "Metal", "value": "';
            parts[6] = getTreasureMetal(tokenId, treasureX, treasureY);
            parts[7] = '"}, {"trait_type": "Special Item", "value": "';
            string memory specialItem = getTreasureSpecialItem(
                tokenId,
                treasureX,
                treasureY
            );
            if (
                keccak256(abi.encodePacked(specialItem)) ==
                keccak256(abi.encodePacked(""))
            ) {
                parts[8] = "None";
            } else {
                parts[8] = specialItem;
            }
            parts[9] = '"}, ';
        }
        parts[10] = '{"trait_type": "Claimed with Loot", "value": "';
        parts[11] = discoveredWithLoot[tokenId] == 0
            ? "None"
            : string(
                abi.encodePacked(
                    "Bag #",
                    Strings.toString(discoveredWithLoot[tokenId])
                )
            );
        parts[12] = '"}, {"trait_type": "Wearing", "value": "';
        parts[13] = whileWearing[tokenId];
        parts[14] = '"}]';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        return
            string(
                abi.encodePacked(
                    output,
                    parts[9],
                    parts[10],
                    parts[11],
                    parts[12],
                    parts[13],
                    parts[14]
                )
            );
    }

    /**
     * @dev Override of tokenURI. Generated fully on-chain dynamically
     building an SVG based on state recorded at token mint and randomness
     based on the token ID and treasure location (tied to token ID).
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId > 0 && tokenId <= _tokenIds.current());

        string[10] memory parts;
        parts[0] = Svg.__svgAddBegin();

        uint256 textY = 20;

        // Every treasure has a location.
        uint256 treasureX;
        uint256 treasureY;

        (treasureX, , treasureY) = abi.decode(
            coordinates[tokenId],
            (uint256, string, uint256)
        );
        parts[1] = Svg.__svgAddLocation(10, textY, treasureX, treasureY);

        // Every treasure has a random item that the adventurer was wearing
        // when claiming.
        textY += 20;
        parts[2] = Svg.__svgAddWearingItem(10, textY, whileWearing[tokenId]);

        // Add a record of the loot bag if was claimed with Loot.
        if (discoveredWithLoot[tokenId] != 0) {
            textY += 20;
            parts[8] = Svg.__svgAddLootBagRecord(
                10,
                textY,
                discoveredWithLoot[tokenId]
            );
        }

        // Every treasure has a weight.
        textY += 20;
        parts[3] = Svg.__svgAddTreasureWeight(
            10,
            textY,
            getTreasureWeight(tokenId)
        );

        // If the treasure has been opened, then we add the treasure contents and
        // add the description of the contents.
        if (isTreasureOpened[tokenId]) {
            uint256 randComposition = __getRandomTreasureComposition(
                tokenId,
                treasureX,
                treasureY
            );
            parts[4] = Svg.__svgAddTreasureContents(randComposition);
            textY += 20;
            parts[5] = Svg.__svgAddTreasureContentsDescription(
                10,
                textY,
                getTreasureContentsDescription(tokenId, treasureX, treasureY)
            );
        }

        // Every treasure is a chest, though the function will take care of
        // rendering either an opened or closed chest.
        parts[6] = Svg.__svgAddTreasureChest(isTreasureOpened[tokenId]);

        // If a treasure was claimed with an OG 'Loot' bag, add a plaque to
        // the treasure chest.
        if (discoveredWithLoot[tokenId] != 0) {
            parts[7] = Svg.__svgAddTreasureChestPlaque();
        }

        parts[9] = "</svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(abi.encodePacked(output, parts[9]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Treasure Chest #',
                        Strings.toString(tokenId),
                        '", "description": "Treasure Chests are randomly generated treasures scattered and hidden across an island, claimable by any Adventurer.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", "attributes": ',
                        buildAttributesJSON(tokenId, treasureX, treasureY),
                        "}"
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    /**
     * @dev Returns a random **Synthetic Loot** item for a treasure. This is originally
     computed at mint based on the creator address.
     */
    function getRandomSyntheticLootItem(address creator)
        private
        view
        returns (string memory)
    {
        uint256 rand = random(string(abi.encodePacked(creator))) % 8;
        if (rand == 0) {
            return syntheticLootContract.getChest(creator);
        } else if (rand == 1) {
            return syntheticLootContract.getFoot(creator);
        } else if (rand == 2) {
            return syntheticLootContract.getHand(creator);
        } else if (rand == 3) {
            return syntheticLootContract.getHead(creator);
        } else if (rand == 4) {
            return syntheticLootContract.getNeck(creator);
        } else if (rand == 5) {
            return syntheticLootContract.getRing(creator);
        } else if (rand == 6) {
            return syntheticLootContract.getWaist(creator);
        } else {
            return syntheticLootContract.getWeapon(creator);
        }
    }

    /**
     * @dev Returns a random **Loot** item for a treasure. This is originally
     computed at mint based on the creator address and uses the loot bag
     ID that the creator chose to use to claim the treasure.
     */
    function getRandomLootItem(address creator, uint256 lootBagId)
        private
        view
        returns (string memory)
    {
        // Pick a random number to pick which Loot component to pick.
        // There are a total of 8.
        uint256 rand = random(string(abi.encodePacked(creator))) % 8;

        if (rand == 0) {
            return lootContract.getChest(lootBagId);
        } else if (rand == 1) {
            return lootContract.getFoot(lootBagId);
        } else if (rand == 2) {
            return lootContract.getHand(lootBagId);
        } else if (rand == 3) {
            return lootContract.getHead(lootBagId);
        } else if (rand == 4) {
            return lootContract.getNeck(lootBagId);
        } else if (rand == 5) {
            return lootContract.getRing(lootBagId);
        } else if (rand == 6) {
            return lootContract.getWaist(lootBagId);
        } else {
            return lootContract.getWeapon(lootBagId);
        }
    }

    /**
     * @dev Returns description of the treasure if it was opened,
     otherwise empty string. Wrapper for `getTreasureInfo()`
     */
    function getTreasureDescription(
        uint256 tokenId,
        uint256 treasureX,
        uint256 treasureY
    ) private view returns (string memory) {
        return
            isTreasureOpened[tokenId]
                ? getTreasureContentsDescription(tokenId, treasureX, treasureY)
                : "";
    }

    /**
     * @dev Returns data about a given treasure give the treasure's `itemId`.
            Things that are returned define a treasure:
            -- (x, y) coordinates of treasure
            -- Random Loot item recorded when claiming the treasure
            -- Loot Bag that was used to claim treasure (if any)
            -- Weight of treasure
            -- Description of treasure (if opened, otherwise empty string)
     */
    function getTreasureInfo(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            uint256,
            uint256,
            string memory
        )
    {
        require(tokenId > 0 && tokenId <= _tokenIds.current());

        uint256 treasureX;
        uint256 treasureY;

        (treasureX, , treasureY) = abi.decode(
            coordinates[tokenId],
            (uint256, string, uint256)
        );

        return (
            treasureX,
            treasureY,
            whileWearing[tokenId],
            discoveredWithLoot[tokenId],
            getTreasureWeight(tokenId),
            getTreasureDescription(tokenId, treasureX, treasureY)
        );
    }

    /**
     * @dev Utility function. Returns whether or not a given address owns a given Loot 
     bag (specified by `lootBagId`).
     */
    function isOwnerOfLoot(uint256 lootBagId, address account)
        public
        view
        returns (bool)
    {
        return lootContract.ownerOf(lootBagId) == account;
    }

    /**
     * @dev Utility function. Returns how many Loot tokens a given address owns.
     */
    function countLootOwned(address account) public view returns (uint256) {
        return lootContract.balanceOf(account);
    }

    /**
     * @dev Utility function. Returns whether or not a given address has claimed a
     treasure.
     */
    function didClaimTreasure(address account) public view returns (bool) {
        return claimedAddresses[account];
    }

    /**
     * @dev Utility function. Returns whether or not one can still claim a 
     treasure at the given x, y coordinates.
     */
    function isTreasureAvailableToClaim(uint256 treasureX, uint256 treasureY)
        public
        view
        returns (bool)
    {
        // Compute the hash of how we store coordinates in the state.
        bytes32 coordHash = keccak256(
            abi.encodePacked(treasureX, ",", treasureY)
        );
        return !hasLocationBeenDiscovered[coordHash];
    }
}
