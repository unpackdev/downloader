// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Nothing is ERC721A, Ownable {

  using Strings for uint256;

  uint256 private constant SUPPLY = 5555;
  uint256 private constant ALLOWANCE = 5;

  constructor() ERC721A("Nothing", "NOTHING") {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function Mint(uint256 _quantity) external callerIsUser {
    require(totalSupply() + _quantity <= SUPPLY, "EXCEEDS MAX SUPPLY");
    require(
      numberMinted(msg.sender) + _quantity <= ALLOWANCE,
      "EXCEEDS ALLOWANCE"
    );

    _mint(msg.sender, _quantity);
  }

  function numberMinted(address _owner) public view returns (uint256) {
    return _numberMinted(_owner);
  }

  function getOwnershipData(uint256 _tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(_tokenId);
  }
}
