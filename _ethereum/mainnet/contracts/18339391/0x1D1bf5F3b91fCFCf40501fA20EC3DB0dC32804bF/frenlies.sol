// SPDX-License-Identifier: MIT

// https://x.com/frenliesx
// https://frenlies.online/

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Strings.sol";
import "./IERC721A.sol";
import "./ERC721AQueryable.sol";
import "./DefaultOperatorFilterer.sol";

contract FRENLIES is ERC721AQueryable, Ownable, DefaultOperatorFilterer {
  using Strings for uint256;
  uint256 public MAX_SUPPLY = 5555;
  uint256 public MAX_FREE = 5555;
  uint256 public maxFreeMintPerWallet = 1;
  uint256 public maxPublicMintPerWallet = 20;
  uint256 public publicTokenPrice = .002 ether;
  uint256 public maxMintPerTx = 20;
  string _contractURI;

  bool public saleStarted = false;
  uint256 public freeMintCount;

  mapping(address => uint256) public freeMintClaimed;

  string private _baseTokenURI;

  constructor() ERC721A("FRENLIES", "FRENS") {
    _baseTokenURI = "ipfs://bafybeiebnxucicx7sgeifdmpegeosctc45e54lsjv6bevwsm2v3exgwmyq/";
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'FREN: The caller is another contract');
    _;
  }

  modifier underMaxSupply(uint256 _quantity) {
    require(
      _totalMinted() + _quantity <= MAX_SUPPLY,
      "Unable to mint."
    );
    _;
  }

  function setTotalMaxSupply(uint256 _newSupply) external onlyOwner {
      MAX_SUPPLY = _newSupply;
  }

  function setPublicTokenPrice(uint256 _newPrice) external onlyOwner {
      publicTokenPrice = _newPrice;
  }

   function mint(uint256 _quantity) external payable callerIsUser underMaxSupply(_quantity) {
    require(_quantity <= maxMintPerTx, "Exceeds max mint per transaction");
    require(balanceOf(msg.sender) + _quantity <= maxPublicMintPerWallet, "Exceeds max mint per wallet");
    require(saleStarted, "Sale has not started");
    if (_totalMinted() < (MAX_SUPPLY)) {
      if (freeMintCount >= MAX_FREE || freeMintClaimed[msg.sender] >= maxFreeMintPerWallet) {
        require(msg.value >= _quantity * publicTokenPrice, "Payment insufficient");
        _mint(msg.sender, _quantity);
      } else {
        uint256 _mintableFreeQuantity = maxFreeMintPerWallet - freeMintClaimed[msg.sender];
        if (_quantity <= _mintableFreeQuantity) {
          freeMintCount += _quantity;
          freeMintClaimed[msg.sender] += _quantity;
          _mint(msg.sender, _quantity);
        } else {
          freeMintCount += _mintableFreeQuantity;
          freeMintClaimed[msg.sender] += _mintableFreeQuantity;
          require(msg.value >= (_quantity - _mintableFreeQuantity) * publicTokenPrice, "Payment insufficient");
          _mint(msg.sender, _quantity);
        }
      }
    }
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function ownerMint(uint256 _numberToMint) external onlyOwner underMaxSupply(_numberToMint) {
    _mint(msg.sender, _numberToMint);
  }

  function setMaxFreeSupply(uint256 _newMaxFree) external onlyOwner {
    MAX_FREE = _newMaxFree;
  }

  function setMaxFreePerWallet(uint256 _newMaxFreePerWallet) external onlyOwner {
    maxFreeMintPerWallet = _newMaxFreePerWallet;
  }


  function ownerMintToAddress(address _recipient, uint256 _numberToMint)
    external
    onlyOwner
    underMaxSupply(_numberToMint)
  {
    _mint(_recipient, _numberToMint);
  }

  function setMaxPublicMintPerWallet(uint256 _count) external onlyOwner {
    maxPublicMintPerWallet = _count;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public payable
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // Storefront metadata
  // https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory _URI) external onlyOwner {
    _contractURI = _URI;
  }

  function withdrawFunds() external onlyOwner {
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success, "Transfer failed");
  }

  function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
    (bool success, ) = _address.call{ value: amount }("");
    require(success, "Transfer failed");
  }

  function flipSaleStarted() external onlyOwner {
    saleStarted = !saleStarted;
  }
}
