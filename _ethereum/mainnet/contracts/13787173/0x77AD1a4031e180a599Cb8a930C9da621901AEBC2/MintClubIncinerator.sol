// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ========== Imports ========== //
import "./AdminControl.sol";
import "./ERC1155Burnable.sol";
import "./ReentrancyGuard.sol";

contract MintClubIncinerator is AdminControl, ReentrancyGuard {
  uint8 constant GOLD_TOKEN_ID = 1;
  uint8 constant BASIC_TOKEN_ID = 2;

  address immutable MINT_TOKEN_ADDRESS;

  mapping(address => bool) public approvedContracts;

  constructor(address _mintTokenAddress) {
    MINT_TOKEN_ADDRESS = _mintTokenAddress;
  }

  function burnGoldTokens(address _tokenOwner, uint256 _qty) external nonReentrant {
    _burnTokens(_tokenOwner, GOLD_TOKEN_ID, _qty);
  }

  function burnBasicTokens(address _tokenOwner, uint256 _qty) external nonReentrant {
    _burnTokens(_tokenOwner, BASIC_TOKEN_ID, _qty);
  }

  function _burnTokens(address _tokenOwner, uint256 _tokenId, uint256 _qty) internal {
    require(approvedContracts[msg.sender], "Contract is not approved");
    require(ERC1155Burnable(MINT_TOKEN_ADDRESS).isApprovedForAll(_tokenOwner, address(this)), "Mint tokens are not approved");

    ERC1155Burnable(MINT_TOKEN_ADDRESS).burn(_tokenOwner, _tokenId, _qty);
  }

  function toggleApprovedContract(address _contractAddress) public onlyAdmin {
    approvedContracts[_contractAddress] = !approvedContracts[_contractAddress];
  }
}