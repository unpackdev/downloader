// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Utils.sol";
import "./IPeopleLand.sol";
import "./ITokenSVG.sol";

contract PeopleLand is IPeopleLand, ERC721Enumerable, Ownable {
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

  mapping(address => bool) public override isPeople;

  mapping(address => bool) public override isBuilder;

  address public override tokenSVGAddress;

  uint256 public constant PRICE = 0.66 ether;

  address public constant SIGN_MESSAGE_ADDRESS =
    0x9d74d0D4bf55bA7E50a0600b7630c36Cab8A2a69;

  bool public mintSelfSwitch;

  modifier hasGived() {
    require(
      _lands[_gived[_msgSender()]].isGived &&
        _lands[_gived[_msgSender()]].givedAddress == _msgSender(),
      "caller is no gived"
    );
    _;
  }

  modifier notPeopleReserved(int128 x, int128 y) {
    require(
      !((-31 < x && x < 31) && (-31 < y && y < 31)),
      "land is people reserved"
    );
    _;
  }

  modifier notReserved(int128 x, int128 y) {
    require(!((-3 < x && x < 3) && (-3 < y && y < 3)), "land is reserved");
    _;
  }

  modifier isReserved(int128 x, int128 y) {
    require((-3 < x && x < 3) && (-3 < y && y < 3), "land is not reserved");
    _;
  }

  constructor(
    address _owner,
    address _startUp,
    address _tokenSVG
  ) ERC721("People's Land", "PEOPLELAND") Ownable() {
    transferOwnership(_owner);

    tokenSVGAddress = _tokenSVG;

    _lands.push(Land(0, 0, "", address(0), _startUp, true, true));
    _gived[_startUp] = 0;
    _packedXYToIsMinted[0] = true;
    _packedXYToTokenId[0] = 0;
    _safeMint(_startUp, 0);
    isBuilder[_startUp] = true;

    emit Mint(0, 0, address(0));
    emit GiveTo(0, 0, _startUp);
  }

  function mintToSelf(
    int128 x,
    int128 y,
    bytes32 messageHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override notReserved(x, y) {
    require(mintSelfSwitch, "close");

    require(_verifyWhitelist(messageHash, v, r, s), "not in whitelist");

    require(
      _lands[_gived[_msgSender()]].givedAddress != _msgSender(),
      "caller is minted or have gived"
    );

    uint256 _packedXY = packedXY(x, y);
    require(!_packedXYToIsMinted[_packedXY], "land is minted");

    isPeople[_msgSender()] = true;

    _lands.push(Land(x, y, "", address(0), _msgSender(), true, true));
    uint256 newTokenId = _lands.length - 1;

    _packedXYToIsMinted[_packedXY] = true;
    _packedXYToTokenId[_packedXY] = newTokenId;
    _gived[_msgSender()] = newTokenId;

    _safeMint(_msgSender(), newTokenId);

    emit Mint(x, y, address(0));
    emit GiveTo(x, y, _msgSender());
  }

  function mintToBuilderByOwner(
    int128 x,
    int128 y,
    address givedAddress
  ) external override onlyOwner isReserved(x, y) {
    _mintToBuilderByOwner(x, y, givedAddress, "");
  }

  function mintToBuilderByOwnerWithSlogan(
    int128 x,
    int128 y,
    address givedAddress,
    string memory slogan
  ) external override onlyOwner isReserved(x, y) {
    _mintToBuilderByOwner(x, y, givedAddress, slogan);
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
    _giveTo(x, y, givedAddress, "");
  }

  function mintAndGiveTo(
    int128 x,
    int128 y,
    address givedAddress
  ) external payable override hasGived {
    _mint(x, y);
    _giveTo(x, y, givedAddress, "");
  }

  function mintAndGiveToWithSlogan(
    int128 x,
    int128 y,
    address givedAddress,
    string memory slogan
  ) external payable override hasGived {
    _mint(x, y);
    _giveTo(x, y, givedAddress, slogan);
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
    _giveTo(x1, y1, givedAddress1, "");
    _giveTo(x2, y2, givedAddress2, "");
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

  function setTokenSVGAddress(address _attr) external override onlyOwner {
    tokenSVGAddress = _attr;
  }

  function openMintSelfSwitch() external override onlyOwner {
    mintSelfSwitch = true;
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

    (bool _ip, bool _ib, ITokenSVG.TokenInfo memory _invite) = getInviteParams(
      tokenId
    );

    ITokenSVG.Meta memory meta = ITokenSVG.Meta(
      x,
      y,
      tokenId,
      _lands[tokenId].slogan,
      _ip,
      _ib,
      _invite,
      getMintedAndInvitedList(tokenId),
      getNeighborsParams(x, y)
    );

    result = ITokenSVG(tokenSVGAddress).tokenMeta(meta);
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
    view
    override
    returns (string memory sx, string memory sy)
  {
    (sx, sy) = ITokenSVG(tokenSVGAddress).getCoordinatesStrings(x, y);
  }

  function _mintToBuilderByOwner(
    int128 x,
    int128 y,
    address givedAddress,
    string memory slogan
  ) private {
    require(
      _lands[_gived[givedAddress]].givedAddress != givedAddress,
      "givedAddress is minted or have gived"
    );

    uint256 _packedXY = packedXY(x, y);
    require(!_packedXYToIsMinted[_packedXY], "land is minted");

    _lands.push(Land(x, y, "", address(0), givedAddress, true, true));
    uint256 newTokenId = _lands.length - 1;

    _packedXYToIsMinted[_packedXY] = true;
    _packedXYToTokenId[_packedXY] = newTokenId;
    _gived[givedAddress] = newTokenId;

    _safeMint(givedAddress, newTokenId);

    isBuilder[givedAddress] = true;

    if (bytes(slogan).length > 0) {
      _lands[newTokenId].slogan = slogan;
    }

    emit Mint(x, y, address(0));
    emit GiveTo(x, y, givedAddress);
  }

  function _giveTo(
    int128 x,
    int128 y,
    address givedAddress,
    string memory slogan
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

    if (bytes(slogan).length > 0) {
      _lands[tokenId].slogan = slogan;
    }

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

  function _mintWithoutEth(int128 x, int128 y) private notPeopleReserved(x, y) {
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

  function getNeighborsParams(int128 x, int128 y)
    public
    view
    returns (string[] memory tokenIds)
  {
    tokenIds = new string[](8);

    bool xIsMax = type(int128).max == x;
    bool yIsMax = type(int128).max == y;
    bool xIsMin = type(int128).min == x;
    bool yIsMin = type(int128).min == y;
    string memory empty = "";

    tokenIds[0] = (xIsMin || yIsMax) ? empty : _getTokenIdStr(x - 1, y + 1);
    tokenIds[1] = yIsMax ? empty : _getTokenIdStr(x, y + 1);
    tokenIds[2] = (xIsMax || yIsMax) ? empty : _getTokenIdStr(x + 1, y + 1);
    tokenIds[3] = xIsMin ? empty : _getTokenIdStr(x - 1, y);
    tokenIds[4] = xIsMax ? empty : _getTokenIdStr(x + 1, y);
    tokenIds[5] = (xIsMin || yIsMin) ? empty : _getTokenIdStr(x - 1, y - 1);
    tokenIds[6] = yIsMin ? empty : _getTokenIdStr(x, y - 1);
    tokenIds[7] = xIsMax || yIsMin ? empty : _getTokenIdStr(x + 1, y - 1);
  }

  function getInviteParams(uint256 tokenId)
    public
    view
    returns (
      bool _ip,
      bool _ib,
      ITokenSVG.TokenInfo memory _invite
    )
  {
    address mintedAddress = _lands[tokenId].mintedAddress;
    address givedAddress = _lands[tokenId].givedAddress;

    _invite = ITokenSVG.TokenInfo(
      _lands[_gived[mintedAddress]].x,
      _lands[_gived[mintedAddress]].y,
      _gived[mintedAddress],
      _lands[_gived[mintedAddress]].isGived
    );

    _ip = isPeople[givedAddress];
    _ib = isBuilder[givedAddress];
  }

  function getMintedAndInvitedList(uint256 tokenId)
    public
    view
    returns (ITokenSVG.TokenInfo[] memory _list)
  {
    address _givedAddress = _lands[tokenId].givedAddress;
    uint256[] memory tokenIds = _mintLandTokenIds[_givedAddress];

    _list = new ITokenSVG.TokenInfo[](tokenIds.length);

    if (tokenIds.length != 0) {
      for (uint8 i = 0; i < tokenIds.length; i++) {
        Land memory qLand = _lands[tokenIds[i]];
        if (qLand.isGived) {
          _list[i] = ITokenSVG.TokenInfo(
            qLand.x,
            qLand.y,
            tokenIds[i],
            qLand.isGived
          );
        } else {
          _list[i] = ITokenSVG.TokenInfo(qLand.x, qLand.y, 0, false);
        }
      }
    }
  }

  function _getTokenIdStr(int128 x, int128 y)
    private
    view
    returns (string memory _str)
  {
    uint256 _packedXY = packedXY(x, y);

    if (_packedXYToIsMinted[_packedXY]) {
      _str = Strings.toString(_packedXYToTokenId[_packedXY]);
    }
  }

  function _verifyWhitelist(
    bytes32 messageHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private view returns (bool pass) {
    bytes32 reMessageHash = keccak256(
      abi.encodePacked(
        "\x19Ethereum Signed Message:\n42",
        Utils.toString(_msgSender())
      )
    );

    pass = (ecrecover(messageHash, v, r, s) == SIGN_MESSAGE_ADDRESS &&
      reMessageHash == messageHash);
  }
}
