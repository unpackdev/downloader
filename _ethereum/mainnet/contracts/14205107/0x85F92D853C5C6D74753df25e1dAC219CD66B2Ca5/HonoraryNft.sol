//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract DACHonoraryMembers is ERC721, Ownable {
  string public baseUri;
  uint256 public totalSupply;

  constructor() ERC721('DAC Honorary Members', 'DACH') {
    baseUri = '';
  }

  event SetBaseUri(string indexed baseUri);

  // -----------------
  // Utility functions
  // -----------------

  function exists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  function getNextId(uint256 currentId) internal view returns (uint256) {
    uint256 tokenId = currentId + 1;

    if (_exists(tokenId)) {
      return getNextId(tokenId);
    }

    return tokenId;
  }

  function mintCommunitySpecific(address _to, uint256 tokenId) private {
    require(!_exists(tokenId), 'Token with this id already exists!');
    require(_to != address(0), 'Cannot mint to zero address.');

    _safeMint(_to, tokenId);
    totalSupply++;
  }

  // -----------------
  // Overrides
  // -----------------

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  // -----------------
  // Admin functions
  // -----------------

  function setBaseUri(string memory _baseUri) external onlyOwner {
    baseUri = _baseUri;
    emit SetBaseUri(baseUri);
  }

  function mintHonorary(address _to) external onlyOwner {
    uint256 tokenId = getNextId(totalSupply);
    mintCommunitySpecific(_to, tokenId);
  }

  function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'No ether left to withdraw');

    (bool success, ) = (msg.sender).call{ value: balance }('');
    require(success, 'Transfer failed.');
  }
}
