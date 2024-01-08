// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";

import "./base64.sol";

contract Confessions is ERC721Enumerable, Pausable, ReentrancyGuard, Ownable {
  event MintCostUpdated(uint256 from, uint256 to);

  struct Confession {
    string[] text; //Solidity sucks at strings (for good reason) and SVG sucks at multi-line
    address confessor;
  }

  mapping(address => Confession[]) private confessorsConfessionMapping;
  mapping(uint256 => Confession) private confessions;
  uint256 private confessionsSize = 0;

  uint256 private mintCost = 0.05 ether;

  constructor() ERC721("Confessions", "CONS") Pausable() Ownable() {
    _pause();
  }

  // Since SVGs don't support multi-line text and solidity strings aren't easy to work with and
  // we want this to be fully on-chain, we have to split the confession text up on the client side
  // and pass it into the contract as an array.
  // MINTING FROM CONTRACT HAS UNPREDICTABLE RESULTS.
  function mintConfession(string[] calldata _text) public payable nonReentrant whenNotPaused {
    require(msg.value == mintCost, "Invalid payment sent");
    _mintConfession(_text);
  }

  function preMintConfession(string[] calldata _text) public onlyOwner {
    _mintConfession(_text);
  }

  function _mintConfession(string[] calldata _text) internal {
    _safeMint(msg.sender, confessionsSize);
    Confession memory newConfession = Confession(_text, msg.sender);
    confessorsConfessionMapping[msg.sender].push(newConfession);
    confessions[confessionsSize] = newConfession;
    confessionsSize++;
  }

  function getConfessionsForConfessor(address confessor) public view returns (Confession[] memory) {
    return confessorsConfessionMapping[confessor];
  }

  function _getConfessionTextArray(uint256 tokenId)
    private
    view
    returns (string[] memory)
  {
    require(tokenId < confessionsSize);
    string[] memory text = confessions[tokenId].text;
    return text;
  }

  function getConfessionText(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    require(tokenId < confessionsSize);
    string[] memory text = confessions[tokenId].text;
    string memory combined;
    for (uint256 index = 0; index < text.length; index++) {
      combined = string(abi.encodePacked(combined, " ", text[index]));
    }
    return combined;
  }

  function getConfessionConfessor(uint256 tokenId)
    public
    view
    returns (address)
  {
    require(tokenId < confessionsSize);
    address confessor = confessions[tokenId].confessor;
    return confessor;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function getMintCost() public view returns (uint256) {
    return mintCost;
  }

  function setMintCost(uint256 _cost) public onlyOwner {
    uint256 old_cost = mintCost;
    mintCost = _cost;
    emit MintCostUpdated(old_cost, _cost);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory svg = getSVG(tokenId);

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Confession #',
            Strings.toString(tokenId),
            '", "description": "Things better left unsaid. Living on-chain forever.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
          )
        )
      )
    );
    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );

    return output;
  }

  function getSVG(uint256 tokenId) public view returns (string memory) {
    string[] memory text = _getConfessionTextArray(tokenId);
    string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><style>.base { fill: #edf2f4; font-family: helvetica; font-size: 12px; } .address { fill: #ef233c; font-size: 14px; }</style><rect width="100%" height="100%" fill="#8d99ae" /><rect rx="5" y="1%" x="1%" width="98%" height="98%" fill="#2b2d42" />';

    svg = string(
      abi.encodePacked(
        svg,
        '<text x="20" y="40" class="base address">0x',
        toAsciiString(getConfessionConfessor(tokenId)),
        "</text>"
      )
    );

    svg = string(abi.encodePacked(svg, 
    '<g transform="translate(30, 50)"><polygon fill="#231F20" points="112.553,157 112.553,86.977 44.158,116.937  "/><polygon fill="#231F20" points="112.553,82.163 112.553,-0.056 46.362,111.156  "/><polygon fill="#231F20" points="116.962,-0.09 116.962,82.163 184.083,111.566  "/><polygon fill="#231F20" points="116.962,86.977 116.962,157.002 185.405,116.957  "/><polygon fill="#231F20" points="112.553,227.406 112.553,171.085 44.618,131.31  "/><polygon fill="#231F20" points="116.962,227.406 184.897,131.31 116.962,171.085  "/></g>'
    ));

    uint256 yOffset = 80;
    for (uint256 index = 0; index < text.length; index++) {
      svg = string(
        abi.encodePacked(
          svg,
          '<text x="20" y="',
          Strings.toString(yOffset),
          '" class="base">',
          text[index],
          "</text>"
        )
      );
      yOffset += 17;
    }

    svg = string(abi.encodePacked(svg, "</svg>"));
    return svg;
  }

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function withdrawTo(address to, uint256 amount) public payable onlyOwner {
      if (to == address(0)) {
          to = msg.sender;
      }
      if (amount == 0) {
          amount = address(this).balance;
      }
      require(payable(to).send(amount));
  }

  function withdraw(uint256 amount) public payable onlyOwner {
      if (amount == 0) {
          amount = address(this).balance;
      }
      require(payable(owner()).send(amount));
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }
}
