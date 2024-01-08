// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/********************
* @author: Squeebo *
********************/

import "./ERC721EnumerableB.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";


contract DumpsterDegens is ERC721EnumerableB, Ownable, PaymentSplitter {
  using Strings for uint256;

  uint256 public TOTAL_SUPPLY    = 4000;

  bool public is_locked          = true;

  uint public price              = 0.03 ether;

  string private _baseTokenURI = 'https://dumpsterdegens.com/metadata.php?tokenID=';
  string private _tokenURISuffix = '';

  constructor(address[] memory payees, uint[] memory splits)
    ERC721B( "Dumpster Degens", "DD" )
    PaymentSplitter(payees, splits){
  }

  //external
  function mint(uint256 quantity) external payable {
    uint256 balance = totalSupply();
    require( !is_locked,                         "Sale is locked"           );
    require( quantity           <= 20,           "Order too big"            );
    require( balance + quantity <= TOTAL_SUPPLY, "Exceeds supply"           );
    require( msg.value >= price * quantity,      "Ether sent is not correct" );

    for( uint256 i; i < quantity; ++i ){
      _safeMint( msg.sender, balance + i );
    }
  }

  //onlyOwner
  function gift(uint256 quantity, address recipient) external onlyOwner {
    uint256 balance = totalSupply();
    require( balance + quantity <= TOTAL_SUPPLY, "Exceeds supply" );

    for(uint256 i; i < quantity; ++i ){
      _safeMint( recipient, balance + i );
    }
  }

  function setLocked(bool is_locked_) external onlyOwner {
    is_locked = is_locked_;
  }

  function setMaxSupply(uint maxSupply) external onlyOwner {
    require(maxSupply > totalSupply(), "Specified supply is lower than current balance" );
    TOTAL_SUPPLY = maxSupply;
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    price = newPrice;
  }

  function withdraw() external onlyOwner {
      require(address(this).balance >= 0, "No funds available");
      Address.sendValue(payable(owner()), address(this).balance);
  }

  //metadata
  function setBaseURI(string memory baseURI, string memory suffix) external onlyOwner {
    _baseTokenURI = baseURI;
    _tokenURISuffix = suffix;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }

  //external
  fallback() external payable {}
}
