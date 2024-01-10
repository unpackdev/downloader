// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./MIRL.sol";

contract ByBitMinter is Ownable {
  MIRL private token;
  address private contractAddress;
  bytes32 private merkleRoot = 0x2118360192c133de1b0786803bdcf3b3399d8693158c02739e4309527f2584d3;
  uint256 public BASE_PRICE = 0;
  uint256 public MAX_PER_WALLET = 1111;
  uint256 public MAX_CAPACITY = 1111;

  event Log(uint256 amount, uint256 gas);
  event ResultsFromCall(bool success, bytes data);

  constructor() {
    // contractAddress = _contractAddress;
    // token = MIRL(_contractAddress);
  }

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

  function mint(address to, bytes32[] calldata merkleProof) public payable {
    require(token.totalSupply() < MAX_CAPACITY, 'No more left to mint');
    require(validateWhiteList(merkleProof, to), 'User is not whitelisted');
    require(token.balanceOf(to) < MAX_PER_WALLET, 'You have minted your wallet limit');
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
    require(validateWhiteList(merkleProof, to), 'User is not whitelisted');
    require((token.balanceOf(to) + batchMintAmt) <= MAX_PER_WALLET, 'You have minted your wallet limit');
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

  function getMerkleRoot() public view onlyOwner returns (bytes32) {
    return merkleRoot;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    MAX_PER_WALLET = _maxPerWallet;
  }

  function setMaxCapacity(uint256 _maxCapacity) public onlyOwner {
    MAX_CAPACITY = _maxCapacity;
  }
}
