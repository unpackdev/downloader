// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract GearSlots is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public cost = 0.025 ether;
    uint256 private maxMintAmount = 10;
    uint256 private maxSupply = 11111;

    uint256 private minSlotPrice = 0.00001 ether;
    mapping(address => uint256) private whitelisted;

    mapping(uint256 => mapping(uint256 => SlotItem)) public _bags;
    mapping(uint256 => uint256) public _setPricesPerSlot;

    struct SlotItem {
        string itemText;
        uint256 price;
    }

    struct SlotPriceDetail {
        uint256 tokenId;
        uint256 slotId;
        uint256 price;
        string slotItem;
    }

    event slotPriceSet(
        address from,
        uint256 tokenId,
        uint256 slotId,
        uint256 amount
    );
    event slotTraded(
        address from,
        uint256 sourceTokenId,
        uint256 targetTokenId,
        uint256 slotId,
        uint256 amount
    );

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function getSlotPrices(uint256 slotId)
        public
        view
        returns (SlotPriceDetail[] memory slotPriceDetail)
    {
        uint256 supply = totalSupply();
        SlotPriceDetail[] memory slotPriceDetails = new SlotPriceDetail[](
            _setPricesPerSlot[slotId]
        );

        uint256 j = 0;
        for (uint256 i = 1; i <= supply; i++) {
            if (_bags[i][slotId].price > 0) {
                slotPriceDetails[j] = SlotPriceDetail(
                    i,
                    slotId,
                    _bags[i][slotId].price,
                    _bags[i][slotId].itemText
                );
                j++;
            }
        }

        return (slotPriceDetails);
    }

    function setSlotMapping(uint256 tokenId) private {
        _bags[tokenId][0] = SlotItem(pluck(tokenId, "WEAPON", weapons), 0);

        _bags[tokenId][1] = SlotItem(pluck(tokenId, "CHEST", chestArmor), 0);

        _bags[tokenId][2] = SlotItem(pluck(tokenId, "HEAD", headArmor), 0);

        _bags[tokenId][3] = SlotItem(pluck(tokenId, "WAIST", waistArmor), 0);

        _bags[tokenId][4] = SlotItem(pluck(tokenId, "FOOT", footArmor), 0);

        _bags[tokenId][5] = SlotItem(pluck(tokenId, "HAND", handArmor), 0);

        _bags[tokenId][6] = SlotItem(pluck(tokenId, "NECK", necklaces), 0);

        _bags[tokenId][7] = SlotItem(pluck(tokenId, "RING", rings), 0);

        _bags[tokenId][8] = SlotItem(pluck(tokenId, "SHIELD", shields), 0);
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (whitelisted[msg.sender] == 0) {
            require(msg.value >= cost * _mintAmount);
        } else {
            _mintAmount = 1;
        }

        uint256 tokenId = supply + 1;
        for (uint256 i = 0; i < _mintAmount; i++) {
            require(tokenId <= maxSupply, "Exceeded supply.");

            _safeMint(_to, tokenId);
            setSlotMapping(tokenId);

            tokenId = tokenId + 1;
        }

        if (whitelisted[msg.sender] == 1) {
            whitelisted[msg.sender] = 0;
        }
    }

    function getMintCost() public view returns (uint256) {
        return cost;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelisted[_address] == 1;
    }

    function setSlotPrices(
        uint256 tokenId,
        uint256[] memory slotIds,
        uint256[] memory prices
    ) public payable {
        require(
            _exists(tokenId),
            "ERC721Metadata: Set slot price for nonexistent token"
        );
        require(ownerOf(tokenId) == msg.sender, "Must own token.");
        require(
            slotIds.length == prices.length,
            "Arrays must be equal length."
        );
        require(getMax(slotIds) < 9, "Invalid slotIds.");
        require(!containsDuplicates(slotIds), "Duplicate slotIds.");
        require(getMin(prices) > minSlotPrice, "Prices must be greater.");

        for (uint256 i = 0; i < slotIds.length; i++) {
            _bags[tokenId][slotIds[i]].price = prices[i];
            _setPricesPerSlot[slotIds[i]] = _setPricesPerSlot[slotIds[i]] + 1;
            emit slotPriceSet(msg.sender, tokenId, slotIds[i], prices[i]);
        }
    }

    function tradeSlotPiece(
        uint256 sourceTokenId,
        uint256 targetTokenId,
        uint256 slotId
    ) public payable {
        require(
            _exists(sourceTokenId),
            "ERC721Metadata: Trade slot piece for nonexistent token"
        );
        require(
            _exists(targetTokenId),
            "ERC721Metadata: Trade slot piece for nonexistent token"
        );
        require(ownerOf(targetTokenId) == msg.sender, "Must own target token.");
        require(
            _bags[sourceTokenId][slotId].price > 0,
            "No price set on item."
        );
        require(
            msg.value >= _bags[sourceTokenId][slotId].price,
            "Incorrect value."
        );

        (bool sendOne, bytes memory dataOne) = owner().call{
            value: msg.value / 20
        }("");
        require(sendOne, "Failed to send Ether");

        (bool sendTwo, bytes memory dataTwo) = ownerOf(sourceTokenId).call{
            value: (msg.value / 20) * 19
        }("");
        require(sendTwo, "Failed to send Ether");

        string memory swap = _bags[sourceTokenId][slotId].itemText;
        _bags[sourceTokenId][slotId].itemText = _bags[targetTokenId][slotId]
            .itemText;
        _bags[targetTokenId][slotId].itemText = swap;

        if (_bags[targetTokenId][slotId].price > 0) {
            _setPricesPerSlot[slotId] = _setPricesPerSlot[slotId] - 2;
        } else {
            _setPricesPerSlot[slotId] = _setPricesPerSlot[slotId] - 1;
        }

        _bags[targetTokenId][slotId].price = 0;
        _bags[sourceTokenId][slotId].price = 0;

        emit slotTraded(
            msg.sender,
            sourceTokenId,
            targetTokenId,
            slotId,
            msg.value
        );
    }

    function getMinSlotPrice() public view returns (uint256) {
        return minSlotPrice;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string[22] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getShield(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getChest(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getHead(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getWaist(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getFoot(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getHand(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getNeck(tokenId);

        parts[16] = '</text><text x="10" y="180" class="base">';

        parts[17] = getRing(tokenId);

        parts[
            18
        ] = '</text><svg x="272" y="235" width="20mm" height="40mm" viewBox="0 0 82 82" xmlns="http://www.w3.org/2000/svg">';

        parts[
            19
        ] = '<path d="m41 1c-2.7392 0-5.4152 0.28719-8 0.8125v6.1875c-3.4748 0.83887-6.7198 2.1846-9.6875 4l-4.375-4.375c-2.2426 1.4861-4.2923 3.2298-6.1875 5.125-1.8953 1.8952-3.6389 3.9449-5.125 6.1875l4.375 4.375c-1.8154 2.9677-3.1611 6.2126-4 9.6875h-6.1875c-0.5253 2.5848-0.8125 5.2608-0.8125 8s0.2872 5.4152 0.8125 8h6.1875c0.83887 3.4748 2.1846 6.7198 4 9.6875l-4.375 4.375c1.4861 2.2426 3.2297 4.2923 5.125 6.1875 1.8952 1.8952 3.9449 3.6389 6.1875 5.125l4.375-4.375c2.9677 1.8154 6.2126 3.1611 9.6875 4v6.1875c2.5848 0.5253 5.2608 0.8125 8 0.8125 2.7391 0 5.4151-0.2872 8-0.8125v-6.1875c3.4748-0.83888 6.7198-2.1846 9.6875-4l4.375 4.375c2.2426-1.4861 4.2922-3.2298 6.1875-5.125 1.8952-1.8952 3.6389-3.9449 5.125-6.1875l-4.375-4.375c1.8154-2.9677 3.1611-6.2126 4-9.6875h6.1875c0.5253-2.5848 0.8125-5.2608 0.8125-8s-0.2872-5.4152-0.8125-8h-6.1875c-0.8389-3.4748-2.1846-6.7198-4-9.6875l4.375-4.375c-1.4861-2.2426-3.2298-4.2923-5.125-6.1875-1.8953-1.8952-3.9449-3.6389-6.1875-5.125l-4.375 4.375c-2.9677-1.8154-6.2127-3.1611-9.6875-4v-6.1875c-2.5849-0.52531-5.2609-0.8125-8-0.8125zm0 20c11.04 0 20 8.96 20 20s-8.96 20-20 20-20-8.96-20-20 8.96-20 20-20z" fill="white" stroke="white" stroke-dashoffset="162" stroke-linecap="round" stroke-linejoin="round" stroke-width="1">';

        parts[
            20
        ] = '<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="360 41 41" to="0 41 41" dur="10s" additive="sum" repeatCount="indefinite" />';

        parts[21] = "</path></svg></svg>";

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
        output = string(abi.encodePacked(output, parts[17], parts[18]));
        output = string(abi.encodePacked(output, parts[19]));
        output = string(abi.encodePacked(output, parts[20], parts[21]));

        string memory json = string(
            abi.encodePacked(
                '{"name": "Bag #',
                toString(tokenId),
                '", "description": "Gear Slots is a collection of randomized RPG bags, full of gear, stored on-chain. Each piece of gear can be traded individually, without trading the entire bag of gear.", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(output)),
                '",'
            )
        );
        json = string(
            abi.encodePacked(
                json,
                '"attributes": [{"trait_type": "Weapon", "value": "',
                getWeapon(tokenId),
                '"}, {"trait_type": "Chest", "value": "',
                getChest(tokenId),
                '"}, {"trait_type": "Head", "value": "',
                getHead(tokenId),
                '"}, {"trait_type": "Waist", "value": "',
                getWaist(tokenId),
                '"}, {"trait_type": "Foot", "value": "',
                getFoot(tokenId),
                '"}, {"trait_type": "Hand",'
            )
        );
        json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        json,
                        '"value": "',
                        getHand(tokenId),
                        '"}, {"trait_type": "Neck", "value": "',
                        getNeck(tokenId),
                        '"}, {"trait_type": "Ring", "value": "',
                        getRing(tokenId),
                        '"}, {"trait_type": "Shield", "value": "',
                        getShield(tokenId),
                        '"}]}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function setMaxMintAmount(uint256 newMaxMintAmount)
        public
        payable
        onlyOwner
    {
        maxMintAmount = newMaxMintAmount;
    }

    function setMinSlotPrice(uint256 newMinSlotPrice) public payable onlyOwner {
        minSlotPrice = newMinSlotPrice;
    }

    function setMintCost(uint256 newMintCost) public payable onlyOwner {
        cost = newMintCost;
    }

    function addToWhitelist(address _to) public payable onlyOwner {
        whitelisted[_to] = 1;
    }

    function withdraw(uint256 amount) public payable onlyOwner {
        payable(owner()).transfer(amount);
    }

    string[] private weapons = [
        "Holy Avenger",
        "Master Sword",
        "Crystal Sword",
        "War Scepter",
        "War Sword",
        "War Hammer",
        "Battle Axe",
        "Heavy Mace",
        "Long Sword",
        "Double Axe",
        "Double Flail",
        "Heavy Scepter",
        "Heavy Club",
        "Short Sword",
        "Axe",
        "Flail",
        "Mace",
        "Scepter",
        "Club"
    ];

    string[] private shields = [
        "Blessed Shield",
        "Enchanted Shield",
        "Templar Shield",
        "Ornate Shield",
        "Mirror Shield",
        "War Shield",
        "Crystal Shield",
        "Spiked Shield",
        "Gothic Shield",
        "Tower Shield",
        "Heavy Shield",
        "Thick Shield",
        "Kite Shield",
        "Round Shield",
        "Small Shield",
        "Buckler"
    ];

    string[] private chestArmor = [
        "Templar Armor",
        "Ornate Armor",
        "Gothic Armor",
        "Plate Armor",
        "Bone Armor",
        "Chain Armor",
        "Scale Armor",
        "Ring Armor",
        "Demon Armor",
        "Shark Armor",
        "Studded Armor",
        "Leather Armor",
        "Blue Tunic",
        "Red Tunic",
        "Tunic"
    ];

    string[] private headArmor = [
        "Templar Helm",
        "Ornate Circlet",
        "Gothic Crown",
        "Plate Helm",
        "Bone Helm",
        "Chain Coif",
        "Scale Coif",
        "Ring Coif",
        "Demon Hood",
        "Shark Hat",
        "Studded Hood",
        "Blue Hood",
        "Red Hood",
        "Hood",
        "Cap"
    ];

    string[] private waistArmor = [
        "Templar Belt",
        "Ornate Belt",
        "Gothic Belt",
        "Plate Belt",
        "Bone Belt",
        "Chain Belt",
        "Scale Belt",
        "Ring Belt",
        "Demon Belt",
        "Shark Belt",
        "Studded Belt",
        "Leather Belt",
        "Quilted Belt",
        "Heavy Belt",
        "Belt"
    ];

    string[] private footArmor = [
        "Templar Boots",
        "Ornate Greaves",
        "Gothic Boots",
        "Plate Greaves",
        "Bone Greaves",
        "Chain Boots",
        "Scale Boots",
        "Ring Boots",
        "Demon Boots",
        "Shark Boots",
        "Studded Boots",
        "Blue Boots",
        "Red Boots",
        "Boots",
        "Slippers"
    ];

    string[] private handArmor = [
        "Templar Gauntlets",
        "Ornate Gauntlets",
        "Gothic Gauntlets",
        "Plate Gauntlets",
        "Bone Gauntlets",
        "Chain Gloves",
        "Scale Gloves",
        "Ring Gloves",
        "Demon Gloves",
        "Shark Gloves",
        "Studded Gloves",
        "Blue Gloves",
        "Red Gloves",
        "Leather Gloves",
        "Gloves"
    ];

    string[] private necklaces = ["Amulet", "Pendant", "Beads"];

    string[] private rings = [
        "Diamond Ring",
        "Gold Ring",
        "Silver Ring",
        "Copper Ring",
        "Ring"
    ];

    string[] private suffixes = [
        "of Victory",
        "of Valor",
        "of War",
        "of Wrath",
        "of Battle",
        "of Honor",
        "of Victory",
        "of Command",
        "of Man",
        "of Might",
        "of Power",
        "of Greed",
        "of Skill",
        "of Force",
        "of Pride",
        "of Plague"
    ];

    string[] private namePrefixes = [
        "Death's",
        "Heaven's",
        "Hell's",
        "Keeper's",
        "Believer's",
        "Zealot's",
        "Brigadier's",
        "Heroes",
        "Emperor's",
        "King's",
        "Juggernaut's",
        "Guardian's",
        "Titan's",
        "Giant's",
        "Templar's",
        "Slayer's",
        "Commander's",
        "Grandmaster's",
        "Blademaster's",
        "Vanquisher's",
        "Vindicator's",
        "Knight's",
        "Squire's",
        "Master's",
        "Captain's",
        "Berserker's",
        "Valkyrie's",
        "Crusader's",
        "Paladin's",
        "Swordsman's",
        "Protector's",
        "Victor's",
        "Subjugator's",
        "Conqueror's",
        "Cavalier's",
        "Devotee's",
        "Bishop's",
        "Cavalryman's",
        "Horseman's",
        "Commando's",
        "Warrior's",
        "Noble's",
        "Enthusiast's",
        "Soldier's",
        "Lord's",
        "Nobleman's",
        "Challenger's",
        "Champion's",
        "Balrog's",
        "Dragon's",
        "Wyrm's",
        "Drake's",
        "Griffon's",
        "Officer's",
        "Lieutenant's",
        "Sergeant's",
        "Corporal's",
        "Marshal's",
        "Warden's",
        "Recruit's",
        "Keeper's",
        "Veteran's",
        "Militant's",
        "Partisan's",
        "Hierophant's",
        "Ideologue's",
        "Priest's",
        "Monk's",
        "Fanatic's",
        "Expert's",
        "Hunter's"
    ];

    string[] private nameSuffixes = [
        "Wrath",
        "Faith",
        "Anger",
        "Might",
        "Pride",
        "Lust",
        "Truth",
        "Sin",
        "Revenge",
        "Grudge",
        "Fury",
        "Glory",
        "Temper",
        "Justice",
        "Envy",
        "Prayer",
        "Virtue",
        "Desire",
        "Skill",
        "Ready"
    ];

    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getWeapon(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][0].itemText;
    }

    function getShield(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][8].itemText;
    }

    function getChest(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][1].itemText;
    }

    function getHead(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][2].itemText;
    }

    function getWaist(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][3].itemText;
    }

    function getFoot(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][4].itemText;
    }

    function getHand(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][5].itemText;
    }

    function getNeck(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][6].itemText;
    }

    function getRing(uint256 tokenId) private view returns (string memory) {
        return _bags[tokenId][7].itemText;
    }

    function toString(uint256 value) private pure returns (string memory) {
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

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) private view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];

        uint256 greatness = rand % 26;
        if (greatness > 16) {
            output = string(
                abi.encodePacked(output, " ", suffixes[rand % suffixes.length])
            );
        }
        if (greatness >= 21) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(
                    abi.encodePacked(
                        unicode"●",
                        " ",
                        name[0],
                        " ",
                        name[1],
                        " ",
                        unicode"●",
                        " ",
                        output
                    )
                );
            } else {
                output = string(
                    abi.encodePacked(
                        unicode"●",
                        " ",
                        name[0],
                        " ",
                        name[1],
                        " ",
                        unicode"●",
                        " ",
                        output,
                        " +1"
                    )
                );
            }
        }
        return output;
    }

    function getMax(uint256[] memory values) private pure returns (uint256) {
        require(values.length > 0, "Array must not be empty");
        uint256 largest = 0;
        for (uint256 i = 0; i < values.length; i++) {
            if (values[i] > largest) {
                largest = values[i];
            }
        }
        return largest;
    }

    function getMin(uint256[] memory values) private pure returns (uint256) {
        require(values.length > 0, "Array must not be empty");
        uint256 smallest = 999999 ether;
        for (uint256 i = 0; i < values.length; i++) {
            if (values[i] < smallest) {
                smallest = values[i];
            }
        }
        return smallest;
    }

    function containsDuplicates(uint256[] memory values)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < values.length; i++) {
            for (uint256 j = 0; j < values.length; j++) {
                if (i != j) {
                    if (values[i] == values[j]) {
                        return true;
                    }
                }
            }
        }
        return false;
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
