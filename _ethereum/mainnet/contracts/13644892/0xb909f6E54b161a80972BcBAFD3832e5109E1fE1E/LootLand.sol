// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./base64.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./ILootLand.sol";

contract LootLand is ILootLand, ERC721Enumerable, Ownable {
  Land[] private _lands;

  // packedXY => tokenId
  mapping(uint256 => uint256) private _packedXYToTokenId;

  // packedXY => bool
  mapping(uint256 => bool) private _packedXYToIsMinted;

  // givedAddress => tokenId
  mapping(address => uint256) private _gived;

  // mintedAddress => mint land tokenids
  mapping(address => uint256[]) private _mintLandTokenIds;

  // mintedAddress => mint count
  mapping(address => uint8) public override mintLandCount;

  uint256 public constant PRICE = 4669201609102000 wei;

  modifier hasGived() {
    require(
      _lands[_gived[_msgSender()]].isGived &&
        _lands[_gived[_msgSender()]].givedAddress == _msgSender(),
      "caller is no gived"
    );
    _;
  }

  constructor(address _owner, address _startUp)
    ERC721("LootLand", "LOOTLAND")
    Ownable()
  {
    transferOwnership(_owner);

    _lands.push(Land(0, 0, "", address(0), _startUp, true, true));
    _gived[_startUp] = 0;
    _packedXYToIsMinted[0] = true;
    _packedXYToTokenId[0] = 0;
    _safeMint(_startUp, 0);

    emit Mint(0, 0, address(0));
    emit GiveTo(0, 0, _startUp);
  }

  function mint(int128 x, int128 y) external payable override hasGived {
    _mint(x, y);
  }

  function mint2(
    int128 x1,
    int128 y1,
    int128 x2,
    int128 y2
  ) external payable override hasGived {
    _mint2(x1, y1, x2, y2);
  }

  function giveTo(
    int128 x,
    int128 y,
    address givedAddress
  ) external override hasGived {
    _giveTo(x, y, givedAddress);
  }

  function mintAndGiveTo(
    int128 x,
    int128 y,
    address givedAddress
  ) external payable override hasGived {
    _mint(x, y);
    _giveTo(x, y, givedAddress);
  }

  function mint2AndGiveTo(
    int128 x1,
    int128 y1,
    address givedAddress1,
    int128 x2,
    int128 y2,
    address givedAddress2
  ) external payable override hasGived {
    _mint2(x1, y1, x2, y2);
    _giveTo(x1, y1, givedAddress1);
    _giveTo(x2, y2, givedAddress2);
  }

  function setSlogan(
    int128 x,
    int128 y,
    string memory slogan
  ) external override {
    uint256 tokenId = getTokenId(x, y);

    require(ownerOf(tokenId) == _msgSender(), "land is not belong to caller");
    require(bytes(slogan).length < 256, "slogan is too long");

    _lands[tokenId].slogan = slogan;

    emit SetSlogan(x, y, slogan);
  }

  function getAllEth() external override onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
  }

  function getEth(uint256 value) external override onlyOwner {
    if (value <= address(this).balance) {
      payable(_msgSender()).transfer(value);
    }
  }

  function land(int128 _x, int128 _y)
    external
    view
    override
    returns (Land memory _land)
  {
    uint256 _packedXY = packedXY(_x, _y);
    if (_packedXYToIsMinted[_packedXY]) {
      uint256 tokenId = _packedXYToTokenId[_packedXY];
      Land memory queryLand = _lands[tokenId];
      _land = queryLand;
    } else {
      _land = Land(_x, _y, "", address(0), address(0), false, false);
    }
  }

  function givedLand(address _givedAddress)
    external
    view
    override
    returns (bool isGived, Land memory _land)
  {
    uint256 tokenId = _gived[_givedAddress];
    Land memory queryLand = _lands[tokenId];
    if (queryLand.givedAddress == _givedAddress) {
      isGived = true;
      _land = queryLand;
    } else {
      isGived = false;
      _land = Land(0, 0, "", address(0), address(0), false, false);
    }
  }

  function getMintLands(address _mintedAddress)
    external
    view
    override
    returns (Land[] memory _mintLands)
  {
    uint256[] memory tokenIds = _mintLandTokenIds[_mintedAddress];
    _mintLands = new Land[](tokenIds.length);
    for (uint8 index = 0; index < tokenIds.length; index++) {
      _mintLands[index] = _lands[tokenIds[index]];
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory result)
  {
    (int128 x, int128 y) = getCoordinates(tokenId);

    string memory _slogan;
    if (!_lands[tokenId].isGived) {
      _slogan = "YOU are invited to BE a lootverse builder for the next 10 years!<br/>To Make It Happen I minted:";
    } else {
      if (bytes(_lands[tokenId].slogan).length > 0) {
        _slogan = _lands[tokenId].slogan;
      } else {
        _slogan = "<br/>I'm this Builder  ^_^";
      }
    }

    string memory _sloganStr = string(
      abi.encodePacked('<div class="sologan">', _slogan, "</div>")
    );

    string memory _landStr = string(
      abi.encodePacked(
        '<div class="land">LootLand ',
        _getTokenIdAndCoordinatesString(tokenId, x, y),
        "</div>"
      )
    );

    string memory _notesStr = string(
      abi.encodePacked(
        '<div class="notes"><ul>',
        _getInviteByStr(tokenId),
        _getMintAndGiveToStr(tokenId),
        '<li>Neighbors:</li></ul><div class="b">',
        _getNeighborsStr(x, y),
        "</div><ul><li>The value of the land is determined by the neighbors, so please invite with care!</li></ul></div>"
      )
    );

    string memory svgStr = string(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 360 360"><rect width="100%" height="100%" fill="#0F4C81" /><foreignObject width="360" height="360" x="0" y="0"><body xmlns="http://www.w3.org/1999/xhtml"><style>.base{font-family:sans-serif;margin:10px;}.sologan{color:#F0EDE5;font-size:16px;line-height:25px;height:75px;margin-top:35px;}.land{color:#C0D725;font-size:24px;line-height:35px;margin-top:0px;}.notes{color:#A5B8D0;font-size:12px;margin-top:10px;}ul{list-style-type:disc;margin:0 0 0 -20px;}.b{margin:5px;justify-content: center;display:grid;grid-template-columns:repeat(3,max-content);grid-template-row:repeat(3,auto);grid-column-gap:5px;justify-items:start;}</style><div class="base">',
        _sloganStr,
        _landStr,
        _notesStr,
        "</div></body></foreignObject></svg>"
      )
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Land #',
            Strings.toString(tokenId),
            '", "description": "Lootland is the home of builders,builders are invited-only,Each builder can mint at most two piece of land,the minted lands can only be used for invitation,only one person can be invited to each piece of land,each person can only accept an invitation once! It is a land space with (x,y) as coordinates. The positive x-axis is east and negative is west, the positive y-axis is north and negative is south, the values of x and y can only be integers, there is no range limit, each coordinate position represents an area of 100 x 100 square meters.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svgStr)),
            '"}'
          )
        )
      )
    );
    result = string(abi.encodePacked("data:application/json;base64,", json));
  }

  function getTokenId(int128 x, int128 y)
    public
    view
    override
    returns (uint256 tokenId)
  {
    uint256 _packedXY = packedXY(x, y);
    require(_packedXYToIsMinted[_packedXY], "land not minted");
    tokenId = _packedXYToTokenId[_packedXY];
  }

  function packedXY(int128 x, int128 y)
    public
    pure
    override
    returns (uint256 _packedXY)
  {
    bytes32 xx = bytes16(uint128(x));
    bytes32 yy = bytes16(uint128(y));
    _packedXY = uint256(xx | (yy >> 128));
  }

  function getCoordinates(uint256 tokenId)
    public
    view
    override
    returns (int128 x, int128 y)
  {
    require(tokenId < _lands.length, "not exists");
    x = _lands[tokenId].x;
    y = _lands[tokenId].y;
  }

  function getCoordinatesStrings(int128 x, int128 y)
    public
    pure
    override
    returns (string memory sx, string memory sy)
  {
    string memory xPrefix = "";
    if (x > 0) {
      xPrefix = "E";
    }
    if (x < 0) {
      xPrefix = "W";
    }

    string memory xStr;
    if (x >= 0) {
      xStr = Strings.toString(uint256(int256(x)));
    } else {
      unchecked {
        xStr = Strings.toString(uint256(-int256(x)));
      }
    }

    string memory yPrefix = "";
    if (y > 0) {
      yPrefix = "N";
    }
    if (y < 0) {
      yPrefix = "S";
    }

    string memory yStr;
    if (y >= 0) {
      yStr = Strings.toString(uint256(int256(y)));
    } else {
      unchecked {
        yStr = Strings.toString(uint256(-int256(y)));
      }
    }

    sx = string(abi.encodePacked(xPrefix, xStr));
    sy = string(abi.encodePacked(yPrefix, yStr));
  }

  function _giveTo(
    int128 x,
    int128 y,
    address givedAddress
  ) private {
    uint256 tokenId = getTokenId(x, y);

    require(
      _lands[tokenId].mintedAddress == _msgSender(),
      "caller didn't minted this land"
    );
    require(!_lands[tokenId].isGived, "land is gived");

    require(
      _lands[_gived[givedAddress]].givedAddress != givedAddress,
      "givedAddress have gived land"
    );

    _lands[tokenId].givedAddress = givedAddress;
    _lands[tokenId].isGived = true;
    _gived[givedAddress] = tokenId;

    _safeMint(givedAddress, tokenId);

    emit GiveTo(x, y, givedAddress);
  }

  function _mint2(
    int128 x1,
    int128 y1,
    int128 x2,
    int128 y2
  ) private {
    require(msg.value >= PRICE * 2, "eth too less");

    _mintWithoutEth(x1, y1);
    _mintWithoutEth(x2, y2);

    if (msg.value > PRICE * 2) {
      payable(_msgSender()).transfer(msg.value - PRICE * 2);
    }
  }

  function _mint(int128 x, int128 y) private {
    require(msg.value >= PRICE, "eth too less");

    _mintWithoutEth(x, y);

    if (msg.value > PRICE) {
      payable(_msgSender()).transfer(msg.value - PRICE);
    }
  }

  function _mintWithoutEth(int128 x, int128 y) private {
    require(mintLandCount[_msgSender()] < 2, "caller is already minted");

    uint256 _packedXY = packedXY(x, y);

    require(!_packedXYToIsMinted[_packedXY], "land is minted");

    _lands.push(Land(x, y, "", _msgSender(), address(0), true, false));

    uint256 newTokenId = _lands.length - 1;
    _mintLandTokenIds[_msgSender()].push(newTokenId);
    mintLandCount[_msgSender()] += 1;

    _packedXYToTokenId[_packedXY] = newTokenId;
    _packedXYToIsMinted[_packedXY] = true;

    emit Mint(x, y, _msgSender());
  }

  function _getInviteByStr(uint256 tokenId)
    private
    view
    returns (string memory _str)
  {
    string memory _var;
    address mintedAddress = _lands[tokenId].mintedAddress;
    if (mintedAddress == address(0)) {
      _var = "Loot";
    } else {
      Land memory _ql = _lands[_gived[mintedAddress]];
      _var = _getTokenIdAndCoordinatesString(
        _gived[mintedAddress],
        _ql.x,
        _ql.y
      );
    }
    _str = string(abi.encodePacked("<li>Invited by ", _var, "</li>"));
  }

  function _getMintAndGiveToStr(uint256 tokenId)
    private
    view
    returns (string memory _str)
  {
    address _givedAddress = _lands[tokenId].givedAddress;
    uint256[] memory tokenIds = _mintLandTokenIds[_givedAddress];
    string memory _mintStr = "";
    string memory _giveToStr = "";
    if (tokenIds.length != 0) {
      for (uint8 i = 0; i < tokenIds.length; i++) {
        Land memory qLand = _lands[tokenIds[i]];
        if (qLand.isGived) {
          _giveToStr = string(
            abi.encodePacked(
              _giveToStr,
              " ",
              _getTokenIdAndCoordinatesString(tokenIds[i], qLand.x, qLand.y)
            )
          );
        } else {
          _mintStr = string(
            abi.encodePacked(
              _mintStr,
              " ",
              _getCoordinatesString(qLand.x, qLand.y)
            )
          );
        }
      }
      _str = string(
        abi.encodePacked(
          bytes(_mintStr).length == 0
            ? ""
            : string(abi.encodePacked("<li>Mint", _mintStr, "</li>")),
          bytes(_giveToStr).length == 0
            ? ""
            : string(abi.encodePacked("<li>Giveto", _giveToStr, "</li>"))
        )
      );
    }
  }

  function _getNeighborsStr(int128 x, int128 y)
    private
    view
    returns (string memory _str)
  {
    string[8] memory _arr = _getNeighborsStrArr(x, y);
    _str = string(
      abi.encodePacked(
        _arr[0],
        _arr[1],
        _arr[2],
        _arr[3],
        "<div>Me</div>",
        _arr[4],
        _arr[5],
        _arr[6],
        _arr[7]
      )
    );
  }

  /**
      (c1)x-1, y+1   (c2)x, y+1  (c3)x+1, y+1   
      (c4)x-1, y     (c5)x, y    (c6)x+1, y
      (c7)x-1, y-1   (c8)x, y-1  (c9)x+1, y-1
     */
  function _getNeighborsStrArr(int128 x, int128 y)
    private
    view
    returns (string[8] memory _arr)
  {
    bool xIsMax = type(int128).max == x;
    bool yIsMax = type(int128).max == y;
    bool xIsMin = type(int128).min == x;
    bool yIsMin = type(int128).min == y;
    string memory empty = "<div>#</div>";

    _arr[0] = (xIsMin || yIsMax) ? empty : _getTokenIdStr(x - 1, y + 1);
    _arr[1] = yIsMax ? empty : _getTokenIdStr(x, y + 1);
    _arr[2] = (xIsMax || yIsMax) ? empty : _getTokenIdStr(x + 1, y + 1);
    _arr[3] = xIsMin ? empty : _getTokenIdStr(x - 1, y);
    _arr[4] = xIsMax ? empty : _getTokenIdStr(x + 1, y);
    _arr[5] = (xIsMin || yIsMin) ? empty : _getTokenIdStr(x - 1, y - 1);
    _arr[6] = yIsMin ? empty : _getTokenIdStr(x, y - 1);
    _arr[7] = xIsMax || yIsMin ? empty : _getTokenIdStr(x + 1, y - 1);
  }

  function _getTokenIdStr(int128 x, int128 y)
    private
    view
    returns (string memory _str)
  {
    uint256 _packedXY = packedXY(x, y);

    if (_packedXYToIsMinted[_packedXY]) {
      _str = string(
        abi.encodePacked("#", Strings.toString(_packedXYToTokenId[_packedXY]))
      );
    } else {
      _str = "#";
    }

    _str = string(abi.encodePacked("<div>", _str, "</div>"));
  }

  function _getTokenIdAndCoordinatesString(
    uint256 tokenId,
    int128 x,
    int128 y
  ) private pure returns (string memory _str) {
    _str = string(
      abi.encodePacked(
        "#",
        Strings.toString(tokenId),
        _getCoordinatesString(x, y)
      )
    );
  }

  function _getCoordinatesString(int128 x, int128 y)
    private
    pure
    returns (string memory _str)
  {
    (string memory sx, string memory sy) = getCoordinatesStrings(x, y);
    _str = string(abi.encodePacked("(", sx, ",", sy, ")"));
  }
}
