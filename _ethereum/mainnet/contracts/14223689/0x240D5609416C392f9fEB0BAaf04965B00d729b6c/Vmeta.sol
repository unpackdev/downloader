// SPDX-License-Identifier: MIT

/*
 _   ____  ___ _____ _____ ___                                                        
| | | |  \/  ||  ___|_   _/ _ \                                                       
| | | | .  . || |__   | |/ /_\ \                                                      
| | | | |\/| ||  __|  | ||  _  |                                                      
\ \_/ / |  | || |___  | || | | |                                                      
 \___/\_|  |_/\____/  \_/\_| |_/                                                      
                                                                                      
                                                                                      
 ___________  ___ ______ _____   _     _____ _   __ _____    ___    _____ ___________ 
|_   _| ___ \/ _ \|  _  \  ___| | |   |_   _| | / /|  ___|  / _ \  |  __ \  _  |  _  \
  | | | |_/ / /_\ \ | | | |__   | |     | | | |/ / | |__   / /_\ \ | |  \/ | | | | | |
  | | |    /|  _  | | | |  __|  | |     | | |    \ |  __|  |  _  | | | __| | | | | | |
  | | | |\ \| | | | |/ /| |___  | |_____| |_| |\  \| |___  | | | | | |_\ \ \_/ / |/ / 
  \_/ \_| \_\_| |_/___/ \____/  \_____/\___/\_| \_/\____/  \_| |_/  \____/\___/|___/                                                                                                                                                                                       
*/

pragma solidity ^0.8.9;

import "./console.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract Vmeta is ERC721, Pausable, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;

  // for developers and marketers
  uint256 NUM_INTERNAL_TOKENS = 100;

  string private _baseTokenURI = "https://contract-api.vmeta.ai/api/token/";
  uint256 private _price;
  uint256 private _presalePrice;
  uint256 private _presaleAllowedAmount;
  
  address private _internalTokenWallet;
  address private _paymentWallet;

  uint256 private _totalSupply;

  // Whitelist
  bytes32 public _whitelistMerkleRoot;
  mapping(address => uint256) public claimedWhitelist;

  // Sale control
  enum MintStatus {
    CLOSED,
    PRESALE,
    PUBLIC
  }
  MintStatus private _mintStatus = MintStatus.CLOSED;

  Counters.Counter private _tokenIdCounter;

  event Mint(address indexed _address, uint256 tokenId);

  constructor(
    uint256 presalePrice,
    uint256 price,
    uint256 presaleAllowedAmount,
    address internalTokenWallet,
    address paymentWallet,
    uint256 totalSupply,
    bytes32 whitelistMerkleRoot
  ) ERC721("VMeta Membership Token", "VMETA") {
    _presalePrice = presalePrice;
    _price = price;
    _presaleAllowedAmount = presaleAllowedAmount;
    _internalTokenWallet = internalTokenWallet;
    _paymentWallet = paymentWallet;
    _totalSupply = totalSupply;
    _whitelistMerkleRoot = whitelistMerkleRoot;

    // Minting tokens for developers and marketing
    for (uint256 i = 0; i < NUM_INTERNAL_TOKENS; i++) {
      _mintPrivate(_internalTokenWallet);
    }
  }

  function mint(uint256 amount, bytes32[] calldata proof)
    public
    payable
    whenNotPaused
    nonReentrant
  {
    require(_mintStatus != MintStatus.CLOSED, "Sale inactive");
    if (_mintStatus == MintStatus.PUBLIC) {
      _mintPublic(amount);
    } else if (_mintStatus == MintStatus.PRESALE) {
      _mintPresale(amount, proof);
    }
  }

  function _mintPublic(uint256 amount) private {
    require(_mintStatus == MintStatus.PUBLIC, "Public Sale inactive");
    require(
      _tokenIdCounter.current() + amount <= _totalSupply,
      "Can't mint over supply limit"
    );
    require(msg.value >= _price * amount, "Not enough ether");
    for (uint256 i = 0; i < amount; i++) {
      _mintPrivate(msg.sender);
    }

    emit Mint(msg.sender, _tokenIdCounter.current());
  }

  function _mintPresale(uint256 amount, bytes32[] calldata proof) private {
    require(_mintStatus == MintStatus.PRESALE, "Pre-sale inactive");
    require(
      _tokenIdCounter.current() + amount <= _totalSupply,
      "Can't mint over supply limit"
    );
    require(
      MerkleProof.verify(
        proof,
        _whitelistMerkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Address is not whitelisted"
    );
    require(claimedWhitelist[msg.sender] + amount <= _presaleAllowedAmount, "Cannot mint over the allowed amount");

    require(msg.value >= _presalePrice * amount, "Not enough ether");

    claimedWhitelist[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) {
      _mintPrivate(msg.sender);
    }

    emit Mint(msg.sender, _tokenIdCounter.current());
  }

  function _mintPrivate(address to) private {
    _tokenIdCounter.increment();
    _safeMint(to, _tokenIdCounter.current());
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(_paymentWallet).transfer(balance);
  }

  function getBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function getPrice() external view returns (uint256) {
    return _price;
  }

  function setPrice(uint256 price) public onlyOwner {
    _price = price;
  }

  function getPresalePrice() external view returns (uint256) {
    return _presalePrice;
  }

  function setPresalePrice(uint256 presalePrice) public onlyOwner {
    _presalePrice = presalePrice;
  }

  function getPresaleAllowedAmount() external view returns (uint256) {
    return _presaleAllowedAmount;
  }

  function setPresaleAllowedAmount(uint256 presaleAllowedAmount) public onlyOwner {
    _presaleAllowedAmount = presaleAllowedAmount;
  }

  function changePaymentWallet(address _address) public onlyOwner {
    _paymentWallet = _address;
  }

  function getStatus() external view returns (MintStatus) {
    return _mintStatus;
  }

  function setStatus(uint8 _status) external onlyOwner {
    _mintStatus = MintStatus(_status);
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function updateWhitelistMerkleRoot(bytes32 whitelistMerkleRoot) public onlyOwner {
    _whitelistMerkleRoot = whitelistMerkleRoot;
  }

  function pause() public onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() public onlyOwner whenPaused {
    _unpause();
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function hasFoundingMemberToken(address wallet) public view returns (bool) {
    return balanceOf(wallet) > 0;
  }

  function tokensSold() public view returns (uint256) {
    return _tokenIdCounter.current();
  }

  function getTotalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function setTotalSupply(uint256 totalSupply) public onlyOwner {
    require(
      _tokenIdCounter.current() <= totalSupply,
      "Total supply cannot be lower than existing tokens"
    );
    _totalSupply = totalSupply;
  }
}