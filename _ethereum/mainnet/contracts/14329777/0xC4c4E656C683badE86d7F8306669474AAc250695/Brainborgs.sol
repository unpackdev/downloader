// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Borgmutation is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private currentTokenId;

  string public constant NAME = "Borgmutation | Brainborgs";
  string public constant SYMBOL = "BORGMUTATIONBRAINBORGS";
  uint256 public constant MAX_SUPPLY = 625;
  uint256 public constant MINT_PRICE = 0.03 ether;
  bool public MINTING_OPEN;

  address OWNER_ADDRESS;
  string BASE_URI = "ipfs://bafybeih6dxfyhrdfcacgwdtomsxwceimnac2eysnlgd7mwbbtojfpue2ui/";

  constructor() ERC721(NAME, SYMBOL) {
    OWNER_ADDRESS = msg.sender;
  }

  function mint(uint256 _mintAmount) public payable {
    require(MINTING_OPEN, "MINTING NOT OPEN");
    require(_mintAmount > 0, "Invalid mint amount!");
    require(_mintAmount > 0 && MAX_SUPPLY >= currentTokenId.current() + _mintAmount, "Your transaction would exceed MAX_SUPPLY!");
    require(msg.value >= MINT_PRICE * _mintAmount, "Transaction value did not match mint price!");

    mintBorgs(_mintAmount, msg.sender);
  }

  function mintOwner(uint256 _mintAmount) public payable onlyOwner {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(MAX_SUPPLY >= currentTokenId.current() + _mintAmount, "Your transaction would exceed MAX_SUPPLY!");

    mintBorgs(_mintAmount, OWNER_ADDRESS);
  }

  function mintBorgs(uint _mintAmount, address _receiver) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      currentTokenId.increment();
      _safeMint(_receiver, currentTokenId.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner  {
    BASE_URI = baseURI;
  }

  function setMintingOpen(bool mintingOpen) public onlyOwner  {
    MINTING_OPEN = mintingOpen;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}
