// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC721Permit.sol";
import "./Ownable.sol";

contract KUSH is ERC721Permit, Ownable {
  mapping (uint256 => uint256) public nonces;
  function version() public pure returns (string memory) { return "1"; }
  constructor() ERC721Permit("KUSH", "KUSH", "1") Ownable() {
    _setBaseURI("ipfs://bafybeih243vzhotmr3cjyunrws6jghoucprj4vrh7jwlck2pcn2vydx5bm/");
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
}
  
