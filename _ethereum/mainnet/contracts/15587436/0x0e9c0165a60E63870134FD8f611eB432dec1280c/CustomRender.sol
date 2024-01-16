// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Base64.sol";

// import "./console.sol";

contract Html {
  function data() public pure returns (string memory) {}
}

contract CustomRender is Ownable {
  string public baseUri;
  string public randomKey;
  bool public showHtml = false;

  Html model1;
  Html model2;
  Html model3;
  Html library4;
  Html shaders5;
  Html builder6;

  function setConnections(
    address _html1Address,
    address _html2Address,
    address _html3Address,
    address _html4Address,
    address _html5Address,
    address _html6Address
  ) public onlyOwner {
    model1 = Html(_html1Address);
    model2 = Html(_html2Address);
    model3 = Html(_html3Address);
    library4 = Html(_html4Address);
    shaders5 = Html(_html5Address);
    builder6 = Html(_html6Address);
  }

  ///////////////// reveal /////////////////

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseUri = _baseURI;
  }

  function setRandom(string memory _randomKey) public onlyOwner {
    randomKey = _randomKey;
  }

  function setShowHtml(bool _html) public onlyOwner {
    showHtml = _html;
  }

  ///////////////// art /////////////////

  function htmlData(string memory seed) public view returns (string memory) {
    string memory htmlPrefix = string(
      abi.encodePacked(
        '<!doctype html><html><head><meta charset="UTF-8"/><meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/><meta name="viewport" content="width=device-width,minimal-ui,viewport-fit=cover,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no"/><title>Tickle Beach</title><style>:root{overflow: hidden; height: 100%}body{margin: 0}</style></head><body><script defer="defer">window.seed="',
        seed,
        '";</script>'
      )
    );

    string memory html = string(
      abi.encodePacked(
        htmlPrefix,
        model1.data(),
        model2.data(),
        model3.data(),
        library4.data(),
        shaders5.data(),
        builder6.data(),
        '</body></html>'
      )
    );
    return html;
  }

  function htmlForToken(uint256 tokenId) public view returns (string memory) {
    string memory html = htmlData(
      toString(
        uint256(keccak256(abi.encodePacked(toString(tokenId), randomKey)))
      )
    );
    return html;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    string memory stringTokenId = toString(tokenId);
    string memory html = '<html not set>';

    if (showHtml == true) {
      html = htmlForToken(tokenId);
    }

    string memory imageUrl = string(
      abi.encodePacked(baseUri, '/preview/', stringTokenId, '.png')
    );

    string memory animationUrl = string(
      abi.encodePacked(baseUri, '/animation/', stringTokenId, '.html')
    );

    string memory externalUrl = string(
      abi.encodePacked(baseUri, '/gallery/', stringTokenId)
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Tickle Beach #',
            stringTokenId,
            '", "image": "',
            imageUrl,
            '", "animation_url": "',
            animationUrl,
            '", "external_url": "',
            externalUrl,
            '", "description": "Tickle Beach loves you.',
            // we did forever3d to avoid api collisons, can change when a standard emerges
            '", "forever3d_html": "data:text/html;base64,',
            Base64.encode(bytes(html)),
            '"}'
          )
        )
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  // ///////////////// utils /////////////////

  // Inspired by OraclizeAPI's implementation - MIT license
  // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}
