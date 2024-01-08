// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./Strings.sol";
import "./ERC721.sol";

contract Metatest is ERC721 {

  string public baseUri;

  constructor(string memory _name, string memory _symbol, uint256 _totalSupply, string memory _baseUri) 
    ERC721(_name, _symbol) {
      baseUri = _baseUri;

      for (uint256 i = 0; i < _totalSupply; i++) {
        _mint(_msgSender(), i + 1);
      }
  }


  function uri(uint256 id) external view returns (string memory) {
    return string(abi.encodePacked(baseUri, Strings.toString(id)));
  }

    function supportsInterface(bytes4 interfaceId) 
    public virtual override(ERC721) view returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
  }
}
