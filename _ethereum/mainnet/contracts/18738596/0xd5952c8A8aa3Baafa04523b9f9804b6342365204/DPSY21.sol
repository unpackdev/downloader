// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract DPSY21 is ERC721, ERC2981, ReentrancyGuard, Ownable {
  uint256 public constant PRICE = 0.9 ether;

  mapping(uint256 => uint256) public tokenIdToPrice;
  uint256[] private _mintedTokenIdList;

  bool public isOnSale = true;
  bool public isMetadataFrozen;
  string private _baseThumbnailURI;
  string private _artCodeURI;

  constructor(
    string memory baseThumbnailURI,
    string memory artCodeURI,
    uint256[] memory editions
  ) ERC721("DPSY21", "DPSY21") {
    _setDefaultRoyalty(owner(), 1000);
    _baseThumbnailURI = baseThumbnailURI;
    _artCodeURI = artCodeURI;

    uint256 count = editions.length;
    for (uint256 i; i < count; i++) {
      uint256 edition = editions[i];
      tokenIdToPrice[edition] = PRICE;
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "DPSY21: not exists");
    string memory tokenIdStr = Strings.toString(tokenId);

    string memory image = string(
      bytes.concat(
        bytes(_baseThumbnailURI),
        bytes(Strings.toString(tokenId)),
        bytes(".jpg")
      )
    );

    string memory animationUrlObj = _getAnimationUrl(tokenIdStr);

    return
      string.concat(
        "data:application/json;base64,",
        Base64.encode(
          abi.encodePacked(
            '{"name":"DPSY21 #',
            tokenIdStr,
            '","description":"',
            "1080*608 pix, 300 frames, 30fps, gif, Kazuhiro Aihara, 2023.\\nA dynamic coding in which the hue changes cycled 365 days.\\nA handmade physical digital frame.",
            '","image":"',
            image,
            '","animation_url":"',
            animationUrlObj,
            '"}'
          )
        )
      );
  }

  function mintedTokenIdList() public view returns (uint256[] memory) {
    return _mintedTokenIdList;
  }

  function mint(uint256 edition) external payable nonReentrant {
    require(isOnSale, "DPSY21: Not on sale");
    require(tokenIdToPrice[edition] == PRICE, "DPSY21: Invalid token id");
    require(msg.value == PRICE, "DPSY21: Invalid value");
    _mintedTokenIdList.push(edition);
    _safeMint(_msgSender(), edition);
  }

  function setIsOnSale(bool _isOnSale) external onlyOwner {
    isOnSale = _isOnSale;
  }

  function setIsMetadataFrozen(bool _isMetadataFrozen) external onlyOwner {
    require(!isMetadataFrozen, "DPSY21: isMetadataFrozen cannot be changed");
    isMetadataFrozen = _isMetadataFrozen;
  }

  function setBaseThumbnailURI(string memory baseThumbnailURI)
    external
    onlyOwner
  {
    require(!isMetadataFrozen, "DPSY21: Metadata is already frozen");
    _baseThumbnailURI = baseThumbnailURI;
  }

  function setArtCodeURI(string memory artCodeURI) external onlyOwner {
    require(!isMetadataFrozen, "DPSY21: Metadata is already frozen");
    _artCodeURI = artCodeURI;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
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

  function _getAnimationUrl(string memory tokenId)
    internal
    view
    returns (string memory)
  {
    string memory htmlData = string.concat(
      "<html>",
      "<head>",
      '<meta name="viewport" content="width=device-width,initial-scale=1"/>',
      "<style>body{margin:0;overflow:hidden;}img{width:100%;height:100%;position:fixed;left:0;top:0;object-fit:contain;background:#000;}</style>",
      "\n<script>\n",
      _embedVariable("tokenId", tokenId),
      "\n</script>\n",
      "</head>",
      "<body>",
      '<img id="img"/>',
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
}
