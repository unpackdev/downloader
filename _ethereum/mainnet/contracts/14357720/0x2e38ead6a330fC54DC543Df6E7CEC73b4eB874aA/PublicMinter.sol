// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./MIRL.sol";

contract PublicMinter is Ownable {
  MIRL private token;
  address private contractAddress;
  bytes32 private merkleRoot;
  uint256 public BASE_PRICE = 0.04 ether;
  uint256 public MAX_CAPACITY = 7777;
  uint256 public MAX_PER_BATCH = 2;
  uint256 public MAX_PER_WALLET_WL = 2; // Max per-wallet for whitelisted
  // uint256 public MAX_PER_WALLET_PL = 3; // Max per-wallet for public
  bool private IS_PUBLIC = false;

  event Log(uint256 amount, uint256 gas);
  event ResultsFromCall(bool success, bytes data);

  constructor() {}

  receive() external payable {}

  fallback() external payable {}

  function validateWhiteList(bytes32[] calldata merkleProof, address sender) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender));
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  /**
  ***************************
  Public
  ***************************
   */
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function mint(address to, bytes32[] calldata merkleProof) public payable {
    require(token.totalSupply() < MAX_CAPACITY, 'No more left to mint');
    if (!IS_PUBLIC) {
      require(validateWhiteList(merkleProof, to), 'User is not whitelisted');
      require(token.balanceOf(to) < MAX_PER_WALLET_WL, 'You have minted your wallet limit');
    }
    require(msg.value >= BASE_PRICE, 'Need to send more ether');
    token.safeMint(to);
    emit Log(msg.value, gasleft());
  }

  function batchMint(
    address to,
    bytes32[] calldata merkleProof,
    uint256 batchMintAmt
  ) public payable {
    require((token.totalSupply() + batchMintAmt) <= MAX_CAPACITY, 'No more left to mint');
    require(batchMintAmt <= MAX_PER_BATCH, 'You have to minted lesser in a batch');
    if (!IS_PUBLIC) {
      require(validateWhiteList(merkleProof, to), 'User is not whitelisted');
      require((token.balanceOf(to) + batchMintAmt) <= MAX_PER_WALLET_WL, 'You have minted your wallet limit');
    }
    require(msg.value >= BASE_PRICE * batchMintAmt, 'Need to send more ether');
    for (uint256 index = 0; index < batchMintAmt; index++) {
      token.safeMint(to);
    }
    emit Log(msg.value, gasleft());
  }

  /**
  ***************************
  Only Owner
  ***************************
   */

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'No ether left to withdraw');

    (bool success, bytes memory data) = (msg.sender).call{value: balance}('');
    require(success, 'Withdrawal failed');
    emit ResultsFromCall(success, data);
  }

  /**
  ***************************
  Customization for the contract
  ***************************
   */

  function setContractAddress(address payable _address) external onlyOwner {
    contractAddress = _address;
    token = MIRL(_address);
  }

  function setBasePrice(uint256 _basePrice) public onlyOwner {
    BASE_PRICE = _basePrice;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMaxPerWalletWL(uint256 _maxPerWallet) public onlyOwner {
    MAX_PER_WALLET_WL = _maxPerWallet;
  }

  function setMaxPerBatch(uint256 _maxPerBatch) public onlyOwner {
    MAX_PER_BATCH = _maxPerBatch;
  }

  function setMaxCapacity(uint256 _maxCapacity) public onlyOwner {
    MAX_CAPACITY = _maxCapacity;
  }

  function setIsPublic(bool _isPublic) public onlyOwner {
    IS_PUBLIC = _isPublic;
  }
}
