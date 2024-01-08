// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";
import "./console.sol";

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

contract GenesisAdventurer is ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {

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
          [0,0],    // 0
          [166,0],  // 1
          [173,0],  // 2
          [163,0],  // 3
          [157,0],  // 4
          [160,0],  // 5
          [152,0],  // 6
          [151,0],  // 7
          [162,0],  // 8
          [160,0],  // 9
          [149,0],  // 10
          [165,0],  // 11
          [162,0],  // 12
          [160,0],  // 13
          [156,0],  // 14
          [154,0],  // 15
          [150,0]   // 16
      ];

      publicPrice = _initialPrice;
     }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
      require(
        (tokenId > 0 && tokenId <= _currentTokenId),
        "TOKEN_ID_NOT_MINTED"
      );

      string[23] memory parts;
      string memory name = string(abi.encodePacked('Genesis Adventurer #', Strings.toString(tokenId)));

      parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; widht: 350px} .italic {font-style: italic}</style><rect width="100%" height="100%" fill="#000"/><rect y="300" width="350" height="50" fill="';
      parts[1] = getOrderColor(tokenId);
      parts[2] = '"/><text x="10" y="20" class="base">';
      parts[3] = getWeapon(tokenId);
      parts[4] = '</text><text x="10" y="40" class="base">';
      parts[5] = getChest(tokenId);
      parts[6] = '</text><text x="10" y="60" class="base">';
      parts[7] = getHead(tokenId);
      parts[8] = '</text><text x="10" y="80" class="base">';
      parts[9] = getWaist(tokenId);
      parts[10] = '</text><text x="10" y="100" class="base">';
      parts[11] = getFoot(tokenId);
      parts[12] = '</text><text x="10" y="120" class="base">';
      parts[13] = getHand(tokenId);
      parts[14] = '</text><text x="10" y="140" class="base">';
      parts[15] = getNeck(tokenId);
      parts[16] = '</text><text x="10" y="160" class="base">';
      parts[17] = getRing(tokenId);
      parts[18] = '</text><text x="10" y="330" class="base italic">Genesis Adventurer of ';
      parts[19] = getOrder(tokenId);
      parts[20] = ' ';
      parts[21] = getOrderCount(tokenId);
      parts[22] = '</text></svg>';

      string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
      output = string(abi.encodePacked(output, parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
      output = string(abi.encodePacked(output, parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
      output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22]));
      string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', name, '", "description": "This item is a Genesis Adventurer used in Loot (for Adventurers)", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
      output = string(abi.encodePacked('data:application/json;base64,', json));
      return output;
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
            return string(abi.encodePacked("Lost Food Armor of ", getOrder(tokenId)));
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
