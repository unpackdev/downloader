// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./Strings.sol";

contract BodyHub is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using ECDSA for bytes32;
  uint256 public immutable collectionSize;

  mapping(address => uint256) public whitelistUsed;
  mapping(address => uint256) public publicSaleUsed;
  bool public _isSWhitelistSaleActive = true;
  bool public _isWhitelistSaleActive = true;
  bool public _isSaleActive = true;
  uint256 public SWhitelistPrice = 0.88 ether;
  uint256 public whitelistPrice = 1 ether;
  uint256 public mintPrice = 1.2 ether;
  uint256 public limit = 3;
  address private _SWhitelistSigner = 0x6a389354957955Bef004222B3dBF4FAb40Ace650;
  address private _WhitelistSigner = 0xba19Eafd7F77EaCedD0f0D72a5CBe570dC48472C;
  address private _PublicSigner = 0xF69e9080320eEDC943e9Fe69b3A08cF16151900e;
  address private subAddress_one = 0xbb965b3F9B4d6b9E637FEc45DCA0F83eEE32427B;
  address private subAddress_two = 0x553CAb5161b5BAAfD42e78Cc7f34350A6412b394;
  receive() external payable {}

  constructor(uint256 collectionSize_) ERC721A("BodyHub", "BH") {
    collectionSize = collectionSize_;
  }
  function flipWhitelistSaleActive() public onlyOwner {
    _isWhitelistSaleActive = !_isWhitelistSaleActive;
  }

  function flipSaleActive() public onlyOwner {
    _isSaleActive = !_isSaleActive;
  }

  function flipSWhitelistSaleActive() public onlyOwner {
    _isSWhitelistSaleActive = !_isSWhitelistSaleActive;
  }

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  function setWhiteListPrice(uint256 _whitelistPrice) public onlyOwner {
    whitelistPrice = _whitelistPrice;
  }

  function setLimit(uint256 _limit) public onlyOwner {
    limit = _limit;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function SWhitelistMint(bytes32 hash, bytes calldata signature, uint256 quantity) external payable callerIsUser {
    require(msg.value * quantity >= SWhitelistPrice, "Need to send more ETH.");
    require(_isSWhitelistSaleActive, "SWhitelistSale has not begin");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(matchAddresSigner(hash, signature, _SWhitelistSigner), "DIRECT_MINT_DISALLOWED");
    require(hashTransaction(msg.sender, quantity) == hash, "HASH_FAIL");
    require(whitelistUsed[msg.sender] + quantity <= limit, "Quantity is over limit");
    _safeMint(msg.sender, quantity);
    whitelistUsed[msg.sender] += quantity;
  }

  function whitelistMint(bytes32 hash, bytes calldata signature, uint256 quantity) external payable callerIsUser {
    require(msg.value * quantity >= whitelistPrice, "Need to send more ETH.");
    require(_isWhitelistSaleActive, "Whitelist Sale has not begin");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(matchAddresSigner(hash, signature, _WhitelistSigner), "DIRECT_MINT_DISALLOWED");
    require(hashTransaction(msg.sender, quantity) == hash, "HASH_FAIL");
    require(whitelistUsed[msg.sender] + quantity <= limit, "Quantity is over limit");
    _safeMint(msg.sender, quantity);
    whitelistUsed[msg.sender] += quantity;
  }

  function publicSaleMint(bytes32 hash, bytes calldata signature, uint256 quantity) external payable callerIsUser {
    require(msg.value * quantity >= mintPrice, "Need to send more ETH.");
    require(_isSaleActive, "Public sale has not begin");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(matchAddresSigner(hash, signature, _PublicSigner), "DIRECT_MINT_DISALLOWED");
    require(hashTransaction(msg.sender, quantity) == hash, "HASH_FAIL");
    require(publicSaleUsed[msg.sender] + quantity <= limit, "Quantity is over limit");
    _safeMint(msg.sender, quantity);
    publicSaleUsed[msg.sender] += quantity;
  }

  // For marketing etc.
  function devMint(uint256 quantity, address to) external onlyOwner {
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    _safeMint(to, quantity);
  }

  function hashTransaction(address sender, uint256 qty) private pure returns(bytes32) {
    bytes32 hash = keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      keccak256(abi.encodePacked(sender, qty)))
    );
    return hash;
  }

  function matchAddresSigner(bytes32 hash, bytes memory signature, address _signerAddress) private pure returns(bool) {
    return _signerAddress == hash.recover(signature);
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

	function withdraw(address to) public onlyOwner {
		uint256 balance = address(this).balance;
		payable(subAddress_one).transfer((balance * 5) / 100);
		payable(subAddress_two).transfer((balance * 5) / 100);
		payable(to).transfer((balance * 90) / 100);
	}

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}
