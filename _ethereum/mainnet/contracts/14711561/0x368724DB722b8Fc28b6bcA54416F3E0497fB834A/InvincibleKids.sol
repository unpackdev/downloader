//SPDX-License-Identifier: MIT
/*
 _____ _   _ _  _______ _____   _____ 
|_   _| \ | | |/ /_   _|  __ \ / ____|
  | | |  \| | ' /  | | | |  | | (___  
  | | | . ` |  <   | | | |  | |\___ \ 
 _| |_| |\  | . \ _| |_| |__| |____) |
|_____|_| \_|_|\_\_____|_____/|_____/ 
                                      
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(##(((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&#((((((((((((((((((((((((##@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@%#(((((((((((((((((((((((((((((%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%(((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#((((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@##(((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#((((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@##(((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#(((((((((((((((((((((((((((((((((##@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&#((((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&#(((((((((((((((((((((((((((((((((((((&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&((((((((((((((((((((((((((((((((((((((&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#((((((((((((((((((((((((((((((((((((&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&&#(#(((((((((((((((#%&&&%###((((#@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#((((((((((((((##&&##(((((#&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##(((((((((((((((###%@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&((((((((((##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%%#(##((((((((((((((#%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@&%((((((((((((((((((((((((((#&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%#(((((((((((((((((((((((((((&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%((((((((((((((((((((((((((##&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&((((((((((((###((##(%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract InvincibleKids is ERC721, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;

  uint256 public constant MAX_SUPPLY = 3_333;
  Counters.Counter private _tokenIdCounter;
  string private _baseTokenURI;
  uint256 private _mintPrice;
  uint256 private _maxQuantityPerTx;
  bool private _isPublicMintActive = false;
  bool private _isWhitelistMintActive = false;
  bytes32 private _merkleRoot;
  uint256 private _maxQuantityPerWhitelistWallet;
  mapping(address => uint256) private _whitelistMinted;

  constructor(
    string memory baseTokenURI,
    uint256 mintPrice,
    uint256 maxQuantityPerTx,
    uint256 maxQuantityPerWhitelistWallet
  ) ERC721("Invincible Kids", "INKIDS") {
    setBaseTokenURI(baseTokenURI);
    setMintPrice(mintPrice);
    setMaxQuantityPerTx(maxQuantityPerTx);
    setMaxQuantityPerWhitelistWallet(maxQuantityPerWhitelistWallet);
  }

  /* Mint management */
  modifier mintable(uint256 quantity) {
    require(quantity <= _maxQuantityPerTx, "Quantity too high.");
    require(msg.value >= _mintPrice * quantity, "Value too low.");
    _;
  }

  function publicMint(uint256 quantity) external payable mintable(quantity) {
    require(_isPublicMintActive, "Public mint is not available.");
    _safeMintTo(msg.sender, quantity);
  }

  function whitelistMint(uint256 quantity, bytes32[] calldata proof)
    external
    payable
    mintable(quantity)
  {
    require(_isWhitelistMintActive, "Whitelist mint is not available.");
    require(
      MerkleProof.verify(
        proof,
        _merkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Caller is not whitelisted."
    );
    require(
      _whitelistMinted[msg.sender] + quantity <= _maxQuantityPerWhitelistWallet,
      "Whitelist mint limit exceeded."
    );
    _whitelistMinted[msg.sender] += quantity;
    _safeMintTo(msg.sender, quantity);
  }

  function ownerMint(uint256 quantity) external onlyOwner {
    _safeMintTo(msg.sender, quantity);
  }

  function ownerMintTo(address to, uint256 quantity) external onlyOwner {
    _safeMintTo(to, quantity);
  }

  function _safeMintTo(address to, uint256 quantity) private {
    require(
      _tokenIdCounter.current() + quantity <= MAX_SUPPLY,
      "Max supply reached."
    );
    for (uint256 i = 0; i < quantity; i++) {
      _tokenIdCounter.increment();
      _safeMint(to, _tokenIdCounter.current());
    }
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIdCounter.current();
  }

  /* BaseTokenURI */
  function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  function getBaseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return getBaseTokenURI();
  }

  /* MintPrice */
  function setMintPrice(uint256 mintPrice) public onlyOwner {
    _mintPrice = mintPrice;
  }

  function getMintPrice() public view returns (uint256) {
    return _mintPrice;
  }

  /* MaxQuantityPerTx */
  function setMaxQuantityPerTx(uint256 maxQuantityPerTx) public onlyOwner {
    _maxQuantityPerTx = maxQuantityPerTx;
  }

  function getMaxQuantityPerTx() public view returns (uint256) {
    return _maxQuantityPerTx;
  }

  /* IsPublicMintActive */
  function setIsPublicMintActive(bool isPublicMintActive) public onlyOwner {
    _isPublicMintActive = isPublicMintActive;
  }

  function getIsPublicMintActive() public view returns (bool) {
    return _isPublicMintActive;
  }

  /* IsWhitelistMintActive */
  function setIsWhitelistMintActive(bool isWhitelistMintActive)
    public
    onlyOwner
  {
    _isWhitelistMintActive = isWhitelistMintActive;
  }

  function getIsWhitelistMintActive() public view returns (bool) {
    return _isWhitelistMintActive;
  }

  /* Merkle Root */
  function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
    _merkleRoot = merkleRoot;
  }

  function getMerkleRoot() public view returns (bytes32) {
    return _merkleRoot;
  }

  /* MaxQuantityPerWhitelistWallet */
  function setMaxQuantityPerWhitelistWallet(
    uint256 maxQuantityPerWhitelistWallet
  ) public onlyOwner {
    _maxQuantityPerWhitelistWallet = maxQuantityPerWhitelistWallet;
  }

  function getMaxQuantityPerWhitelistWallet() public view returns (uint256) {
    return _maxQuantityPerWhitelistWallet;
  }

  /* Withdrawing */
  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }(
      ""
    );
    require(success, "Transfer failed.");
  }
}
