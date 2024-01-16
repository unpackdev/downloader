//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

interface IMerkleTreeWhitelist {
    function isValidMerkleProof(bytes32[] calldata _merkleProof, address _minter, uint96 _amount) external view returns (bool);
}

interface ITokenContract {
  function mint(address _recipient, uint256 _tokenId, uint96 _quantity) external;
}

contract ClonableMerkleAirdropMinimalERC1155 is OwnableUpgradeable {
  
  IMerkleTreeWhitelist public merkleProofWhitelist;
  ITokenContract public tokenContract;
  address public payoutAddress;
  uint256 public tokenId;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public purchasableAllocation;
  uint256 public purchasePrice;
  uint256 public purchasedCount;
  uint256 public claimedCount;
  uint256 public whitelistVersion;
  mapping(uint256 => mapping(address => bool)) public whitelistVersionToClaimantToClaimStatus;

  function initialize(
    address _merkleProofWhitelist,
    address _tokenContract,
    uint256 _tokenId,
    uint256 _startTime,
    uint256 _endTime,
    address _admin,
    address _payoutAddress
  ) external {
    require(address(merkleProofWhitelist) == address(0), "ALREADY_INITIALIZED");
    merkleProofWhitelist = IMerkleTreeWhitelist(_merkleProofWhitelist);
    tokenContract = ITokenContract(_tokenContract);
    tokenId = _tokenId;
    startTime = _startTime;
    endTime = _endTime;
    whitelistVersion = 1;
    payoutAddress = _payoutAddress;
    _transferOwnership(_admin);
  }

  function mintMerkleWhitelist(
    bytes32[] calldata _merkleProof,
    uint16 _quantity,
    address _claimant,
    address _recipient
  ) external {
    require(block.timestamp >= startTime, "CLAIMS_NOT_STARTED");
    if(endTime > 0) {
      require(block.timestamp <= endTime, "CLAIMS_HAVE_ENDED");
    }
    if(_claimant == _recipient) {
      require(!whitelistVersionToClaimantToClaimStatus[whitelistVersion][_claimant], 'MERKLE_CLAIM_ALREADY_MADE');
      require(merkleProofWhitelist.isValidMerkleProof(_merkleProof, _claimant, _quantity), 'INVALID_MERKLE_PROOF');
      whitelistVersionToClaimantToClaimStatus[whitelistVersion][_claimant] = true;
    } else {
      require(!whitelistVersionToClaimantToClaimStatus[whitelistVersion][msg.sender], 'MERKLE_CLAIM_ALREADY_MADE');
      require(merkleProofWhitelist.isValidMerkleProof(_merkleProof, msg.sender, _quantity), 'INVALID_MERKLE_PROOF');
      whitelistVersionToClaimantToClaimStatus[whitelistVersion][msg.sender] = true;
    }
    claimedCount += _quantity;
    tokenContract.mint(_recipient, tokenId, _quantity);
  }

  function mintPurchase(
    uint16 _quantity,
    address _recipient
  ) external payable {
    require(block.timestamp >= startTime, "SALE_NOT_STARTED");
    if(endTime > 0) {
      require(block.timestamp <= endTime, "SALE_HAS_ENDED");
    }
    require(msg.value == (_quantity * purchasePrice), "INCORRECT_ETH_AMOUNT");
    purchasedCount += _quantity;
    require(purchasedCount <= purchasableAllocation, "INSUFFICIENT_REMAINING_SUPPLY");

    tokenContract.mint(_recipient, tokenId, _quantity);
  }

  function setEndTime(uint256 _endTime) external onlyOwner {
    endTime = _endTime;
  }

  function setStartTime(uint256 _startTime) external onlyOwner {
    startTime = _startTime;
  }

  function setPayoutAddress(address _payoutAddress) external onlyOwner {
    payoutAddress = _payoutAddress;
  }

  function setSaleConfig(uint256 _purchasableAllocation, uint256 _purchasePrice) external onlyOwner {
    require((address(merkleProofWhitelist) == address(0)) || (owner() == _msgSender()), "ALREADY_INITIALISED_NOT_OWNER");
    purchasableAllocation = _purchasableAllocation;
    purchasePrice = _purchasePrice;
  }

  function payout() external {
    (bool payoutDeliverySuccess, ) = payoutAddress.call{value: address(this).balance}("");
    require(payoutDeliverySuccess, "PAYOUT_FAILED");
  }

}