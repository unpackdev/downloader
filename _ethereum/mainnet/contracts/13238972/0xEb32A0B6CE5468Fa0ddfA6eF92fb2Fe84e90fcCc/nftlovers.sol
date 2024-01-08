// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
// Inspired by WeirdWhales and MoreLoot.
pragma solidity >=0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract NFTLovers is ERC721Enumerable, Ownable {
  using SafeMath for uint256;

  string[] private desires = [ 'NFT', 'ETH', 'ADA', 'SOL', 'ELON', 'GAS' ];
  string[] private colors = [ '000', 'fa4', 'f4a', '4af', '2c8', 'fff' ];
  string[] private colornames = [ 'Black', 'Orange', 'Pink', 'Blue', 'Green', 'White' ];
  // Pre-computed set of configs that satisfies uniqueness and rarity goals.
  uint16[] private configs = [363,13,2160,479,720,253,84,2600,4932,292,81,162,433,2244,39,289,156,74,2850,868,577,83,2352,145,4032,183,660,297,541,2736,95,160,864,79,2196,291,194,4033,654,721,288,2127,942,146,2464,324,217,12,153,91,293,2484,726,229,2129,579,4944,2,151,360,180,4,2385,589,252,0,2811,445,296,900,73,2172,148,78,4361,753,576,937,2023,216,540,2319,37,150,220,5,332,2448,15,4825,972,174,619,147,2304,88,149,2088,331,722,1011,984,2233,618,4465,3,294,218,2316,77,144,475,580,264,2035,795,870,36,301,2236,72,4179,582,326,121,2165,438,936,303,2197,793,48,9,4320,166,653,444,2125,225,866,336,2737,221,6,1,228,756,2314,578,111,504,2175,865,42,4392,181,7,2163,246,432,364,11,2712,867,325,792,152,4177,300,2019,510,901,14,108,2592,227,724,49,306,2161,75,366,2881,768,4176,109,651,299,192,506,2016,154,723,2028,361,269,612,439,4104,237,290,2880,10,159,468,649,2052,223,157,2310,399,869,16,794,2053,186,4608,732,219,90,2305,435,120,871,2232,40,588,295,365,4248,182,729,2017,2136,1153,437,876,76,187,309,648,158,396,2022,2883,757,505,4188,114,5335];

  constructor() ERC721("250 NFT Lovers", "NFTL") Ownable() {}

  function mint(uint256 _count) public payable {
    uint256 totalSupply = totalSupply();

    require(_count > 0 && _count < 11, "Only 10 NFT Lovers per transaction please");
    require(totalSupply + _count <= configs.length, "Not enough NFT Lovers left");
    require(msg.value >= 10000000000000000 * _count, "Minting an NFT Lover costs 0.01 ETH");

    for(uint16 i = 0; i < _count; i++){
      _safeMint(msg.sender, totalSupply + i + 1);
    }
  }

  function send(address _to) public onlyOwner {
    uint256 totalSupply = totalSupply();
    require(totalSupply < configs.length, "No NFT Lovers left");
    _safeMint(_to, totalSupply + 1);
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    require(_exists(tokenId), "NFT Lover doesn't exist");
    uint16 config = configs[tokenId - 1];
    uint16 color = config % 6;
    config /= 6;
    string memory svg = string(abi.encodePacked(
      '<?xml version="1.0" encoding="UTF-8"?><svg width="800" height="800" viewBox="0 0 211.66667 211.66667" version="1.1" xmlns="http://www.w3.org/2000/svg"><style>svg{background:#',
      colors[color],
      '}path,circle{fill:none;stroke:#',
      color == 5 ? '000' : 'fff',
      ';stroke-width:1.05833;stroke-linejoin:round}text,.fill {fill:#',
      color == 5 ? '000' : 'fff',
      ';stroke:none}text,tspan{text-align:center;text-anchor:middle;font-size:8.46666667px;font-family:monospace}</style><path d="M 82.987503,127.70803 C 75.55105,44.689282 138.2747,24.066036 122.19554,125.39244 Z" /><path d="m 114.92743,125.74744 c 6.68183,31.27095 1.06909,49.98007 1.06909,49.98007 l 9.35456,2.13818" /><path d="m 88.469089,127.33495 c 6.681824,31.27095 1.069087,49.98007 1.069087,49.98007 l 9.354557,2.13818" /><circle cx="112.8697" cy="44.678566" r="12.386244" />'));
    string memory traits;
    uint16 tmp = config % 3;
    config /= 3;
    if (tmp == 1) {
      svg = string(abi.encodePacked(svg, '<path d="m 124.97115,92.778856 c 7.91092,1.84588 18.9862,2.373277 18.9862,2.373277 l 4.74655,-1.845877" /><path d="m 93.77507,77.090679 c -10.4576,22.258934 -7.228205,57.088631 -7.228205,57.088631 l -5.04276,5.48345" />'));
      traits = '{"trait_type":"Arms","value":"Relaxed"},';
    } else if (tmp == 2) {
      svg = string(abi.encodePacked(svg, '<path d="m 124.41241,84.409948 c 0.35716,4.285978 3.69069,18.215402 3.69069,18.215402 -16.07242,-6.548022 -28.573177,-4.285977 -28.573177,-4.285977 l -5.119361,3.095427" /><path d="m 93.775068,77.090679 c 2.738263,11.786439 4.207143,25.653721 4.207143,25.653721 16.072419,-4.166919 26.549249,-5.357465 26.549249,-5.357465 l 5.95275,2.619205" />'));
      traits = '{"trait_type":"Arms","value":"Crossed"},';
    } else {
      svg = string(abi.encodePacked(svg, '<path d="m 119.87684,125.67165 c -0.13895,3.97135 -0.3633,6.39098 -0.3633,6.39098 l 5.04279,5.48345" /><path d="m 93.77507,77.090679 c -10.4576,22.258934 -7.228205,57.088631 -7.228205,57.088631 l -5.04276,5.48345" />'));
      traits = '{"trait_type":"Arms","value":"Relaxed"},';
    }
    if (config % 2 == 1) {
      if (tmp == 1) {
        svg = string(abi.encodePacked(svg, '<path class="fill" d="m 147.63814,87.510393 c 5.46165,5.581742 6.77827,9.116965 6.77827,9.116965 -1.69302,0.110861 -2.297,1.093905 -2.297,1.093905 -2.79891,-4.546593 -4.33105,-7.821002 -5.10079,-9.684812" /><path class="fill" d="m 155.28056,96.598425 c 0,0 14.97613,-15.528461 15.76951,-26.323225 0.7934,-10.794759 -11.19433,-10.892 -10.03515,-30.710437 C 162.1741,19.746326 148.68371,0.05157297 148.68371,0.05157297 l 48.52945,0.02835725 c 0,0 -23.76185,22.06525778 -25.8047,37.29125678 -2.04285,15.226003 9.09568,18.074511 6.80958,32.172831 -2.28612,14.098316 -22.93748,27.054436 -22.93748,27.054436 z" />'));
      } else {
        svg = string(abi.encodePacked(svg, '<path class="fill" d="m 118.58275,49.367127 c 7.78654,-0.59599 11.34099,0.667811 11.34099,0.667811 -1.00334,1.368197 -0.6385,2.462753 -0.6385,2.462753 -5.28201,-0.778401 -8.77519,-1.70946 -10.69773,-2.317841" /><path class="fill" d="m 129.88055,51.720723 c 0,0 14.97613,-8.310394 15.76951,-14.087447 0.7934,-5.77705 -11.19433,-5.829091 -10.03515,-16.435359 1.15918,-10.606268 -3.59996,-21.14634403 -3.59996,-21.14634403 l 39.7982,0.015176 c 0,0 -23.76185,11.80870303 -25.8047,19.95722803 -2.04285,8.148527 9.09568,9.672968 6.80958,17.217991 -2.28612,7.545021 -22.93748,14.478771 -22.93748,14.478771 z" />'));
      }
      traits = string(abi.encodePacked(traits, '{"trait_type":"Accessory","value":"Cigarette"},'));
    }
    config /= 2;
    tmp = config % 4;
    config /= 4;
    if (tmp == 3) {
      svg = string(abi.encodePacked(svg, '<path d="m 109.899145,41.727663 c 1.633156,0.85547 3.165697,0 3.165697,0" /><path d="m 117.836647,41.727663 c 1.633156,0.85547 3.165697,0 3.165697,0" /><path d="m 114.661645,49.665165 c 1.633156,-0.85547 3.165697,0 3.165697,0" />'));
      traits = string(abi.encodePacked(traits, '{"trait_type":"Emotion","value":"Scepticism"},'));
    } else if (tmp == 2) {
      svg = string(abi.encodePacked(svg, '<path d="m 109.899145,41.727663 c 1.633156,-0.855463 3.165697,0 3.165697,0" /><path d="m 117.836647,41.727663 c 1.633156,-0.855463 3.165697,0 3.165697,0" /><path d="m 114.661645,49.665165 c 1.633156,0.855463 3.165697,0 3.165697,0" />'));
      traits = string(abi.encodePacked(traits, '{"trait_type":"Emotion","value":"Enthusiasm"},'));
    } else if (tmp == 1) {
      svg = string(abi.encodePacked(svg, '<circle class="fill" cx="111.44763" cy="41.688648" r="1.5484867" /><circle class="fill" cx="119.38513" cy="41.688648" r="1.5484867" /><circle class="fill" cx="116.21013" cy="49.626152" r="1.5484867" />'));
      traits = string(abi.encodePacked(traits, '{"trait_type":"Emotion","value":"Surprise"},'));
    } else {
      svg = string(abi.encodePacked(svg, '<path d="m 109.89914,41.727663 h 3.1657" /><path d="m 117.83666,41.727663 h 3.1657" /><path d="m 114.66167,49.665165 h 3.1657" />'));
      traits = string(abi.encodePacked(traits, '{"trait_type":"Emotion","value":"Neutral"},'));
    }
    tmp = config % 7;
    config /= 7;
    if (tmp > 0) {
      svg = string(abi.encodePacked(
        svg,
        '<text><tspan x="111.67871" y="88.152931">I\u2665</tspan><tspan x="111.67871" y="95.089966">',
        desires[tmp - 1],
        '</tspan></text>'));
    }
    if (config % 2 == 1) {
      svg = string(abi.encodePacked(svg, '<path d="m 98.497708,127.20131 c 1.199837,6.83909 4.319442,0 4.319442,0 4.12425,24.93241 4.289,-0.48633 4.289,-0.48633 0,0 2.41887,7.20543 4.81855,-0.35356" />'));
      traits = string(abi.encodePacked(traits, '{"trait_type":"Wardrobe","value":"Malfunction"},'));
    } else if (tmp > 0) {
      traits = string(abi.encodePacked(traits, '{"trait_type":"Wardrobe","value":"', desires[tmp - 1], '"},'));
    } else {
      traits = string(abi.encodePacked(traits, '{"trait_type":"Wardrobe","value":"Plain"},'));
    }
    config /= 2;
    tmp = config % 3;
    config /= 3;
    if (tmp == 2) {
      svg = string(abi.encodePacked(svg, '<path d="m 102.22746,50.823859 c -7.656207,0.665224 -1.73922,-4.251425 -1.73922,-4.251425 -7.630297,-2.910525 0.38649,-5.410906 0.38649,-5.410906 -6.293028,-6.922331 2.51221,-4.637919 2.51221,-4.637919 -3.3825,-7.866285 4.05818,-3.285191 4.05818,-3.285191 1.88791,-7.394308 5.02441,-1.15948 5.02441,-1.15948 4.24779,-6.293028 5.60415,1.352727 5.60415,1.352727 6.60768,-4.641108 3.67169,2.705452 3.67169,2.705452 7.39431,-2.045234 2.8987,4.251425 2.8987,4.251425 7.6303,0.07866 0.57974,4.637918 0.57974,4.637918" />'));
      traits = string(abi.encodePacked(traits, '{"trait_type":"Hair","value":"Curly"},'));
    } else if (tmp == 1) {
      svg = string(abi.encodePacked(svg, '<path d="m 109.82131,32.680446 -0.24294,-2.411068" /><path d="m 111.49073,32.46347 -0.13549,-2.439859" /><path d="m 113.16015,32.246492 0.21568,-2.418781" />'));
      traits = string(abi.encodePacked(traits, '{"trait_type":"Hair","value":"Definitely"},'));
    } else {
      traits = string(abi.encodePacked(traits, '{"trait_type":"Hair","value":"Probably"},'));
    }
    svg = string(abi.encodePacked(svg, '</svg>'));
    return string(abi.encodePacked('data:application/json;base64,',
      Base64.encode(bytes(string(abi.encodePacked(
        '{"name": "NFT Lover #',
        string(toBytes(tokenId)),
        '","description": "A collection of 250 NFT lovers","external_url":"https://twitter.com/250NFTLovers","attributes":[',
        traits,
        '{"trait_type":"Background","value":"',
        colornames[color],
        '"}],"image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(svg)),
        '"}'))))));
  }

  function toBytes(uint256 value) internal pure returns (bytes memory) {
  // Inspired by OraclizeAPI's implementation - MIT license via
  // https://etherscan.io/address/0x1dfe7ca09e99d10835bf73044a23b73fc20623df#code
    bytes memory buffer;
    if (value == 0) {
      buffer = new bytes(1);
      buffer[0] = bytes1(uint8(48));
      return buffer;
    }
    uint256 temp = value;
    uint16 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint8(value % 10)));
      value /= 10;
    }
    return buffer;
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
