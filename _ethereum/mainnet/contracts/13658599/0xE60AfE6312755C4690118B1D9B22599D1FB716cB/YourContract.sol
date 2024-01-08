pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "./console.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./base64.sol";
import "./SnakerMaker.sol";
// import "./Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
  constructor() ERC721("SNAKESONACHAIN", "SNKS") {}


  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  uint256 public constant MAX_SUPPLY = 2000;
  uint256 public constant PRICE = 0.015 ether;

  function contractURI() public view returns (string memory) {
        return "https://snakesonachain.club/my-metadata";
    }
  

  function mintItem(uint256 numTokens)
      public
      payable
      virtual
  {     
      _mintItem(numTokens, _msgSender());
  }

    function mintForFriend(uint256 numTokens, address walletAddress) 
      public
      payable
      virtual
    {
      _mintItem(numTokens, walletAddress);
    }

  function _mintItem(uint256 numTokens, address destination) private {
      require(numTokens > 0, "Negative");
      require(PRICE * numTokens == msg.value, "amount wrong");
      require(totalSupply() < MAX_SUPPLY, "sold out");
      require(totalSupply() + numTokens <= MAX_SUPPLY, "Too many");
      require( numTokens < 21, "Too many");

      for (uint256 i = 0; i < numTokens; i++) {
          uint256 id = _tokenIds.current();
          _safeMint(destination, id);
          _tokenIds.increment();
      }
  }

  function getTotalSupply() public view returns (uint256) {
    return totalSupply();
  }

  function withdrawAll() public payable nonReentrant onlyOwner {
      require(payable(_msgSender()).send(address(this).balance));
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "id does not exist");
      SnakerMaker.Snake memory snk;
      string memory svg;

      string[3] memory backgroundNames = [
            "WATER",
            "DESERT",
            "SPACE"
        ];

      string[5] memory thicknessNames = [
            "SKINNY",
            "WHIMSY",
            "BASIC",
            "NOICE", 
            "THICC"
        ];

       string memory name = string(abi.encodePacked('Snake on a chain #',id.toString()));
      string memory description = string(abi.encodePacked('Every snake follows its own path (in life)'));
      (snk, svg) = SnakerMaker.generateSVGofTokenById(id);
      string memory image = Base64.encode(bytes(svg));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "attributes": [{"trait_type": "Color", "value": "',
                              //SnakerMaker.toHSLString(snk.color),
                              '"},{"trait_type": "Background", "value": "',
                              backgroundNames[snk.bgIdx],
                              '"},{"trait_type": "Thickness", "value": "',
                              thicknessNames[snk.thickIdx],
                              '"}], "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          ); 
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

}
