// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract SunBirds is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bool public collection_revealed = false;
  uint256 public cost = 0.069 ether;
  uint256 public max_supply = 10000;
  string public baseURI;
  string public revealURI = "https://ipfs.io/ipfs/QmW7GTc1o9aDV8XxeAWtbZZrjzvoEtntA8Rk7iSq5qGv2J";
  
  constructor() ERC721A("Sunbirds", "SUNBIRD") {}

  function purchase(uint256 _token_amount) external payable nonReentrant {
    
    require(msg.value >= cost * _token_amount, "insufficient_funds");
    uint256 supply = totalSupply();
    require(_token_amount > 0, "quantity_is_required");
    require(_token_amount + supply <= max_supply, "max_supply_exceedeed" );

    _safeMint(msg.sender, _token_amount);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "non_existant_token");
    if (collection_revealed) {
      return string(abi.encodePacked(baseURI, _tokenId.toString()));
    } else {
      return revealURI;
    }
  }

  function set_base_uri(string memory _new_base_uri) public onlyOwner {
    baseURI = _new_base_uri;
  }

  function set_reveal_uri(string memory _new_reveal_uri) public onlyOwner {
    revealURI = _new_reveal_uri;
  }

  function set_collection_revealed(bool _new_collection_revealed_state) public onlyOwner {
    collection_revealed = _new_collection_revealed_state;
  }

  function set_max_supply(uint256 _new_max_supply) public onlyOwner {
    max_supply = _new_max_supply;
  }

  function set_cost(uint256 _new_cost) public onlyOwner {
    cost = _new_cost;
  } 

  function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    payable(0xCaC046ea7Cfc145EFD5dF785471E74cF920b08aB).transfer(balance);
  }
}