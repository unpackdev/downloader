// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ITrinviNFT.sol";
// import "./console.sol";

contract Sale is Ownable {

  // =============================================================
  //                            EVENTS
  // =============================================================
  event BatchSet(Batch);

  // =============================================================
  //                            ERRORS
  // =============================================================
  error BatchShouldStartAfterLastBatch();
  error BatchStartMustBeInFuture();
  error BatchEndMustBeAfterStart();
  error LastBatchDoesNotEnd();
  error BatchNotFound();
  error BatchNotYetStarted();
  error BatchHasPassed();
  error InsufficientValueForMint();
  error NotRegisteredInCurrentBatch();
  error MintQtyExceedsMaxSale();
  error MintQtyExceedsMaxSalePerAccount();
  error MustEndInTheFuture();
  error BatchAlreadyHasEndDate();
  error AirdropStartMustBeInFuture();
  error AirdropNotFound();
  error NotRegisteredInAirdrop();
  error MintQtyExceedsMaxQty();
  error MintQtyExceedsMaxQtyPerAccount();
  error AirdropNotYetStarted();
  error AirdropHasPassed();


  // =============================================================
  //                            STRUCTS
  // =============================================================
  struct BatchParam {
    string name;
    uint256 start;
    uint256 end; // set end to 0 if no end
    uint price;
    uint maxSale; // Set to 0 if no max
    uint maxSalePerAccount; // Set to 0 if no max
    bool mustRegister;
  }

  struct Batch {
    uint idx;
    string name;
    uint256 start;
    uint256 end; // set end to 0 if no end
    uint price;
    uint maxSale; // Set to 0 if no max
    uint maxSalePerAccount; // Set to 0 if no max
    uint qtySold; // track the number of qty sold
    bytes32 whitelistMerkleRoot; //
    bool mustRegister;
  }

  struct BatchClaim {
    uint batchIdx;
    address claimer;
    uint qtyClaimed;
  }

  /// Airdrops does not have have to start and end in sequences like Batch do
  struct AirdropParam {
    string name;
    uint256 start;
    uint256 end; // set end to 0 if no end
    uint maxClaim;
    uint maxClaimPerAccount;
  }

  struct Airdrop {
    uint idx;
    string name;
    uint256 start;
    uint256 end; // set end to 0 if no end
    uint maxClaim;
    uint maxClaimPerAccount;
    uint qtyClaimed;
    bytes32 whitelistMerkleRoot;
  }

  struct AirdropClaim {
    uint airdropIdx;
    address claimer;
    uint qtyClaimed;
  }

  // =============================================================
  //                            STORAGE
  // =============================================================
  address public _nftAddress;
  uint public _lastBatchIdx;
  uint public _lastAirdropIdx;

  // =============================================================
  //                            MAPPINGS
  // =============================================================
  // id => Batch
  mapping (uint => Batch) public _batches;
  mapping (uint => Airdrop) public _airdrops;
  mapping (uint => mapping(address => BatchClaim)) public _batchClaims;
  mapping (uint => mapping(address => AirdropClaim)) public _airdropClaims;


  // =============================================================
  //                            MODIFIERS
  // =============================================================
  modifier mustSendSufficientValue(uint qty, uint batchIdx) {
    Batch memory currBatch = _batches[batchIdx];
    if (msg.value < (currBatch.price * qty)) {
      revert InsufficientValueForMint();
    }
    _;
  }

  modifier followsBatchRules(uint batchIdx, uint mintQty, bytes32[] calldata merkleProof) {
    Batch memory currBatch = _batches[batchIdx];
    if (currBatch.idx == 0) {
      revert BatchNotFound();
    }
    BatchClaim memory batchClaim = _batchClaims[batchIdx][msg.sender];
    if (!hasStarted(currBatch.start)) {
      revert BatchNotYetStarted();
    }
    if (hasPassed(currBatch.end)) {
      revert BatchHasPassed();
    }
    if (currBatch.mustRegister && !_isInWhitelist(msg.sender, currBatch.whitelistMerkleRoot, merkleProof)) {
      revert NotRegisteredInCurrentBatch();
    }
    if (!doesNotExceedMaxQty(mintQty, currBatch.maxSale, currBatch.qtySold)) {
      revert MintQtyExceedsMaxSale();
    }
    if (!isAllowedToMintQty(mintQty, currBatch.maxSalePerAccount, batchClaim.qtyClaimed)) {
      revert MintQtyExceedsMaxSalePerAccount();
    }
    _;
  }

  function hasStarted(uint start) internal view returns (bool) {
    if (start > 0 && block.timestamp < start) {
      return false;
    }
    return true;
  }

  function hasPassed(uint end) internal view returns (bool) {
    if (end > 0 && block.timestamp > end) {
      return true;
    }
    return false;
  }

  function _isInWhitelist(address msgSender, bytes32 whitelistMerkleRoot, bytes32[] calldata merkleProof_) internal pure returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(msgSender));
    bool isValidProof = MerkleProof.verify(merkleProof_, whitelistMerkleRoot, leaf);
    return isValidProof;
  }

  function isAllowedToMintQty(uint qty, uint maxQtyPerAccount, uint qtyMinted) internal pure returns (bool) {
    if (maxQtyPerAccount == 0) {
      return true;
    }
    uint allowedMintQty = maxQtyPerAccount - qtyMinted;
    if (qty > allowedMintQty) {
      return false;
    }
    return true;
  }

  function doesNotExceedMaxQty(uint qty, uint maxQty, uint qtyMinted) internal pure returns (bool) {
    if (maxQty == 0) {
      return true;
    }
    uint qtyRemaining = maxQty - qtyMinted;
    if (qty > qtyRemaining) {
      return false;
    }
    return true;
  }

  modifier followsAirdropRules(uint airdropIdx, uint mintQty, bytes32[] calldata merkleProof) {
    Airdrop memory airdrop = _airdrops[airdropIdx];
    AirdropClaim memory airdropClaim = _airdropClaims[airdropIdx][msg.sender];
    if (!hasStarted(airdrop.start)) {
      revert AirdropNotYetStarted();
    }
    if (hasPassed(airdrop.end)) {
      revert AirdropHasPassed();
    }
    if (!_isInWhitelist(msg.sender, airdrop.whitelistMerkleRoot, merkleProof)) {
      revert NotRegisteredInAirdrop();
    }
    if (!doesNotExceedMaxQty(mintQty, airdrop.maxClaim, airdrop.qtyClaimed)) {
      revert MintQtyExceedsMaxQty();
    }
    if (!isAllowedToMintQty(mintQty, airdrop.maxClaimPerAccount, airdropClaim.qtyClaimed)) {
      revert MintQtyExceedsMaxQtyPerAccount();
    }
    _;
  }

  constructor(address nftAddress) {
    _nftAddress = nftAddress;
  }

  function mintTo(address to, uint qty, uint batchIdx, bytes32[] calldata merkleProof) external payable
    mustSendSufficientValue(qty, batchIdx)
    followsBatchRules(batchIdx, qty, merkleProof)
  {
    ITrinviNFT(_nftAddress).mintTo(to, qty);
    recordBatchActivity(msg.sender, batchIdx, qty);
  }

  function claimAirdrop(address to, uint qty, uint airdropIdx, bytes32[] calldata merkleProof)
    external
    followsAirdropRules(airdropIdx, qty, merkleProof)
  {
    ITrinviNFT(_nftAddress).mintTo(to, qty);
    recordAirdropActivity(msg.sender, airdropIdx, qty);
  }

  function batches(uint index) public view returns (Batch memory) {
    return _batches[index];
  }

  function currentBatch() public view returns (Batch memory batch_) {
    for (uint i = _lastBatchIdx; i > 0; i--) {
      Batch memory batch = _batches[i];
      if (block.timestamp >= batch.start && batch.end == 0) {
        return batch;
      }
      if (block.timestamp >= batch.start && block.timestamp < batch.end) {
        return batch;
      }
    }
  }

  function addBatches(BatchParam[] calldata batches_) external onlyOwner {
    for (uint i = 0; i < batches_.length; i++) {
      addBatch(batches_[i]);
    }
  }

  function addBatch(BatchParam calldata batchParam) internal {
    validateBatchParam(batchParam);

    _lastBatchIdx++;

    Batch memory batch = Batch({
      idx: _lastBatchIdx,
      name: batchParam.name,
      start: batchParam.start,
      end: batchParam.end, // set end to 0 if no end
      price: batchParam.price,
      maxSale: batchParam.maxSale, // Set to 0 if no max
      maxSalePerAccount: batchParam.maxSalePerAccount, // Set to 0 if no max
      mustRegister: batchParam.mustRegister,
      whitelistMerkleRoot: bytes32(0),
      qtySold: 0 // track the number of qty sold
    });
    _batches[_lastBatchIdx] = batch;
  }

  function setLastBatchEnd(uint batchEnd_) external onlyOwner {
    Batch memory batch = _batches[_lastBatchIdx];
    if (batch.end > 0) {
      revert BatchAlreadyHasEndDate();
    }
    if (batchEnd_ < batch.start) {
      revert BatchEndMustBeAfterStart();
    }
    batch.end = batchEnd_;
    _batches[_lastBatchIdx] = batch;
  }

  function validateBatchParam(BatchParam memory batch) internal view {
    if (batch.start < block.timestamp) {
      revert BatchStartMustBeInFuture();
    }
    if (batch.end > 0 && batch.start > batch.end) {
      revert BatchEndMustBeAfterStart();
    }
    if (_lastBatchIdx > 0) {
      Batch memory lastBatch = _batches[_lastBatchIdx];
      if (lastBatch.end == 0) {
        revert LastBatchDoesNotEnd();
      }
      if (batch.start <= lastBatch.end) {
        revert BatchShouldStartAfterLastBatch();
      }
    }
  }

  function registerAddressesToBatch(bytes32 whitelistMerkleRoot, uint batchIdx) external onlyOwner {
    Batch memory batch = _batches[batchIdx];
    if (batch.idx == 0) {
      revert BatchNotFound();
    }
    batch.whitelistMerkleRoot = whitelistMerkleRoot;
    _batches[batchIdx] = batch;
  }

  function isInBatchWhitelist(address address_, uint batchIdx, bytes32[] calldata merkleProof) external view returns (bool) {
    Batch memory batch = _batches[batchIdx];
    if (batch.idx == 0) {
      revert BatchNotFound();
    }
    return _isInWhitelist(address_, batch.whitelistMerkleRoot, merkleProof);
  }

  function isInAirdropWhitelist(address address_, uint airdropIdx, bytes32[] calldata merkleProof) external view returns (bool) {
    Airdrop memory airdrop = _airdrops[airdropIdx];
    if (airdrop.idx == 0) {
      revert AirdropNotFound();
    }
    return _isInWhitelist(address_, airdrop.whitelistMerkleRoot, merkleProof);
  }

  function recordBatchActivity(address msgSender, uint batchIdx, uint mintQty) internal returns (BatchClaim memory claim) {
    claim = _batchClaims[batchIdx][msgSender];
    if (claim.claimer == address(0)) {
      claim.batchIdx = batchIdx;
      claim.claimer = msgSender;
    }
    claim.qtyClaimed = claim.qtyClaimed + mintQty;
    _batchClaims[batchIdx][msgSender] = claim;

    Batch memory batch = _batches[batchIdx];
    batch.qtySold += mintQty;
    _batches[batchIdx] = batch;

    return claim;
  }
  
  function recordAirdropActivity(address msgSender, uint airdropIdx, uint mintQty) internal returns (AirdropClaim memory claim) {
    claim = _airdropClaims[airdropIdx][msgSender];
    if (claim.claimer == address(0)) {
      claim.airdropIdx = airdropIdx;
      claim.claimer = msgSender;
    }
    claim.qtyClaimed += mintQty;
    _airdropClaims[airdropIdx][msgSender] = claim;

    Airdrop memory airdrop = _airdrops[airdropIdx];
    airdrop.qtyClaimed += mintQty;
    _airdrops[airdropIdx] = airdrop;

    return claim;
  }

  function addAirdrops(AirdropParam[] calldata airdrops_) external onlyOwner {
    for (uint i = 0; i < airdrops_.length; i++) {
      addAirdrop(airdrops_[i]);
    }
  }

  function addAirdrop(AirdropParam calldata airdropParam) internal {
    validateAirdropParam(airdropParam);

    _lastAirdropIdx++;

    Airdrop memory airdrop = Airdrop({
      idx: _lastAirdropIdx,
      name: airdropParam.name,
      start: airdropParam.start,
      end: airdropParam.end, // set end to 0 if no end
      maxClaim: airdropParam.maxClaim, // Set to 0 if no max
      maxClaimPerAccount: airdropParam.maxClaimPerAccount, // Set to 0 if no max
      whitelistMerkleRoot: bytes32(0),
      qtyClaimed: 0 // track the number of qty sold
    });
    _airdrops[_lastAirdropIdx] = airdrop;
  }

  function setAirdropEnd(uint airdropIdx, uint end) external onlyOwner {
    Airdrop memory airdrop = _airdrops[airdropIdx];
    if (airdrop.idx == 0) {
      revert AirdropNotFound();
    }
    if (block.timestamp > end) {
      revert MustEndInTheFuture();
    }
    airdrop.end = end;
    _airdrops[airdropIdx] = airdrop;
  }

  function validateAirdropParam(AirdropParam memory airdrop) internal view {
    if (airdrop.start < block.timestamp) {
      revert AirdropStartMustBeInFuture();
    }
  }

  function registerAddressesToAirdrop(bytes32 whitelistMerkleRoot, uint airdropIdx) external onlyOwner {
    Airdrop memory airdrop = _airdrops[airdropIdx];
    if (airdrop.idx == 0) {
      revert AirdropNotFound();
    }
    airdrop.whitelistMerkleRoot = whitelistMerkleRoot;
    _airdrops[airdropIdx] = airdrop;
  }

  /**
    * Withdraw all contract's balance to specified address
    */
  function withdraw(address to) public onlyOwner {
    address payable receiver = payable(to);
    receiver.transfer(address(this).balance);
  }
}