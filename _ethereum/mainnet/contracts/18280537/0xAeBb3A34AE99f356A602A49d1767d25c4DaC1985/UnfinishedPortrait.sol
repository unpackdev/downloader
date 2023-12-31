// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./IERC721Receiver.sol";
import "./ERC2981.sol";
import "./Util.sol";

interface IADiscSystem {
  function tokenIdToAttributes(uint256 tokenId)
    external
    view
    returns (
      bytes32,
      string memory,
      string memory,
      string memory,
      string memory,
      uint256,
      uint256,
      uint256,
      uint256,
      bool
    );

  function ownerOf(uint256 tokenId) external view returns (address);

  function mint(uint256 quantity) external payable;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function mintedTokenIdList() external view returns (uint256[] memory);
}

contract UnfinishedPortrait is
  ERC721,
  ERC2981,
  IERC721Receiver,
  ReentrancyGuard,
  Ownable,
  Util
{
  uint256 public constant MAX_SUPPLY = 50;
  uint256 public constant PRICE = 0.1 ether;
  uint256 public constant DISC_PRICE = 0.02 ether;

  struct Attribute {
    bytes32 hash;
    string palette;
    string image;
    string message;
    string shape;
    uint256 speed;
    uint256 size;
    uint256 weight;
    uint256 offset;
    bool dynamic;
  }

  IADiscSystem public discSystem;

  bool public isOnSale = true;
  bool public isMetadataFrozen;
  mapping(uint256 => uint256) public tokenIdToDiscTokenId;
  mapping(uint256 => Attribute) public tokenIdToAttribute;
  uint256[] private _mintedTokenIdList;

  string private _baseThumbnailURI;
  string private _artCodeURI;
  uint256 private EMPTY_DISC_TOKEN_ID = 9999;

  constructor(
    string memory baseThumbnailURI,
    string memory artCodeURI,
    address discSystemAddress
  ) ERC721("Unfinished Portrait", "UP") {
    _setDefaultRoyalty(owner(), 1000);
    _baseThumbnailURI = baseThumbnailURI;
    _artCodeURI = artCodeURI;
    discSystem = IADiscSystem(discSystemAddress);
  }

  function mintedTokenIdList() external view returns (uint256[] memory) {
    return _mintedTokenIdList;
  }

  function mint(uint256 discTokenId) external payable nonReentrant {
    require(isOnSale, "Unfinished Portrait: Not on sale");
    require(msg.value == PRICE, "Unfinished Portrait: Invalid value");

    _mintAndTransfer(_msgSender(), discTokenId);
  }

  function mintTokenAndDisc() external payable nonReentrant {
    require(isOnSale, "Unfinished Portrait: Not on sale");
    require(
      msg.value == PRICE + DISC_PRICE,
      "Unfinished Portrait: Invalid value"
    );

    discSystem.mint{value: DISC_PRICE}(1);
    uint256 discTokenId = discSystem.mintedTokenIdList().length - 1;
    require(
      address(this) == discSystem.ownerOf(discTokenId),
      "Unfinished Portrait: Not owner"
    );
    // Transfer the token from contract address to the user
    discSystem.safeTransferFrom(address(this), _msgSender(), discTokenId);
    _mintAndTransfer(_msgSender(), discTokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Unfinished Portrait: not exists");
    string memory tokenIdStr = Strings.toString(tokenId);
    uint256 discTokenId = tokenIdToDiscTokenId[tokenId];
    Attribute memory attrs;
    if (discTokenId == EMPTY_DISC_TOKEN_ID) {
      attrs = tokenIdToAttribute[tokenId];
    } else {
      attrs = _getAttribute(discTokenId);
    }

    string memory image = string(
      bytes.concat(
        bytes(_baseThumbnailURI),
        bytes(Strings.toString(tokenId)),
        bytes(".png")
      )
    );
    string memory animationUrlObj = _getAnimationUrl(attrs);

    return
      string.concat(
        "data:application/json;base64,",
        Base64.encode(
          abi.encodePacked(
            '{"name":"Unfinished Portrait #',
            tokenIdStr,
            '","description":"',
            "Artist: NIINOMI\\n\\nThe genre of portrait, which has been explored for a long time in the history of art, has evolved from the aristocratic and religious era, through the modern era when artists began to develop new techniques to depict the daily lives of the general public, to the modern era with the use of multimedia. In each of these periods, most portraits were painted by the hand of the artist and delivered to the viewer in a finished form.\\nThis work is a portrait that will never be completed, and will continue to be painted by a computer system. The owner of the work decides on the subject via the blockchain, and the system continues to draw it. It is a new portrait for the Internet age.",
            '","image":"',
            image,
            '","animation_url":"',
            animationUrlObj,
            '","discTokenId":',
            Strings.toString(discTokenId),
            ",",
            _attributesText(attrs),
            "}"
          )
        )
      );
  }

  function setDisc(uint256 tokenId, uint256 discTokenId) external {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "Unfinished Portrait: caller is not token owner"
    );
    require(
      _msgSender() == discSystem.ownerOf(discTokenId),
      "Unfinished Portrait: Not owner"
    );
    tokenIdToDiscTokenId[tokenId] = discTokenId;
  }

  function setIsOnSale(bool _isOnSale) external onlyOwner {
    isOnSale = _isOnSale;
  }

  function setIsMetadataFrozen(bool _isMetadataFrozen) external onlyOwner {
    require(
      !isMetadataFrozen,
      "Unfinished Portrait: isMetadataFrozen cannot be changed"
    );
    isMetadataFrozen = _isMetadataFrozen;
  }

  function setBaseThumbnailURI(string memory baseThumbnailURI)
    external
    onlyOwner
  {
    require(
      !isMetadataFrozen,
      "Unfinished Portrait: Metadata is already frozen"
    );
    _baseThumbnailURI = baseThumbnailURI;
  }

  function setArtCodeURI(string memory artCodeURI) external onlyOwner {
    require(
      !isMetadataFrozen,
      "Unfinished Portrait: Metadata is already frozen"
    );
    _artCodeURI = artCodeURI;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    external
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _mintAndTransfer(address to, uint256 discTokenId) internal {
    uint256 nextTokenId = _mintedTokenIdList.length + 1;
    require(
      nextTokenId <= MAX_SUPPLY,
      "Unfinished Portrait: Sold out or invalid amount"
    );
    require(
      to == discSystem.ownerOf(discTokenId),
      "Unfinished Portrait: Not owner"
    );

    tokenIdToDiscTokenId[nextTokenId] = discTokenId;

    _mintedTokenIdList.push(nextTokenId);
    _safeMint(to, nextTokenId);
  }

  function _getAttribute(uint256 discTokenId)
    internal
    view
    returns (Attribute memory)
  {
    (
      bytes32 hash,
      string memory palette,
      string memory image,
      string memory message,
      string memory shape,
      uint256 speed,
      uint256 size,
      uint256 weight,
      uint256 offset,
      bool dynamic
    ) = discSystem.tokenIdToAttributes(discTokenId);
    return
      Attribute(
        hash,
        palette,
        image,
        message,
        shape,
        speed,
        size,
        weight,
        offset,
        dynamic
      );
  }

  function _getAnimationUrl(Attribute memory attrs)
    internal
    view
    returns (string memory)
  {
    string memory attrObj = _getAttrObj(attrs);
    string memory htmlData = string.concat(
      "<html>",
      "<head>",
      '<meta name="viewport" content="width=device-width,initial-scale=1"/>',
      "<style>body{margin:0;overflow:hidden;}.artCanvas {width:100%;height:100%;position:fixed;overflow:hidden;}</style>",
      "\n<script>\n",
      _embedVariable("attributes", attrObj),
      "\n</script>\n",
      "</head>",
      "<body>",
      '<canvas id="canvas" class="artCanvas"></canvas><canvas id="canvas2" class="artCanvas"></canvas>',
      _embedScript(_artCodeURI),
      "</body>",
      "</html>"
    );
    return
      string.concat(
        "data:text/html;charset=UTF-8;base64,",
        Base64.encode(bytes(htmlData))
      );
  }

  function _getAttrObj(Attribute memory attrs)
    internal
    pure
    returns (string memory)
  {
    string memory hash = string.concat("0x", bytes32ToHexString(attrs.hash));
    string memory json1 = string(
      abi.encodePacked(
        "{",
        '"hash":"',
        hash,
        '","palette":"',
        attrs.palette,
        '","image":"',
        attrs.image,
        '","message":"',
        attrs.message,
        '","shape":"',
        attrs.shape,
        '","speed":',
        Strings.toString(attrs.speed)
      )
    );

    string memory json2 = string(
      abi.encodePacked(
        ',"size":',
        Strings.toString(attrs.size),
        ',"weight":',
        Strings.toString(attrs.weight),
        ',"offset":',
        Strings.toString(attrs.offset),
        ',"dynamic":',
        attrs.dynamic ? "true" : "false",
        "}"
      )
    );

    return string(abi.encodePacked(json1, json2));
  }

  function _embedVariable(string memory name, string memory value)
    private
    pure
    returns (string memory)
  {
    return string.concat(name, " = ", value, ";\n");
  }

  function _embedScript(string memory src)
    private
    pure
    returns (string memory)
  {
    return string.concat('<script src="', src, '"></script>');
  }

  function _attributesText(Attribute memory attrs)
    internal
    pure
    returns (string memory)
  {
    return
      string.concat(
        '"attributes":[{"trait_type":"palette","value":"',
        attrs.palette,
        '"},{"trait_type":"image","value":"',
        attrs.image,
        '"},{"trait_type":"message","value":"',
        attrs.message,
        '"},{"trait_type":"shape","value":"',
        attrs.shape,
        '"},{"trait_type":"speed","value":',
        Strings.toString(attrs.speed),
        '},{"trait_type":"size","value":',
        Strings.toString(attrs.size),
        '},{"trait_type":"weight","value":',
        Strings.toString(attrs.weight),
        '},{"trait_type":"offset","value":',
        Strings.toString(attrs.offset),
        '},{"trait_type":"dynamic","value":"',
        attrs.dynamic ? "true" : "false",
        '"}]'
      );
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
    if (from != address(0)) {
      uint256 discTokenId = tokenIdToDiscTokenId[tokenId];
      if (discTokenId != EMPTY_DISC_TOKEN_ID) {
        tokenIdToDiscTokenId[tokenId] = EMPTY_DISC_TOKEN_ID;
        Attribute memory attribute = _getAttribute(discTokenId);
        tokenIdToAttribute[tokenId] = attribute;
      }
    }
  }
}
