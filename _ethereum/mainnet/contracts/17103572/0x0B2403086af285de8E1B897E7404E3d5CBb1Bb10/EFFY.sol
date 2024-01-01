// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC721Permit.sol";
import "./Ownable.sol";

contract EFFY is ERC721Permit, Ownable {
  mapping (uint256 => uint256) public nonces;
  function version() public pure returns (string memory) { return "1"; }
  constructor() ERC721Permit("EFFY", "EFFY", "1") Ownable() {
    _setBaseURI("ipfs://bafybeiabkpuobzmb254odlnwueunp6ov65xrhcjlygpazutbhsbxxqfsyu/");
  }
  function _getAndIncrementNonce(uint256 _tokenId) internal override virtual returns (uint256) {
    uint256 nonce = nonces[_tokenId];
    nonces[_tokenId]++;
    return nonce;
  }
  function setBaseURI(string memory _baseUri) public onlyOwner {
    _setBaseURI(_baseUri);
  }
  function mint(address _to, uint256 _tokenId) public onlyOwner {
    _mint(_to, _tokenId);
  }
  function mintRange(address _to, uint256 _start, uint256 _end) public onlyOwner {
    for (uint256 i = _start; i < _end; i++) {
      _mint(_to, i);
    }
  }
}
  
