// SPDX-License-Identifier: Unlicense

/*
    Glyph Pets inspires by WAGMIpet NFT by m1guelpf.eth, which was
    inspired by dhof.eth's wagmipet contract (mainnet:0xecb504d39723b0be0e3a9aa33d646642d1051ee1)
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract GlyphPets is Ownable, ERC721Enumerable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  event CaretakerLoved(
    address indexed caretaker,
    uint256 indexed tokenId,
    uint256 amount
  );

  struct Pet {
    uint256 lastFeedBlock;
    uint256 lastCleanBlock;
    uint256 lastPlayBlock;
    uint256 lastSleepBlock;
    uint8 hunger;
    uint8 uncleanliness;
    uint8 boredom;
    uint8 sleepiness;
  }

  mapping(uint256 => Pet) internal pets;

  mapping(address => uint256) public love;

  ERC721 lilglyphs;

  constructor(address lilGlyphAddress) ERC721("Glyph Pets", "GP") {
    lilglyphs = ERC721(lilGlyphAddress);
  }

  function glyphInPlay(uint256 tokenId) public view returns (bool) {
    require(_exists(tokenId), "token id invalid");
    return getAlive(tokenId);
  }

  function adopt(uint256 tokenId) public returns (uint256) {
    bool exists = _exists(tokenId);
    if (exists) {
      require(!getAlive(tokenId) && ownerOf(tokenId) == msg.sender, "in play");
    } else {
      require(lilglyphs.ownerOf(tokenId) == _msgSender(), "not owned");
    }
    pets[tokenId] = Pet(
      block.number,
      block.number,
      block.number,
      block.number,
      0,
      0,
      0,
      0
    );
    if (!exists) {
      _mint(_msgSender(), tokenId);
    }
    return tokenId;
  }

  function addLove(
    address caretaker,
    uint256 tokenId,
    uint256 amount
  ) internal {
    love[caretaker] += amount;

    emit CaretakerLoved(caretaker, tokenId, amount);
  }

  function feed(uint256 tokenId) public {
    require(_exists(tokenId), "pet does not exist");
    require(ownerOf(tokenId) == _msgSender(), "not your pet");
    require(getHunger(tokenId) > 0, "i dont need to eat");
    require(getAlive(tokenId), "no longer with us");
    require(getBoredom(tokenId) < 80, "im too tired to eat");
    require(getUncleanliness(tokenId) < 80, "im feeling too gross to eat");
    require(getHunger(tokenId) > 0, "i dont need to eat");

    pets[tokenId].lastFeedBlock = block.number;

    pets[tokenId].hunger = 0;
    pets[tokenId].boredom += 10;
    pets[tokenId].uncleanliness += 3;

    addLove(_msgSender(), tokenId, 1);
  }

  function clean(uint256 tokenId) public {
    require(_exists(tokenId), "pet does not exist");
    require(ownerOf(tokenId) == _msgSender(), "not your pet");
    require(getAlive(tokenId), "no longer with us");
    require(getUncleanliness(tokenId) > 0, "i dont need a bath");

    pets[tokenId].lastCleanBlock = block.number;
    pets[tokenId].uncleanliness = 0;

    addLove(_msgSender(), tokenId, 1);
  }

  function play(uint256 tokenId) public {
    require(_exists(tokenId), "pet does not exist");
    require(ownerOf(tokenId) == _msgSender(), "not your pet");
    require(getAlive(tokenId), "no longer with us");
    require(getHunger(tokenId) < 80, "im too hungry to play");
    require(getSleepiness(tokenId) < 80, "im too sleepy to play");
    require(getUncleanliness(tokenId) < 80, "im feeling too gross to play");
    require(getBoredom(tokenId) > 0, "i dont wanna play");

    pets[tokenId].lastPlayBlock = block.number;

    pets[tokenId].boredom = 0;
    pets[tokenId].hunger += 10;
    pets[tokenId].sleepiness += 10;
    pets[tokenId].uncleanliness += 5;

    addLove(_msgSender(), tokenId, 1);
  }

  function sleep(uint256 tokenId) public {
    require(_exists(tokenId), "pet does not exist");
    require(ownerOf(tokenId) == _msgSender(), "not your pet");
    require(getAlive(tokenId), "no longer with us");
    require(getUncleanliness(tokenId) < 80, "im feeling too gross to sleep");
    require(getSleepiness(tokenId) > 0, "im not feeling sleepy");

    pets[tokenId].lastSleepBlock = block.number;

    pets[tokenId].sleepiness = 0;
    pets[tokenId].uncleanliness += 5;

    addLove(_msgSender(), tokenId, 1);
  }

  function getStatus(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "pet does not exist");

    uint256 mostNeeded = 0;

    string[5] memory goodStatus = [
      "gm",
      "im feeling great",
      "we gmi",
      "all good",
      "i love u"
    ];

    string memory status = goodStatus[block.number % 5];

    uint256 hunger = getHunger(tokenId);
    uint256 uncleanliness = getUncleanliness(tokenId);
    uint256 boredom = getBoredom(tokenId);
    uint256 sleepiness = getSleepiness(tokenId);

    if (getAlive(tokenId) == false) {
      return "no longer with us";
    }

    if (hunger > 50 && hunger > mostNeeded) {
      mostNeeded = hunger;
      status = "im hungry";
    }

    if (uncleanliness > 50 && uncleanliness > mostNeeded) {
      mostNeeded = uncleanliness;
      status = "i need a bath";
    }

    if (boredom > 50 && boredom > mostNeeded) {
      mostNeeded = boredom;
      status = "im bored";
    }

    if (sleepiness > 50 && sleepiness > mostNeeded) {
      mostNeeded = sleepiness;
      status = "im sleepy";
    }

    return status;
  }

  function getAlive(uint256 tokenId) public view returns (bool) {
    require(_exists(tokenId), "pet does not exist");
    return
      getHunger(tokenId) < 101 &&
      getUncleanliness(tokenId) < 101 &&
      getBoredom(tokenId) < 101 &&
      getSleepiness(tokenId) < 101;
  }

  function getHunger(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "pet does not exist");

    return
      pets[tokenId].hunger +
      ((block.number - pets[tokenId].lastFeedBlock) / 400);
  }

  function getUncleanliness(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "pet does not exist");

    return
      pets[tokenId].uncleanliness +
      ((block.number - pets[tokenId].lastCleanBlock) / 400);
  }

  function getBoredom(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "pet does not exist");

    return
      pets[tokenId].boredom +
      ((block.number - pets[tokenId].lastPlayBlock) / 400);
  }

  function getSleepiness(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "pet does not exist");

    return
      pets[tokenId].sleepiness +
      ((block.number - pets[tokenId].lastSleepBlock) / 400);
  }

  function getStats(uint256 tokenId) public view returns (uint256[5] memory) {
    return [
      getAlive(tokenId) ? 1 : 0,
      getHunger(tokenId),
      getUncleanliness(tokenId),
      getBoredom(tokenId),
      getSleepiness(tokenId)
    ];
  }

  function countNeighbors(
    uint256 id,
    uint256 idx,
    uint256 index
  ) internal pure returns (uint256) {
    uint256 top = idx >= 5 ? getBoolean(id, idx - 5) : 0;
    uint256 bottom = idx <= 44 ? getBoolean(id, idx + 5) : 0;
    uint256 left = idx > 0 && index != 0 ? getBoolean(id, idx - 1) : 0;
    uint256 right = idx < 49 && index != 4 ? getBoolean(id, idx + 1) : 0;
    return top + bottom + left + right;
  }

  function setBoolean(
    uint256 _packedBools,
    uint256 _boolNumber,
    uint256 _value
  ) public pure returns (uint256) {
    if (_value == 1) return _packedBools | (uint256(1) << _boolNumber);
    else return _packedBools & ~(uint256(1) << _boolNumber);
  }

  function getBoolean(uint256 _packedBools, uint256 _boolNumber)
    public
    pure
    returns (uint256)
  {
    uint256 flag = (_packedBools >> _boolNumber) & uint256(1);
    return flag;
  }

  string[] baseColors = [
    "#FFD12A",
    "#4F86F7",
    "#FFD3F8",
    "#DA2647",
    "#FFFF31",
    "#44D7A8",
    "#A6E7FF",
    "#6F2DA8",
    "#DA614E",
    "#253529",
    "#1A1110",
    "#B2F302",
    "#214FC6",
    "#FF5050",
    "#0048BA",
    "#B0BF1A",
    "#7CB9E8",
    "#C0E8D5",
    "#B284BE",
    "#FF7E00",
    "#9966CC",
    "#66FF00"
  ];

  string[] buttonColors = [
    "#FF3855",
    "#FFAA1D",
    "#FFF700",
    "#299617",
    "#FF5470",
    "#BFAFB2",
    "#E936A7",
    "#66FF66",
    "#FF00CC",
    "#848482",
    "#318CE7",
    "#66FF00",
    "#FB607F"
  ];

  function compareStr(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
  }

  function getSvg(uint256 tokenId) public view returns (string memory) {
    uint256 ppd = 5;
    string memory svg;
    for (uint256 i = 0; i < 50; i++) {
      uint256 x = (i - ((i / 5) * 5));
      if (getBoolean(tokenId, i) == 1) {
        continue;
      } else if (countNeighbors(tokenId, i, x) > 0) {
        string memory color1 = "3B2F2F";
        string memory color2 = "3B2F2F";
        string memory status = getStatus(tokenId);

        if (!getAlive(tokenId)) {
          color1 = "DEAD";
          color2 = color1;
        } else if (compareStr(status, "im hungry")) {
          color1 = "E52B50";
          color2 = "FFBF00";
        } else if (compareStr(status, "i need a bath")) {
          color1 = "9F8170";
          color2 = color1;
        } else if (compareStr(status, "im bored")) {
          color1 = "FB607F";
          color2 = color1;
        } else if (compareStr(status, "im sleepy")) {
          color1 = "8A2BE2";
          color2 = color1;
        }

        string memory rect = string(
          abi.encodePacked(
            '<rect x="',
            Strings.toString(x * ppd),
            '" y="',
            Strings.toString((i / 5) * ppd),
            '" width="5" height="5" style="fill:#',
            color1,
            '"></rect>'
          )
        );
        string memory rectFlip = string(
          abi.encodePacked(
            '<rect data-id="',
            Strings.toString(i),
            '" x="',
            Strings.toString((10 - x - 1) * ppd),
            '" y="',
            Strings.toString((i / 5) * ppd),
            '" width="5" height="5" style="fill:#',
            color2,
            '"></rect>'
          )
        );

        svg = string(abi.encodePacked(svg, rect, rectFlip));
      } else {
        continue;
      }
    }

    string[5] memory wrap;

    wrap[0] = string(
      abi.encodePacked(
        '<svg fill="#FFF" height="270" viewBox="0 0 210 270" width="210" xmlns="http://www.w3.org/2000/svg">  <defs><linearGradient id="g" gradientTransform="rotate(',
        Strings.toString(tokenId % 180),
        ')"><stop offset="5%"  stop-color="',
        baseColors[(tokenId / 2) % baseColors.length],
        '" /><stop offset="95%" stop-color="',
        baseColors[(tokenId) % baseColors.length],
        '" /></linearGradient></defs><g><rect width="210" height="270"></rect><path fill="url(#g)" d="m105 0c10.2 0 18.9 8.4 18.6 18.6 0 2.1-.3 4.2-.9 6 49.5 12 87.3 72.9 87.3 146.4 0 54.6-47.1 99-105 99s-105-44.4-105-99c0-73.5 37.8-134.4 87-146.1-.6-1.8-.9-3.9-.9-6 0-10.5 8.7-18.9 18.9-18.9zm45 97.5h-90c-4.2 0-7.5 3.3-7.5 7.5v90c0 4.2 3.3 7.5 7.5 7.5h90c4.2 0 7.5-3.3 7.5-7.5v-90c0-4.2-3.3-7.5-7.5-7.5zm-45-86.1c-4.2 0-7.5 3.3-7.5 7.5s3.3 7.5 7.5 7.5 7.5-3.3 7.5-7.5-3.3-7.5-7.5-7.5z"/><g transform="translate(80 125)">'
      )
    );

    if (getAlive(tokenId)) {
      wrap[1] = string(
        abi.encodePacked(
          '<animateTransform xmlns="http://www.w3.org/2000/svg" attributeName="transform" attributeType="XML" type="translate" dur=".9s" repeatCount="indefinite" autoReverse="true" values="80 125; 80 122; 80 125;"/>',
          svg,
          "</g>"
        )
      );
    } else {
      wrap[1] = string(abi.encodePacked(svg, "</g>"));
    }

    wrap[2] = string(
      abi.encodePacked(
        '<g fill="',
        buttonColors[tokenId % buttonColors.length],
        '">'
      )
    );
    wrap[
      3
    ] = '<path d="m75 247.5c-4.2 0-7.5-3.3-7.5-7.5s3.3-7.5 7.5-7.5 7.5 3.3 7.5 7.5-3.3 7.5-7.5 7.5z"/><path d="m105 255c-4.2 0-7.5-3.3-7.5-7.5s3.3-7.5 7.5-7.5 7.5 3.3 7.5 7.5-3.3 7.5-7.5 7.5z"/><path d="m135 247.5c-4.2 0-7.5-3.3-7.5-7.5s3.3-7.5 7.5-7.5 7.5 3.3 7.5 7.5-3.3 7.5-7.5 7.5z"/>';
    wrap[4] = "</g></g></svg>";

    return
      string(abi.encodePacked(wrap[0], wrap[1], wrap[2], wrap[3], wrap[4]));
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(_exists(tokenId), "pet does not exist");

    // solhint-disable-next-line quotes
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Glyph Pet #',
            Strings.toString(tokenId),
            '", "background_color": "FFFFFF", "description": "Glyph Pets are virtual pets living on the blockchain.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(getSvg(tokenId))),
            '"}'
          )
        )
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }
}

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
