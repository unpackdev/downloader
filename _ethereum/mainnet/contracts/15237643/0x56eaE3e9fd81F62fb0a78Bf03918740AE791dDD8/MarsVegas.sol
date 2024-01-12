// ##     ##    ###    ########   ######     ##     ## ########  ######      ###     ######
// ###   ###   ## ##   ##     ## ##    ##    ##     ## ##       ##    ##    ## ##   ##    ##
// #### ####  ##   ##  ##     ## ##          ##     ## ##       ##         ##   ##  ##
// ## ### ## ##     ## ########   ######     ##     ## ######   ##   #### ##     ##  ######
// ##     ## ######### ##   ##         ##     ##   ##  ##       ##    ##  #########       ##
// ##     ## ##     ## ##    ##  ##    ##      ## ##   ##       ##    ##  ##     ## ##    ##
// ##     ## ##     ## ##     ##  ######        ###    ########  ######   ##     ##  ######

// Developers: Setonix (https://setonixstudio.com/)
// Artists: Gazzar (https://gazzarstudio.com/)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract MarsVegas is ERC721A, ReentrancyGuard, Ownable {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  enum MintStatus {
    CLOSED, // contract fully closed for non-admin actions
    PUBLIC, // free mint opened
    PRESALE, // free whitelist
    SALE // paid mint opened
  }
  uint256 public MAX_SUPPLY = 7777;

  // Maximum number of tokens that can be minted for single account
  uint256 public maxTokenPerWallet = 1;
  // the token price for whitelist
  uint256 public price;

  // Number of tokens issued for sale
  uint256 public issuedTotal;

  string private baseUri;

  string internal _unrevealedURI;

  bytes32 public merkleRoot;

  bool public revealed;

  MintStatus public mintStatus = MintStatus.CLOSED;

  mapping(address => uint256) public martianOwners;
  mapping(address => uint256) public alphaOwners;

  constructor(string memory hiddenUri) ERC721A("MarsVegas", "MVN") {
    _unrevealedURI = hiddenUri;
  }

  modifier canMint(uint256 quantity) {
    require(mintStatus != MintStatus.CLOSED, "CONTRACT_LOCKED");
    require(quantity <= remainingUnsoldSupply(), "NOT_ENOUGH_ISSUED_TOKEN");
    require(totalMinted() + quantity <= MAX_SUPPLY, "TOKENS_EXPIRED");
    _;
  }

  // --- Administrative --- //
  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseUri = baseURI;
  }

  function setUnrevealedURI(string calldata unrevealedURI) external onlyOwner {
    _unrevealedURI = unrevealedURI;
  }

  function reveal() external onlyOwner {
    revealed = !revealed;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMaxMint(uint256 newLimit) external onlyOwner {
    maxTokenPerWallet = newLimit;
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    price = newPrice;
  }

  function issue(uint256 number) external onlyOwner {
    require(number <= remainingUnissuedSupply(), "TOKENS_EXPIRED");
    issuedTotal += number;
  }

  function setMintStatus(MintStatus status) external onlyOwner {
    mintStatus = status;
  }

  function airdrop(address[] calldata entries, uint256 quantity, bool _isAlpha) external onlyOwner {
    require(totalMinted() + (entries.length * quantity) <= MAX_SUPPLY, "TOKENS_EXPIRED");

    for (uint256 i = 0; i < entries.length; i++) {
      if (_isAlpha) {
        alphaOwners[entries[i]] += quantity;
      } else {
        martianOwners[entries[i]] += quantity;
      }
      _safeMint(entries[i], quantity);
    }

  }

  function withdraw() external onlyOwner nonReentrant {
    payable(msg.sender).transfer(address(this).balance);
  }

  // --- Public --- //
  function freeMint() external canMint(1) {
    require(mintStatus == MintStatus.PUBLIC, "FREE_MINT_CLOSED");
    require(
      martianOwners[msg.sender] + 1 <= maxTokenPerWallet,
      "WALLET_LIMIT_EXCEEDED"
    );
    martianOwners[msg.sender] += 1;
    _safeMint(msg.sender, 1);
  }

  function presaleMint(bytes32[] memory _merkleProof) external canMint(1) {
    require(mintStatus == MintStatus.PRESALE, "PRESALE_CLOSED");
    require(
      martianOwners[msg.sender] + 1 <= maxTokenPerWallet,
      "WALLET_LIMIT_EXCEEDED"
    );
    // Generate leaf node from callee
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    // Check the proof
    require(_merkleProof.verify(merkleRoot, leaf), "INVALID_MERKLE_PROOF");

    martianOwners[msg.sender] += 1;
    _safeMint(msg.sender, 1);
  }

  function mint() external payable canMint(1) {
    require(mintStatus == MintStatus.SALE, "SALE_CLOSED");
    require(msg.value >= price * 1, "INSUFFICIENT_VALUE");
    require(
      alphaOwners[msg.sender] + 1 <= maxTokenPerWallet,
      "WALLET_LIMIT_EXCEEDED"
    );

    alphaOwners[msg.sender] += 1;

    _safeMint(msg.sender, 1);
  }

  // --- Views --- //
  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function remainingUnissuedSupply() public view returns (uint256) {
    return MAX_SUPPLY - issuedTotal;
  }

  function remainingUnsoldSupply() public view returns (uint256) {
    return issuedTotal - totalMinted();
  }

  // --- Overrides --- //
  function _baseURI() internal view virtual override returns (string memory) {
    return baseUri;
  }

  function tokenURI(uint256 tokenId)
  public
  view
  virtual
  override(ERC721A)
  returns (string memory)
  {
    require(_exists(tokenId), "TOKEN_NOT_EXISTS");
    if (!revealed) {
      return _unrevealedURI;
    }

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
  }

  function _afterTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity)
  internal virtual override(ERC721A) {
    super._afterTokenTransfers(from, to, tokenId, quantity);
  }

  function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity)
  internal virtual override(ERC721A) {
    super._beforeTokenTransfers(from, to, tokenId, quantity);
  }

}
