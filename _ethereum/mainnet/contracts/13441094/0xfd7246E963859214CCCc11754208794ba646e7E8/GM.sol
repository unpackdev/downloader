// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./base64.sol";

//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░░██████╗░███╗░░░███╗░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░██╔════╝░████╗░████║░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░██║░░███╗██╔████╔██║░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░██║░░░██║██║╚██╔╝██║░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░╚██████╔╝██║░╚═╝░██║░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░░╚═════╝░╚═╝░░░░░╚═╝░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

contract GM is ERC721, Ownable, ReentrancyGuard {
  
  using SafeMath for uint256;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _totalNFTs,
    uint256 _totalCommunity
  ) ERC721(_name, _symbol) {
    totalNFTs = _totalNFTs;
    totalCommunity = _totalCommunity;
    mintedNFTs = 1;
    mintedCommunity = 1;
  }

  address private _fund = 0xc13576788F8f59FB4889F66938fd73157bd97c47;
  uint256 public mintedNFTs;
  uint256 mintedCommunity;
  uint256 totalNFTs;
  uint256 totalCommunity;

  mapping (address => bool) internal mintedFree;

  function communityTokens(
    string memory custom, address toWallet, string memory tier) public onlyOwner {
    require(mintedNFTs <= totalNFTs, "gm is sold out!");
    require(mintedCommunity <= totalCommunity, "Community tokens are not available!");
    _safeMint(toWallet, mintedNFTs);
    string memory customText;
    if (_compare(custom, '')) {
       customText = unicode''
       unicode'░░██████╗░███╗░░░███╗░<br/>'
       unicode'░██╔════╝░████╗░████║░<br/>'
       unicode'░██║░░███╗██╔████╔██║░<br/>'
       unicode'░██║░░░██║██║╚██╔╝██║░<br/>'
       unicode'░╚██████╔╝██║░╚═╝░██║░<br/>'
       unicode'░░╚═════╝░╚═╝░░░░░╚═╝░';
    } else {
      customText = custom;
    }
    string memory morning = isMorningUTC(block.timestamp);
    uint256 charCount = uint256(bytes(customText).length);
    string memory tokenURI = _constructTokenURI(mintedNFTs, customText, morning, tier, charCount);
    _setTokenURI(mintedNFTs, tokenURI);
    mintedNFTs = mintedNFTs.add(1);
    mintedCommunity = mintedCommunity.add(1);
  }

  function isMorningUTC(uint256 timestamp) public pure returns (string memory) {
    return ((timestamp / 60 / 60) % 24) < 12 ? 'Yes' : 'No';
  }

  function sayItBack(string memory custom) public payable nonReentrant {
    require(mintedNFTs <= totalNFTs, "gm is sold out!");
    uint256 charCount = uint256(bytes(custom).length);
    string memory tier;
    if (charCount <= 5){
        require(charCount >= 1, "Custom text must not less than 1 character!");
        require(mintedFree[msg.sender] == false, "Already minted a free token!");
        mintedFree[msg.sender] = true;
        tier = 'Black';
    } else if (charCount > 5 && charCount <= 35) {
        require(msg.value >= 0.01 ether, "Please send 0.01 ETH!");
        tier = 'Blue';
    } else if (charCount > 35) {
        require(charCount <= 138, "Custom text must not be more than 138 characters!");
        require(msg.value >= 0.03 ether, "Please send 0.03 ETH!");
        tier = 'Gold';
    }
    _safeMint(_msgSender(), mintedNFTs);
    payable(_fund).transfer(msg.value);
    string memory customText = _concat('gm<br/><br/>', custom);
    string memory morning = isMorningUTC(block.timestamp);
    string memory tokenURI = _constructTokenURI(mintedNFTs, customText, morning, tier, charCount);
    _setTokenURI(mintedNFTs, tokenURI);
    mintedNFTs = mintedNFTs.add(1);
  }

  function _append(
    string memory a,
    string memory b,
    string memory c,
    string memory d,
    string memory e,
    string memory f,
    string memory g,
    string memory h
  ) private pure returns (string memory) {
    return string(abi.encodePacked(a, b, c, d, e, f, g, h));
  }

  function _compare(string memory a, string memory b) private pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function _concat(string memory a, string memory b) private pure returns (string memory) {
    return _append(a, b, '', '', '', '', '', '');
  }

  function _constructTokenURI(
    uint256 tokenId,
    string memory customText,
    string memory morning,
    string memory tier,
    uint256 charCount
  ) private pure returns (string memory) {
    string memory svg = _drawSvg(customText, tier);
    string memory attributes = _setTraits(morning, tier, Strings.toString(charCount));
    string memory metadata = _append(
      '{"name": "GM #',
      Strings.toString(tokenId),
      '", "description": "GM is a social experiment to spread positivity on the Ethereum blockchain.',
      '", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svg)),
      '", "attributes": ',
      attributes,
      '}'
    );
    string memory tokenURI = _concat(
      "data:application/json;base64,", Base64.encode(bytes(metadata))
    );
    return tokenURI;
  }

  function _drawSvg(
    string memory customText,
    string memory tier
  ) private pure returns (string memory) {
    string[8] memory line;
    string memory style = " font: 14px monospace; height: 100%; justify-content: center;"
    " display:flex; text-align: center; align-items: center; }</style>";
    line[0] = "<svg height='350' width='350' viewBox='0 0 350 350' preserveAspectRatio='none' "
    "xmlns='http://www.w3.org/2000/svg'>";
    if (_compare(tier, 'Gold')) {
      line[1] = _concat("<style>div { background: linear-gradient(180deg, rgb(223, 159, 40),"
      " rgb(253, 224, 141), rgb(223, 159, 40)); color: black;", style);
    } else if (_compare(tier, 'Blue')) {
      line[1] = _concat("<style>div { background: rgb(150, 220, 252); color: black;", style);
    } else {
      line[1] = _concat("<style>div { background: black; color: white;", style);
    }
    line[2] = "<foreignObject width='350' height='350'>";
    line[3] = "<div xmlns='http://www.w3.org/1999/xhtml'>";
    line[4] = customText;
    line[5] = '</div>';
    line[6] = '</foreignObject>';
    line[7] = '</svg>';
    string memory svg = _append(
      line[0], line[1], line[2], line[3], line[4], line[5], line[6], line[7]
    );
    return svg;
  }

  function _setTraits(
    string memory morning,
    string memory tier,
    string memory charCount
  ) private pure returns (string memory) {
    string memory attributes = _append(
      '[{',
      '"trait_type": "Morning - UTC", "value": "',
      morning,
      '"}, { "trait_type": "Background", "value": "',
      tier,
      '"}, { "trait_type": "Character Count", "value": ',
      charCount,
      '}]'
    );
    return attributes;
  }

}
