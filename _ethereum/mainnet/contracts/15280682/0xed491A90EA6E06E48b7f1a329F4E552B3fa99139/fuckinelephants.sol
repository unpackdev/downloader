// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";

contract FuckinElephants is ERC721A, ERC721AQueryable, Ownable {
  uint256 constant EXTRA_MINT_PRICE = 0.003 ether;
  uint256 constant MAX_SUPPLY_PLUS_ONE = 4001;
  uint256 constant MAX_PER_TRANSACTION_PLUS_ONE = 4;

  string tokenBaseUri = "ipfs://bafybeiago5gen5bqoqti4kfsk7yg23r424a7kj7j2ec7szlz3x76ootxga/";

  bool public paused = false;

  mapping(address => uint256) private _freeMintedCount;

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  constructor() ERC721A("Fuckin' Elephants", "FKNELE") {
      _mint(msg.sender, 1);
  }

  function mint(uint256 _quantity) external payable callerIsUser {
    require(!paused, "Mint is paused.");

    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _quantity < MAX_SUPPLY_PLUS_ONE, "No mints left.");
    require(_quantity < MAX_PER_TRANSACTION_PLUS_ONE, "Attempting to mint too many at once.");

    // Free Mints
    uint256 payForCount = _quantity;
    uint256 freeMintCount = _freeMintedCount[msg.sender];

    if (freeMintCount < 1) {
      if (_quantity > 1) {
        payForCount = _quantity - 1;
      } else {
        payForCount = 0;
      }

      _freeMintedCount[msg.sender] = 1;
    }

    require(msg.value >= payForCount * EXTRA_MINT_PRICE, "Not enough eth sent.");

    _mint(msg.sender, _quantity);
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMintedCount[owner];
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw failed."
    );
  }
}
