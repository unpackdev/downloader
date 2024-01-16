// SPDX-License-Identifier: MIT
/*
                  .(((((((((((-.
                 ggWWWWHHHHHHHHQp
                 M#zzzzzzzXZZZyM@
                 M#zzzzzzzzuZZyM@
                 M#zzzuzzuzzZZyM@
                 M#zzzzzzzzuZZyM@
                 M#zzzuzzzzuZZyM@
                 M#zzzzuzzzzzXyM@.
               ..MBzzzzzzuzzzXZZdM}
               JMkzzzuzzzzzuzXyZdM}
               JMkzzzzzzuzzzzXZZdM}
              .JMkzuzuuzuzzzuXZydM}
              M#TQkTXZTQkT4wzXyZdM}
              Mb.M8.dn.dN.JUzXUZdM}
              ?wNkuuzuuuuuzzzzzZdM}
               JMNNNNNNNNNMMkXzZyWN#
              MNQQQQQQQQQQQXM#zZZZM#
              .JMMMMMMMMMMMMmmuZZZM#
              74NNNNNNNNNNNNM8zZZyM#
               JM0UUUUUUUUUUuzzZyZM#
               JMkzzzzzzzzzzzzuXXXM#
               JMmyzzzzzzzQQQQQMHHM#
               JMHNQQQQQQQHHHHHHHHM#
               JMHHHHHHHHHHHHHHHHHM#
               JMHHHH@HHH@HH@HH@HHM#
*/
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./Strings.sol";

contract VeryLongPepe is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public maxSupply = 100;
  uint256 public nextTokenId = 1;

  mapping(uint256 => string) public pepeBodies;

  constructor() ERC721("VeryLongPepe", "VLPEPE"){}

  function mint(string calldata pepeBody) external onlyOwner {
    uint256 supply = totalSupply();
    require(supply <= maxSupply, "All tokens minted");
    require(msg.sender == owner(), "Not Owner");

    uint256 _tokenId = nextTokenId;
    nextTokenId++;
    pepeBodies[_tokenId] = pepeBody;

    _safeMint(msg.sender, _tokenId);
  }

 function tokenURI(uint256 tokenId)
   public
   view
   virtual
   override
   returns (string memory) {
   require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token" );

   return string(abi.encodePacked(
     'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
      '{"name": "VeryLongPepe #', Strings.toString(tokenId),
      '", "description": "Let\'s make Pepe Longer!'
      '", "image": "data:image/svg+xml;base64,',
      buildImage(tokenId),
      '"}'
     )))));
 }

  function buildImage(uint256 tokenId) public view returns(string memory) {
    return Base64.encode(bytes(abi.encodePacked(
        pepeBodies[tokenId]
    )));
  }

}