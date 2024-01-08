// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Counters.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getWeapon(uint256 tokenId) external view returns (string memory);
    function getChest(uint256 tokenId) external view returns (string memory);
    function getHead(uint256 tokenId) external view returns (string memory);
    function getWaist(uint256 tokenId) external view returns (string memory);
    function getFoot(uint256 tokenId) external view returns (string memory);
    function getHand(uint256 tokenId) external view returns (string memory);
    function getNeck(uint256 tokenId) external view returns (string memory);
    function getRing(uint256 tokenId) external view returns (string memory);
}

contract ColorLoot is ReentrancyGuard, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    //Loot Contract
    address public constant lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    LootInterface lootContract = LootInterface(lootAddress);

    //LootAvatars Contract
    address public constant lootAvatarsAddress = 0x6A364afB113A46DC67DD659cE67f4b518b4c9D14;
    IERC721 lootAvatarsContract = IERC721(lootAvatarsAddress);

    Counters.Counter private _tokenNumTracker;

    uint256 public constant MAX_ELEMENTS = 8000;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public constant PUBLIC_PRICE = 0.05 ether;

    address public devAddress;
    bool public autoTokenId = true;

    uint256[] public thresholds = [8000, 374, 357, 100, 9, 1];
    string[] public colors = [
        "#838383",
        "#00DC82",
        "#2e82ff",
        "#c13cff",
        "#f8b73e",
        "#ff44b7"
    ];
    string[] public levels = [
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
        "Mythic"
    ];

    mapping (bytes32 => uint256) public occurrences;

    mapping (uint256 => bool) public mintedLootIds;
    mapping (uint256 => bool) public mintedLootAvatarsIds;

    event CreateColorLoot(uint256 indexed id);

    /**
     * @notice rarity of loot item
     */
    struct ItemRarity {
        uint256 occurrence;
        uint256 threshold;
        string color;
        string level;
    }

    // Item types for loot
    // Inspired by LootLoose: https://etherscan.io/address/0x3dacb00a8c38fac4bbe24d200fca35e1f9fac80e
    uint256 internal constant WEAPON = 0x0;
    uint256 internal constant CHEST = 0x1;
    uint256 internal constant HEAD = 0x2;
    uint256 internal constant WAIST = 0x3;
    uint256 internal constant FOOT = 0x4;
    uint256 internal constant HAND = 0x5;
    uint256 internal constant NECK = 0x6;
    uint256 internal constant RING = 0x7;

    struct ItemNames {
        string weapon;
        string chest;
        string head;
        string waist;
        string foot;
        string hand;
        string neck;
        string ring;
    }

    struct ItemRarities {
        ItemRarity weapon;
        ItemRarity chest;
        ItemRarity head;
        ItemRarity waist;
        ItemRarity foot;
        ItemRarity hand;
        ItemRarity neck;
        ItemRarity ring;
    }

    /**
     * @dev init contract
     *
     * @param dev dev address
     */
    constructor(
        address dev
    )
        ERC721("Color Loot", "CLOOT")
    {
        require(dev != address(0), "Zero address");
        devAddress = dev;
    }

    // ********* public view functions **********

    /**
     * @notice total number of tokens minted
     */
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @notice get all token IDs of a address
     *
     * @param owner owner address
     */
    function walletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokensId;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return lootContract.getWeapon(tokenId);
    }

    function getChest(uint256 tokenId) public view returns (string memory) {
        return lootContract.getChest(tokenId);
    }

    function getHead(uint256 tokenId) public view returns (string memory) {
        return lootContract.getHead(tokenId);
    }
    
    function getWaist(uint256 tokenId) public view returns (string memory) {
        return lootContract.getWaist(tokenId);
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        return lootContract.getFoot(tokenId);
    }
    
    function getHand(uint256 tokenId) public view returns (string memory) {
        return lootContract.getHand(tokenId);
    }
    
    function getNeck(uint256 tokenId) public view returns (string memory) {
        return lootContract.getNeck(tokenId);
    }

    function getRing(uint256 tokenId) public view returns (string memory) {
        return lootContract.getRing(tokenId);
    }

    // Given an ERC721 bag, returns the names of the items in the bag
    function itemNames(uint256 tokenId) public view returns (ItemNames memory) {
        return
            ItemNames({
                weapon: getWeapon(tokenId),
                chest: getChest(tokenId),
                head: getHead(tokenId),
                waist: getWaist(tokenId),
                foot: getFoot(tokenId),
                hand: getHand(tokenId),
                neck: getNeck(tokenId),
                ring: getRing(tokenId)
            });
    }

    function itemName(uint256 tokenId, uint256 itemType) public view returns (string memory name) {
        if (itemType == WEAPON) {
            return getWeapon(tokenId);
        }
        if (itemType == CHEST) {
            return getChest(tokenId);
        }
        if (itemType == HEAD) {
            return getHead(tokenId);
        }
        if (itemType == WAIST) {
            return getWaist(tokenId);
        }
        if (itemType == FOOT) {
            return getFoot(tokenId);
        }
        if (itemType == HAND) {
            return getHand(tokenId);
        }
        if (itemType == NECK) {
            return getNeck(tokenId);
        }
        if (itemType == RING) {
            return getRing(tokenId);
        }
    }

    /**
     * @notice get rarity data for a item name, i.e. weapon name
     */
    function getItemRarity(string memory name) public view returns (ItemRarity memory) {
        uint256 occurrence = occurrences[keccak256(abi.encodePacked(name))];
        if (occurrence == 0) {
            return _toItemRarity(thresholds[0], colors[0], levels[0], occurrence);
        } 
        for (uint256 i = levels.length - 1; i >= 0; i--) {
            if (occurrence <= thresholds[i]) {
                return _toItemRarity(thresholds[i], colors[i], levels[i], occurrence);
            }
        }
        return _toItemRarity(thresholds[0], colors[0], levels[0], occurrence);
    }

    /**
     * @notice get all rarity data for a loot token
     */
    function getItemRarities(uint256 tokenId) public view returns (ItemRarities memory) {
        return ItemRarities({
            weapon: getItemRarity(getWeapon(tokenId)),
            chest: getItemRarity(getChest(tokenId)),
            head: getItemRarity(getHead(tokenId)),
            waist: getItemRarity(getWaist(tokenId)),
            foot: getItemRarity(getFoot(tokenId)),
            hand: getItemRarity(getHand(tokenId)),
            neck: getItemRarity(getNeck(tokenId)),
            ring: getItemRarity(getRing(tokenId))
        });
    }

    /**
     * @notice get occurrence of item name
     */
    function getOccurrence(string memory name) public view returns (uint256) {
        return occurrences[keccak256(abi.encodePacked(name))];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[1] = getWeapon(tokenId);
        parts[0] = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>text { font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" fill="', getItemRarity(parts[1]).color, '">'));

        parts[3] = getChest(tokenId);
        parts[2] = string(abi.encodePacked(
            '</text><text x="10" y="40" fill="', getItemRarity(parts[3]).color, '">'));

        parts[5] = getHead(tokenId);
        parts[4] = string(abi.encodePacked(
            '</text><text x="10" y="60" fill="', getItemRarity(parts[5]).color, '">'));

        parts[7] = getWaist(tokenId);
        parts[6] = string(abi.encodePacked(
            '</text><text x="10" y="80" fill="', getItemRarity(parts[7]).color, '">'));

        parts[9] = getFoot(tokenId);
        parts[8] = string(abi.encodePacked(
            '</text><text x="10" y="100" fill="', getItemRarity(parts[9]).color, '">'));

        parts[11] = getHand(tokenId);
        parts[10] = string(abi.encodePacked(
            '</text><text x="10" y="120" fill="', getItemRarity(parts[11]).color, '">'));

        parts[13] = getNeck(tokenId);
        parts[12] = string(abi.encodePacked(
            '</text><text x="10" y="140" fill="', getItemRarity(parts[13]).color, '">'));

        parts[15] = getRing(tokenId);
        parts[14] = string(abi.encodePacked(
            '</text><text x="10" y="160" fill="', getItemRarity(parts[15]).color, '">'));

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Color Loot privides rarity data on chain to Loot. Contracts can access item rarity of Loot on chain now. Feel free to use Color Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
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

    // ********* public functions **********

    /**
     * @notice mint one token for public
     *
     * @notice public price is 0.05 eth
     */
    function mint() public payable nonReentrant {
        require(autoTokenId, "Auto token id disabled, please use mintWithTokenId");
        require(totalMint() < MAX_ELEMENTS, "Max supply");
        require(msg.value >= PUBLIC_PRICE, "Value below price");
        _transfer(devAddress, msg.value);
        _mintOne(_msgSender());
    }

    /**
     * @notice multi mint for public
     */
    function multiMint(uint256 count) public payable nonReentrant {
        require(autoTokenId, "Auto token id disabled, please use mintWithTokenId");
        require(count <= MAX_BY_MINT, "Max limit");
        require(totalMint() + count <= MAX_ELEMENTS, "Max supply");
        require(msg.value >= PUBLIC_PRICE * count, "Value below price");
        _transfer(devAddress, msg.value);
        for (uint256 i = 0; i < count; i++) {
            _mintOne(_msgSender());
        }
    }

    /**
     * @notice mint one token with tokenId for public
     *
     * @notice for the first 1-7777 tokens, please use mint
     * @notice this method only enabled when there is new tokens > 7777 minted
     * 
     * @notice public price is 0.05 eth
     */
    function mintWithTokenId(uint256 tokenId) public payable nonReentrant {
        require(!autoTokenId, "Auto token id enabled");
        require(totalMint() < MAX_ELEMENTS, "Max supply");
        require(msg.value >= PUBLIC_PRICE, "Value below price");
        _transfer(devAddress, msg.value);
        _mintOne(_msgSender(), tokenId);
    }

    /**
     * @notice mint with loot
     *
     * @param lootId loot token id
     */
    function mintWithLoot(uint256 lootId) public payable nonReentrant {
        require(autoTokenId, "Auto token id disabled, please use mintWithTokenId");
        require(lootId > 0 && lootId < 8001, "Token ID invalid");
        require(lootContract.ownerOf(lootId) == _msgSender(), "Not the owner of this loot");
        require(!mintedLootIds[lootId], "This loot token has already been minted");
        mintedLootIds[lootId] = true;
        
        require(totalMint() < MAX_ELEMENTS, "Max supply");
        _mintOne(_msgSender());
    }

    /**
     * @notice mint with multiple loots
     *
     * @param lootIds loot token ids
     */
    function multiMintWithLoots(uint[] memory lootIds) public payable nonReentrant {
        require(autoTokenId, "Auto token id disabled, please use mintWithTokenId");
        for (uint256 i = 0; i < lootIds.length; i++) {
            uint256 lootId = lootIds[i];
            require(lootId > 0 && lootId < 8001, "Token ID invalid");
            require(lootContract.ownerOf(lootId) == _msgSender(), "Not the owner of this loot");
            require(!mintedLootIds[lootId], "This loot token has already been minted");
            mintedLootIds[lootId] = true;
        }
        uint256 count = lootIds.length;
        require(count <= MAX_BY_MINT, "Max limit");
        require(totalMint() + count <= MAX_ELEMENTS, "Max supply");
        for (uint256 i = 0; i < count; i++) {
            _mintOne(_msgSender());
        }
    }

    /**
     * @notice mint with avatar
     *
     * @param avatarId loot token id
     */
    function mintWithAvatar(uint256 avatarId) public payable nonReentrant {
        require(autoTokenId, "Auto token id disabled, please use mintWithTokenId");
        require(avatarId > 0 && avatarId < 8001, "Token ID invalid");
        require(lootAvatarsContract.ownerOf(avatarId) == _msgSender(), "Not the owner of this avatar");
        require(!mintedLootAvatarsIds[avatarId], "This token has already been minted");
        mintedLootAvatarsIds[avatarId] = true;
        
        require(totalMint() < MAX_ELEMENTS, "Max supply");
        _mintOne(_msgSender());
    }

    /**
     * @notice mint with multiple avatars
     *
     * @param avatarIds loot avatar token ids
     */
    function multiMintWithAvatars(uint[] memory avatarIds) public payable nonReentrant {
        require(autoTokenId, "Auto token id disabled, please use mintWithTokenId");
        for (uint256 i = 0; i < avatarIds.length; i++) {
            uint256 avatarId = avatarIds[i];
            require(avatarId > 0 && avatarId < 8001, "Token ID invalid");
            require(lootAvatarsContract.ownerOf(avatarId) == _msgSender(), "Not the owner of this avatar");
            require(!mintedLootAvatarsIds[avatarId], "This token has already been minted");
            mintedLootAvatarsIds[avatarId] = true;
        }
        
        uint256 count = avatarIds.length;
        require(count <= MAX_BY_MINT, "Max limit");
        require(totalMint() + count <= MAX_ELEMENTS, "Max supply");
        for (uint256 i = 0; i < count; i++) {
            _mintOne(_msgSender());
        }
    }

    // ********* public onwer functions **********

    /**
     * @notice set dev address
     */
    function setDev(address dev) public onlyOwner {
        require(dev != address(0), "Zero address");
        devAddress = dev;
    }

    /**
     * @notice withdraw the balance except jackpotRemaining
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        _transfer(devAddress, amount);
    }

    /**
     * @notice update a rarity level
     *
     * @dev make sure rarities are sorted by threshold in descending order
     *
     * @param idx index of rarity level
     * @param threshold threshold of occurrence
     * @param color color shown in svg
     * @param level name of rarity level
     */
    function updateRarityLevel(
        uint256 idx,
        uint256 threshold,
        string memory color,
        string memory level
    )
        public onlyOwner
    {
        thresholds[idx] = threshold;
        colors[idx] = color;
        levels[idx] = level;
    }

    /**
     * @notice reset rarity levels
     *
     * @dev params should be sorted by threshold in descending order
     *
     * @param _thresholds all thresholds in descending order
     * @param _colors all colors
     * @param _levels all levels
     */
    function resetRarityLevels(
        uint256[] calldata _thresholds,
        string[] memory _colors,
        string[] memory _levels
    )
        public onlyOwner
    {
        require(_thresholds.length > 0, "Empty thresholds");
        require(_thresholds.length == _colors.length, "array length should be equal");
        require(_thresholds.length == _levels.length, "array length should be equal");
        thresholds = _thresholds;
        colors = _colors;
        levels = _levels;
    }

    /**
     * @notice auto token id enabled for loot 1 - 7777
     *
     * @dev the max supply of loot is 8000, if new loots not claimed in order, we should disable auto token id
     */
    function setAutoTokenId(bool _autoTokenId) public onlyOwner {
        autoTokenId = _autoTokenId;
    }

    // ****** internal functions ******

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _totalSupply() internal virtual view returns (uint) {
        return _tokenNumTracker.current();
    }

    function _toItemRarity(
        uint256 threshold,
        string memory color,
        string memory level,
        uint256 occurrence
    )
        internal pure returns (ItemRarity memory)
    {
        return ItemRarity({
            occurrence: occurrence,
            threshold: threshold,
            color: color,
            level: level
        });
    }

    // ******* private functions ********

    function _incrOccurrence(string memory _name) private {
        bytes32 hashName = keccak256(abi.encodePacked(_name));
        occurrences[hashName]++;
    }

    function _incrItemsOccurrences(ItemNames memory _itemNames) private {
        _incrOccurrence(_itemNames.weapon);
        _incrOccurrence(_itemNames.chest);
        _incrOccurrence(_itemNames.head);
        _incrOccurrence(_itemNames.waist);
        _incrOccurrence(_itemNames.foot);
        _incrOccurrence(_itemNames.hand);
        _incrOccurrence(_itemNames.neck);
        _incrOccurrence(_itemNames.ring);
    }

    /**
     * @dev mint with auto id, from 1
     */
    function _mintOne(address _to) private {
        _tokenNumTracker.increment();
        uint id = _tokenNumTracker.current();
        require(lootContract.ownerOf(id) != address(0), "Loot Id not exists");
        require(!_exists(id), "TokenId already minted");

        _incrItemsOccurrences(itemNames(id));
        _safeMint(_to, id);
        emit CreateColorLoot(id);
    }

    /**
     * @dev mint with token id
     */
    function _mintOne(address _to, uint256 _tokenId) private {
        _tokenNumTracker.increment();
        uint id = _tokenId;
        require(lootContract.ownerOf(id) != address(0), "Loot Id not exists");
        require(!_exists(id), "Token Id already minted");

        _incrItemsOccurrences(itemNames(id));
        _safeMint(_to, id);
        emit CreateColorLoot(id);
    }

    function _transfer(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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