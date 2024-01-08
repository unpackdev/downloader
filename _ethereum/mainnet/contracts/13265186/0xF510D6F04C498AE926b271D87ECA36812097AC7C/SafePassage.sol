// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
  Safe Passage NFTs
  by nftboi and tr666
 */

contract SafePassage is ERC721Enumerable, Ownable {
  string BASE_URI;
  uint256 PRICE = 0.06 ether;
  uint256 MAX_SUPPLY = 11111;
  uint256 public START_TIME = 1632322800;
  address public DONATION_WALLET;

  constructor(string memory baseUri, address donationWallet)
    ERC721("Safe Passage", "SP")
  {
    BASE_URI = baseUri;
    DONATION_WALLET = donationWallet;
  }

  uint256 globalId;

  mapping(uint256 => uint256) tokenIdToSeed;

  function getSeedFromTokenId(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "SP: 6");
    return tokenIdToSeed[tokenId];
  }

  function updateStartTime(uint256 startTime) public onlyOwner {
    START_TIME = startTime;
  }

  function updateDonationWallet(address donationWallet) public onlyOwner {
    DONATION_WALLET = donationWallet;
  }

  function updatePrice(uint256 price) public onlyOwner {
    PRICE = price;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "SP: 6");
    string[3] memory parts;
    parts[
      0
    ] = "<script>({PI,cos:c,sin:s,round:x}=Math),l=2147483647,r=(r=>(n=0,i=1)=>(r=16807*r%l,n+(i-n)*r/l))(Number(";

    parts[1] = uintToStr(getSeedFromTokenId(tokenId));

    parts[
      2
    ] = ')),m=.05,v=r(.01,.04),z=.5-m-v,u=r(5,25),b=r(5,25),y=x(r(10,60)),n=r(0,.15)*m,_=`stroke-width=${.002} stroke-dasharray="${`${r(.01,.1)} ${r(0,.1)}`}" stroke="#000" fill="none"/>`,$="<circle cx=0.5 cy=0.5 r=",q=\'<polyline points="\',document.write(`<svg width="100%" height="100%" viewBox="0 0 1 1" preserveAspectRatio="xMidYMid meet"><defs><clipPath id="c">${$}${.5-m-v} /></clipPath></defs><rect x="0" y="0" width="1" height="1" fill="white" />${q}${new Array(361).fill(0).map((_,j)=>(o=j/180*PI,g=.5-m+s(o*y)*n,`${.5+g*s(o)} ${.5+g*c(o)}`)).join(",")}" ${_}${$}${.5-m-v} ${_}${q}${new Array(2e3).fill(0).map((_,n)=>`${c(n/u)*z+.5} ${c(n/b)*z+.5}`).join(",")}" clip-path="url(#c)" ${_}</svg>`)</script>';

    string memory html;
    for (uint256 i = 0; i < parts.length; i++) {
      html = string(abi.encodePacked(html, parts[i]));
    }

    string memory id = uintToStr(tokenId);

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Safe Passage #',
            id,
            '", "description": "On-chain generative artworks commemorating donations supporting the evacuation of thousands of vulnerable people from Afghanistan", "image": "',
            _baseURI(),
            id,
            '", "on_chain_image": "data:text/html;base64,',
            Base64.encode(bytes(html)),
            '"}'
          )
        )
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  event Donation(uint256 amount);
  event Minted(uint256 tokenId, uint256 seed);

  function mint(uint256 amount) public payable {
    require(block.timestamp >= START_TIME, "SP: 1");
    require(globalId < MAX_SUPPLY, "SP: 2");
    require(msg.value == amount * PRICE, "SP: 3");
    require(globalId + amount <= MAX_SUPPLY, "SP: 4");
    require(amount > 0 && amount <= 20, "SP: 5");
    payable(DONATION_WALLET).transfer(msg.value);
    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = ++globalId;
      tokenIdToSeed[tokenId] = uint256(
        keccak256(
          abi.encodePacked(
            tokenId,
            block.number,
            blockhash(block.number - 1),
            msg.sender
          )
        )
      );
      _safeMint(msg.sender, tokenId);
      emit Minted(tokenId, tokenIdToSeed[tokenId]);
    }
  }

  function setBaseUri(string memory baseUri) public onlyOwner {
    BASE_URI = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  function uintToStr(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function bytes32ToString(bytes32 x) internal pure returns (string memory) {
    bytes memory bytesString = new bytes(32);
    uint256 charCount = 0;
    for (uint256 j = 0; j < 32; j++) {
      bytes1 char = bytes1(bytes32(uint256(x) * 2**(8 * j)));
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (uint256 j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }

  /**
    Error codes
    1: Sale not started
    2: All minted 
    3: Incorrect value sent
    4: Cannot mint amount specified
    5: Max 20 mints per transaction
    6: Token ID does not exist
   */
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
