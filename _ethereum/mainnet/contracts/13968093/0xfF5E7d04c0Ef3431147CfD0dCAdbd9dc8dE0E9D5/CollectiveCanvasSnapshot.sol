//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./base64.sol";

contract CollectiveCanvas {
  function historicalImageAt(uint256 tokenId)
    public
    view
    virtual
    returns (string memory)
  {}

  function creatorAt(uint256 tokenId) public view returns (address) {}
}

contract CollectiveCanvasSnapshot is ERC721, Ownable {
  CollectiveCanvas collectiveCanvasContract;

  constructor(address collectiveCanvasAddr)
    ERC721("CollectiveCanvasSnapshot", "CCS")
  {
    collectiveCanvasContract = CollectiveCanvas(collectiveCanvasAddr);
  }

  function mint(uint256 tokenId) public {
    require(
      collectiveCanvasContract.creatorAt(tokenId) == msg.sender,
      "You are not the creator of that token"
    );
    _safeMint(msg.sender, tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId));
    string memory svg = collectiveCanvasContract.historicalImageAt(tokenId);
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name":"Autonomous Art Snapshot #',
        Strings.toString(tokenId),
        '","image":"',
        svg,
        '"}'
      )
    );
    string memory jsonUri = string(
      abi.encodePacked("data:application/json;base64,", json)
    );

    return jsonUri;
  }
}
