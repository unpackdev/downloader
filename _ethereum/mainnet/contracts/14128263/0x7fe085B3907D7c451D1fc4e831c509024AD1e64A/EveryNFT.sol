pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract EveryNFT is ERC721, Ownable {
  // @dev This defines the struct for a token to read data from a parent contract, and what token to read data from
  struct tokenData {
    uint256 tokenId;
    address contractAddress;
  }
  // @dev mapping that goes from a tokenId to a
  mapping(uint256 => tokenData) public tokenToData;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721('EveryNFT', 'EVRNFT') {}

  // @dev fetches image data from the contract stored && the tokenId stored
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    string memory linkToReturn = ERC721(tokenToData[_tokenId].contractAddress).tokenURI(tokenToData[_tokenId].tokenId);
    return linkToReturn;
  }

  function mintToken(address _contractAddress, uint256 _fraudTokenId) public payable {
    require(msg.value >= 0.01 ether, 'Value too low');
    (bool sent, bytes memory data) = address(0x807a1752402D21400D555e1CD7f175566088b955).call{value: msg.value}('');
    require(sent, 'Failed to send Ether');
    _tokenIds.increment();
    uint256 tokenId = _tokenIds.current();
    _mint(msg.sender, tokenId);
    tokenToData[tokenId] = tokenData(_fraudTokenId, _contractAddress);
  }
}
