/* 
This smart contract represents the "IPCOSMOS GALLERY" collection of NFTs 2021.
Every Artwork is a unique token limited edition of 1.
This contract created by using Openzeppelin library and verified by using Truffle.
*/

pragma solidity ^0.5.16;

import "./ERC721Full.sol";
import "./MinterRole.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CosmosGallery is Ownable, MinterRole, ERC721Full {
  using SafeMath for uint;

  constructor() ERC721Full("IPCOSMOS GALLERY", "IPCT") public {
  }

  function mint(address _to, string memory _tokenURI) public onlyMinter returns (bool) {
    _mintWithTokenURI(_to, _tokenURI);
    return true;
  }

  function _mintWithTokenURI(address _to, string memory _tokenURI) internal {
    uint _tokenId = totalSupply().add(1);
    _mint(_to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
  }
}