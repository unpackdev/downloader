// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AOwnersExplicit.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Counters.sol";

contract MirlPfp is ERC721A, Pausable, AccessControl, ERC721ABurnable, ERC721AOwnersExplicit {
  using Counters for Counters.Counter;

  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  Counters.Counter private _tokenIdCounter;

  constructor() ERC721A('MIRL 1/1', 'MIRL') {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

    // Start from 1
    _tokenIdCounter.increment();
  }

  function _baseURI() internal pure override returns (string memory) {
    return 'https://nft.mirl.club/pfp/';
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function safeMint(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(to, quantity);
  }

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 tokenId,
    uint256 quantity
  ) internal override whenNotPaused {
    super._beforeTokenTransfers(from, to, tokenId, quantity);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
