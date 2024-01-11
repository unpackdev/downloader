// SPDX-License-Identifier: MIT
// 0xmellow@protonmail.com

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./IERC721Metadata.sol"; 
import "./Ownable.sol"; 

contract NFT is IERC721Metadata, ERC721, Ownable {

  uint256 public nextTokenId;
  string public baseUri;
  mapping(address => bool) public minters;
  bool public canBaseUriBeModified;

  constructor(string memory tokenName, string memory tokenSymbol) ERC721(tokenName, tokenSymbol) 
  {
    minters[msg.sender] = true;
    canBaseUriBeModified = true;
  }

  function mint(address receiver) public onlyMinter
  {
    _mint(receiver, nextTokenId);
    nextTokenId +=1;
  }

  function setBaseUri(string memory _baseUri, bool canBeModifiedLaterOn) public onlyMinter
  {
    baseUri = _baseUri;
    require(canBaseUriBeModified, "Base Uri can't be modified anymore");
    canBaseUriBeModified = canBeModifiedLaterOn;
  }


  function _baseURI() internal view virtual override returns (string memory) 
  {
        return baseUri;
  }

  modifier onlyMinter()
  {
    require(minters[msg.sender]);
    _;
  }

  function setMinter(address minter, bool permission) public onlyMinter returns (bool)
  {
    if (!minters[msg.sender])
    {
      return false;
    }
    else
    {
      minters[minter] = permission;
      return true;
    }
  }
}
