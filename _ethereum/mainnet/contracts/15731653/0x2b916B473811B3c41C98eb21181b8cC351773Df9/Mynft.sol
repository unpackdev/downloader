// SPDX-License-Identifier: DevThreeTeam

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Strings.sol"; 
import "./Ownable.sol";

contract DevThreeTeamNft is ERC721A, Ownable{
    using Strings for uint256;
    string private baseURI = "ipfs://bafybeif5ebhyh4sdn33ffxquvm6lwexkke6gfrlqsbsma6njsg5shxa2iu/";
    string private  baseExtension = ".json";

    constructor() ERC721A( "The Invincible Nerd - Wave 1", "TIN") {}


 function mint (uint256 quantity) external  payable onlyOwner  {
    _mint(msg.sender, quantity);
    }

function _baseURI() override  internal view  virtual  returns(string memory) {
    return baseURI;
}

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    


    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
}