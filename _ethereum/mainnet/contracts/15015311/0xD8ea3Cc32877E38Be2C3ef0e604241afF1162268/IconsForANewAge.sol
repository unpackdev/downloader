// contracts/IconsForNewAge.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";

import "./ERC721Tradable.sol";

contract IconsForANewAge is ERC721Tradable {
  string private _contract_uri;
  string private _base_token_uri;

  constructor(address _proxyRegistryAddress, address royalty_reciever, uint96 fee_numerator, string memory base_token_uri, string memory contract_uri)
    ERC721Tradable("Icons For A New Age", "IFANA", _proxyRegistryAddress)
  {
    _setDefaultRoyalty(royalty_reciever, fee_numerator);
    _contract_uri = contract_uri;
    _base_token_uri = base_token_uri;
  }

  function contractURI() public view returns (string memory) {
    return _contract_uri;
  }

  function baseTokenURI() override public view returns (string memory) {
    return _base_token_uri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return _base_token_uri;
  }
}
