// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";
import "./console.sol";
import "./IERC20.sol";

interface LootInterface is IERC721 {
    // Loot methods
    function getWeapon(uint256 tokenId) external view returns (string memory);
    function getChest(uint256 tokenId) external view returns (string memory);
    function getHead(uint256 tokenId) external view returns (string memory);
    function getWaist(uint256 tokenId) external view returns (string memory);
    function getFoot(uint256 tokenId) external view returns (string memory);
    function getHand(uint256 tokenId) external view returns (string memory);
    function getNeck(uint256 tokenId) external view returns (string memory);
    function getRing(uint256 tokenId) external view returns (string memory);
}

interface GMInterface is IERC721 {

    struct ManaDetails {
        uint256 lootTokenId;
        bytes32 itemName;
        uint8 suffixId;
        uint8 inventoryId;
    }
    function detailsByToken(uint256 tokenId)
        external view
        returns (ManaDetails memory) ;
}

//---------------------------------- v2 start ------------------------------------
interface IGenesisRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IGenesisLostManaNaming {
    function getMax(uint256 tokenId, uint8 inventoryId) external view returns (uint256);
}

//---------------------------------- v2 end ------------------------------------

contract GenesisAdventurerV3 is ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {

    GMInterface private _genesisMana;
    LootInterface private _lootContract;

    // Item Metadata Tracker
    // Mapping is: detailsByToken[tokenId][map below] = GM TokenID
    // 0 - weapon
    // 1 - chestArmor
    // 2 - headArmor
    // 3 - waistArmor
    // 4 - footArmor
    // 5 - handArmor
    // 6 - neckArmor
    // 7 - ring
    // 8 - order id
    // 9 - order count
    mapping(uint256 => uint256[10]) private _detailsByToken;

    string[2][17] private _suffices;
    uint8[2][17] private _sufficesCount;

    uint32 private _currentTokenId;

    mapping(uint256 => bool) public itemUsedByGMID;

    address[17] public orderDAOs;

    uint256 public publicPrice;

    function initialize(address _gmAddress, address _lootAddress, address[17] memory _DAOs, uint256 _initialPrice) initializer public {
      __ERC721_init("GenesisAdventurer", "GA");
      __Ownable_init();

      orderDAOs = _DAOs;
      _genesisMana = GMInterface(_gmAddress);

      _lootContract = LootInterface(_lootAddress);

      _currentTokenId = 0;

      _suffices = [
          ["",""],                         // 0
          ["Power","#191D7E"],             // 1
          ["Giants","#DAC931"],            // 2
          ["Titans","#B45FBB"],            // 3
          ["Skill","#1FAD94"],             // 4
          ["Perfection","#2C1A72"],        // 5
          ["Brilliance","#36662A"],        // 6
          ["Enlightenment","#78365E"],     // 7
          ["Protection","#4F4B4B"],        // 8
          ["Anger","#9B1414"],             // 9
          ["Rage","#77CE58"],              // 10
          ["Fury","#C07A28"],              // 11
          ["Vitriol","#511D71"],           // 12
          ["the Fox","#949494"],           // 13
          ["Detection","#DB8F8B"],         // 14
          ["Reflection","#318C9F"],        // 15
          ["the Twins","#00AE3B"]          // 16
      ];

      _sufficesCount = [
          [0,0],                         // 0
          [166,0],             // 1
          [173,0],            // 2
          [163,0],            // 3
          [157,0],             // 4
          [160,0],        // 5
          [152,0],        // 6
          [151,0],     // 7
          [162,0],        // 8
          [160,0],             // 9
          [149,0],              // 10
          [165,0],              // 11
          [162,0],           // 12
          [160,0],           // 13
          [156,0],         // 14
          [154,0],        // 15
          [150,0]          // 16
      ];

      publicPrice = _initialPrice;
     }

    function tokenURI(uint256 tokenId) override public view returns (string memory) { //----- updated for v2
      require(
        (tokenId > 0 && tokenId <= _currentTokenId),
        "TOKEN_ID_NOT_MINTED"
      );
      return IGenesisRenderer(rendererAddress).tokenURI(tokenId);
    }

    // Function for a Genesis Mana holder to mint Genesis Adventure
    function resurrectGA(
        uint256 weaponTokenId,
        uint256 chestTokenId,
        uint256 headTokenId,
        uint256 waistTokenId,
        uint256 footTokenId,
        uint256 handTokenId,
        uint256 neckTokenId,
        uint256 ringTokenId)
      external
      payable
      nonReentrant
    {

      require(publicPrice <= msg.value, "INSUFFICIENT_ETH");

      uint256[8] memory _items = [
        weaponTokenId,
        chestTokenId,
        headTokenId,
        waistTokenId,
        footTokenId,
        handTokenId,
        neckTokenId,
        ringTokenId
      ];
      uint256[10] memory lootTokenIds;

      GMInterface.ManaDetails memory details;
      uint256 suffixId = 0;

      for (uint8 i = 0; i < 8; i++) {

        require(
            !itemUsedByGMID[_items[i]],
            "ITEM_USED"
        );

        require(
            _msgSender() == _genesisMana.ownerOf(_items[i]),
            "MUST_OWN"
        );
        details = _genesisMana.detailsByToken(_items[i]);

        require(
            i == details.inventoryId,
            "ITEM_WRONG"
        );
        if (suffixId == 0) {
          suffixId = details.suffixId;
        } else {
          require(
              suffixId == details.suffixId,
              "BAD_ORDER_MATCH"
          );
        }

        lootTokenIds[i] = details.lootTokenId;
      }
      lootTokenIds[8] = suffixId;
      _sufficesCount[suffixId][1]++;
      lootTokenIds[9] = _sufficesCount[suffixId][1];

      _detailsByToken[_getNextTokenId()] = lootTokenIds;
      _safeMint(_msgSender(), _getNextTokenId());
      _incrementTokenId();

      for (uint8 i = 0; i < 8; i++) {
        itemUsedByGMID[_items[i]] = true;
        _genesisMana.safeTransferFrom(_msgSender(), orderDAOs[suffixId], _items[i]);
      }
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        if (_detailsByToken[tokenId][0] == 0)
            return string(abi.encodePacked("Lost Weapon of ", getOrder(tokenId)));
        else
            return _lootContract.getWeapon(_detailsByToken[tokenId][0]);
    }

    function getChest(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        if (_detailsByToken[tokenId][1] == 0)
            return string(abi.encodePacked("Lost Chest Armor of ", getOrder(tokenId)));
        else
            return _lootContract.getChest(_detailsByToken[tokenId][1]);
    }

    function getHead(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        if (_detailsByToken[tokenId][2] == 0)
            return string(abi.encodePacked("Lost Head Armor of ", getOrder(tokenId)));
        else
            return _lootContract.getHead(_detailsByToken[tokenId][2]);
    }

    function getWaist(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        if (_detailsByToken[tokenId][3] == 0)
            return string(abi.encodePacked("Lost Waist Armor of ", getOrder(tokenId)));
        else
            return _lootContract.getWaist(_detailsByToken[tokenId][3]);
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        if (_detailsByToken[tokenId][4] == 0)
            return string(abi.encodePacked("Lost Foot Armor of ", getOrder(tokenId)));
        else
            return _lootContract.getFoot(_detailsByToken[tokenId][4]);
    }

    function getHand(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        if (_detailsByToken[tokenId][5] == 0)
            return string(abi.encodePacked("Lost Hand Armor of ", getOrder(tokenId)));
        else
            return _lootContract.getHand(_detailsByToken[tokenId][5]);
    }

    function getNeck(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        if (_detailsByToken[tokenId][6] == 0)
            return string(abi.encodePacked("Lost Neck Armor of ", getOrder(tokenId)));
        else
            return _lootContract.getNeck(_detailsByToken[tokenId][6]);
    }

    function getRing(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        if (_detailsByToken[tokenId][7] == 0)
            return string(abi.encodePacked("Lost Ring of ", getOrder(tokenId)));
        else
            return _lootContract.getRing(_detailsByToken[tokenId][7]);
    }

    function getOrder(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        return _suffices[_detailsByToken[tokenId][8]][0];
    }

    function getOrderColor(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        return _suffices[_detailsByToken[tokenId][8]][1];
    }

    function getOrderCount(uint256 tokenId) public view returns (string memory) {
        require(
            (tokenId > 0 && tokenId <= _currentTokenId),
            "TOKEN_ID_NOT_MINTED"
        );
        return string(abi.encodePacked("#",Strings.toString(_detailsByToken[tokenId][9])," / ",Strings.toString(_sufficesCount[_detailsByToken[tokenId][8]][0])));
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId + 1;
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    //---------------------------------- v2 start ------------------------------------
    address public rendererAddress;
    address public adventureTimeAddress;
    address public lostNamingAddress;
    mapping(uint256=>uint8) lostNamingCount;
    struct Item {
        uint256 lootTokenId;
        uint8 inventoryId;
    }
    event NameLostMana(uint256 tokenId, Item[] itemsToName);

    function getLootTokenIds(uint256 tokenId) public view returns(uint256[8] memory) {
        return [_detailsByToken[tokenId][0], _detailsByToken[tokenId][1], _detailsByToken[tokenId][2], _detailsByToken[tokenId][3], _detailsByToken[tokenId][4], _detailsByToken[tokenId][5],_detailsByToken[tokenId][6],_detailsByToken[tokenId][7]];
    }

    function setRenderer(address addr) external onlyOwner {
        rendererAddress = addr;
    }

    function setATIME(address addr) external onlyOwner {
        adventureTimeAddress = addr;
    }
    function setLostNamingAddress(address addr) external onlyOwner {
        lostNamingAddress = addr;
    }
    function withdrawErc20(IERC20 token) public onlyOwner {
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

    function getOrderFromLoot(uint256 tokenId, uint8 inventoryId) internal pure returns(uint256) {
        string memory keyPrefix;
        if (inventoryId == 0)
            keyPrefix = "WEAPON";
        else if (inventoryId == 1)
            keyPrefix = "CHEST";
        else if (inventoryId == 2)
            keyPrefix = "HEAD";
        else if (inventoryId == 3)
            keyPrefix = "WAIST";
        else if (inventoryId == 4)
            keyPrefix = "FOOT";
        else if (inventoryId == 5)
            keyPrefix = "HAND";
        else if (inventoryId == 6)
            keyPrefix = "NECK";
        else if (inventoryId == 7)
            keyPrefix = "RING";
        
        uint256 rand = random(string(abi.encodePacked(keyPrefix, Strings.toString(tokenId))));
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            return (rand % 16) + 1;
        } else {
            return 0;
        }
    }
    function random(string memory input) internal pure returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(input)));
    }
  
    function getLostManaNameUsed(Item memory lootItem) public view returns (uint256) {
        return lostNamingCount[lootItem.lootTokenId*10+lootItem.inventoryId];
    }
    function nameLostMana(uint256 tokenId, Item[] memory itemsToName) public payable {

        // check to see if item is available
        // check to see if there is enough atime
        require(_msgSender() == this.ownerOf(tokenId), "NOT_OWNER_OF_GA");
        uint256 amount = nameLostManaPrice*(10**18) * itemsToName.length;
        IERC20 atime = IERC20(adventureTimeAddress);
        require(atime.allowance(msg.sender, address(this)) >= amount, "NOT_ENOUGH_ATIME_APPROVED");
        uint256 index;
        IGenesisLostManaNaming lostMana = IGenesisLostManaNaming(lostNamingAddress);
        for (uint8 i = 0; i < itemsToName.length; i++) {
            require(_detailsByToken[tokenId][itemsToName[i].inventoryId] == 0, "IS_NOT_LOST_ITEM");
            index = itemsToName[i].lootTokenId*10+itemsToName[i].inventoryId;

            require(lostNamingCount[index] < lostMana.getMax(itemsToName[i].lootTokenId, itemsToName[i].inventoryId), "NO_MORE_LEFT_OR_INVALID_LOOT_ID");
            //verify it is the same order
            require(getOrderFromLoot(itemsToName[i].lootTokenId, itemsToName[i].inventoryId) == _detailsByToken[tokenId][8], "NEW_MANA_IS_WRONG_ORDER");
            lostNamingCount[index] += 1;
            _detailsByToken[tokenId][itemsToName[i].inventoryId] = itemsToName[i].lootTokenId;
        }
        atime.transferFrom(msg.sender, address(this), amount);
        emit NameLostMana(tokenId, itemsToName);
    }
    //---------------------------------- v2 end  -------------------------------------
    //---------------------------------- v3 start ------------------------------------
    uint256 public nameLostManaPrice;
    uint256 public nameAdventurerPrice;
    string[2540] private _gaNames;
    event NameAdventurer (uint256 tokenId, string name);

    function setNameLostManaPrice(uint256 price_) public onlyOwner {
        nameLostManaPrice = price_;
    }

    function setNameAdventurerPrice(uint256 price_) public onlyOwner {
        nameAdventurerPrice = price_;
    }
    function setName(uint256 tokenId, string memory name_) external {
        uint256 amount = nameAdventurerPrice*(10**18);
        IERC20 atime = IERC20(adventureTimeAddress);

        require(_msgSender() == this.ownerOf(tokenId), "NOT_OWNER_OF_GA");
        require(atime.allowance(msg.sender, address(this)) >= amount, "NOT_ENOUGH_ATIME_APPROVED");
        require(bytes(name_).length <= 42, "NAME_MAX_42_CHARS");
        _gaNames[tokenId] = name_;
        atime.transferFrom(msg.sender, address(this), amount);
        emit NameAdventurer(tokenId, name_);
    }

    function daoName(uint256 tokenId, string memory name_) external onlyOwner {
        require(bytes(name_).length <= 42, "NAME_MAX_42_CHARS");
        _gaNames[tokenId] = name_;
        emit NameAdventurer(tokenId, name_);
    }

    function getName(uint256 tokenId) external view returns (string memory) {
        if (bytes(_gaNames[tokenId]).length == 0) {
            return string(abi.encodePacked("Genesis Adventurer of ", this.getOrder(tokenId), " #", Strings.toString(tokenId)));
        } else {
            return _gaNames[tokenId];
        }
    }
    //---------------------------------- v3 end  -------------------------------------
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
