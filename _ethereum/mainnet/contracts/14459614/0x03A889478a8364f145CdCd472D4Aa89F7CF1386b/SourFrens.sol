//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract SourFrens is ERC721A, ReentrancyGuard, Ownable {
  uint256 public constant MAX_SUPPLY = 3333;
  uint256 public constant PUBLIC_MINT_WALLET_LIMIT = 4;
  uint256 public constant PRIVATE_MINT_WALLET_LIMIT = 2;

  // SALE STAGE
  // [0] Paused
  // [1] Private Sale
  // [2] Public Sale
  uint8 public saleStage = 0;

  uint256 public price = 0.07 ether;

  string private ipfsBaseURI;

  bytes32 merkleRoot;

  constructor() ERC721A("SourFrens", "SOURFREN") {}

  // MINT
  function remainingMint(address user) public view returns (uint256) {
    if (saleStage == 0) return 0;

    uint256 totalSupply = totalSupply();
    uint256 remaining = (
      saleStage == 1 ? PRIVATE_MINT_WALLET_LIMIT : PUBLIC_MINT_WALLET_LIMIT
    ) - _numberMinted(user);
    return
      (MAX_SUPPLY - totalSupply < remaining)
        ? MAX_SUPPLY - totalSupply
        : remaining;
  }

  function mint(uint256 quantity, bytes32[] calldata proof)
    external
    payable
    nonReentrant
  {
    require(tx.origin == msg.sender, "Caller must be a user");
    require(saleStage != 0, "Sale not started");

    if (saleStage == 1) {
      require(merkleRoot != 0, "Whitelist root not set");
      require(
        MerkleProof.verify(
          proof,
          merkleRoot,
          keccak256(abi.encodePacked(msg.sender))
        ),
        "Invalid whitelist proof"
      );
    }

    require(quantity > 0, "Quantity must be positive");
    require(quantity <= remainingMint(msg.sender), "Exceeds wallet mint limit");
    require(price * quantity <= msg.value, "Not enough ether");

    _safeMint(msg.sender, quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return ipfsBaseURI;
  }

  // OWNER FUNCTIONS
  function mintOwner(uint256 quantity) external onlyOwner {
    require(quantity > 0, "Quantity must be positive");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Supply reached");

    _safeMint(msg.sender, quantity);
  }

  function withdrawTo(address payable to) external onlyOwner {
    to.transfer(address(this).balance);
  }

  function setBaseURI(string calldata _ipfsBaseURI) external onlyOwner {
    ipfsBaseURI = _ipfsBaseURI;
  }

  function setSaleStage(uint8 _saleStage) external onlyOwner {
    saleStage = _saleStage;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
}
