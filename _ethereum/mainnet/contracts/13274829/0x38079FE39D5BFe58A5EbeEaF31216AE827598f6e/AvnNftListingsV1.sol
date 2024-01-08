// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Owned.sol";
import "./IAvnNftListingsV1.sol";
import "./IAvnNftRoyaltyStorage.sol";

contract AvnNftListingsV1 is IAvnNftListingsV1, Owned {

  IAvnNftRoyaltyStorage immutable private avnNftRoyaltyStorage;

  string constant private AUCTION_INSTRUCTION = "AVN_START_AUCTION";
  string constant private BATCH_INSTRUCTION = "AVN_START_BATCH";
  string constant private SALE_INSTRUCTION = "AVN_START_SALE";
  uint32 constant private ONE_MILLION = 1000000;
  uint64 constant public SUPPLY_LIMIT = type(uint64).max;
  bool private payingOut;

  mapping (address => bool) public authority;
  mapping (uint256 => Listing) private listing;
  mapping (uint256 => Bid) private highBid;
  mapping (bytes32 => bool) private proofUsed;

  constructor(IAvnNftRoyaltyStorage _avnNftRoyaltyStorage)
  {
    avnNftRoyaltyStorage = _avnNftRoyaltyStorage;
  }

  modifier isNotListed(uint256 _id) {
    require(listing[_id].state == State.Unlisted, "Listing already exists");
    _;
  }

  modifier isListedForAuction(uint256 _nftId) {
    require(listing[_nftId].state == State.Auction, "Auction not listed");
    _;
  }

  modifier isListedForBatchSale(uint256 _batchId) {
    require(listing[_batchId].state == State.Batch, "Batch not listed");
    _;
  }

  modifier isListedForSale(uint256 _nftId) {
    require(listing[_nftId].state == State.Sale, "Sale not listed");
    _;
  }

  modifier hasAvnPublicKey(bytes32 _avnPublicKey) {
    require(_avnPublicKey != 0, "Missing AVN public key");
    _;
  }

  modifier onlySeller(address _seller) {
    require(_seller == msg.sender, "Only seller");
    _;
  }

  modifier onlySellerOrAuthorityOrOwner(uint256 _nftId) {
    require(msg.sender == listing[_nftId].seller || authority[msg.sender] || msg.sender == owner, "Not permitted");
    _;
  }

  function setAuthority(address _authority, bool _isAuthorised)
    external
    override
    onlyOwner
  {
    require(_authority != address(0), "Cannot be zero address");
    authority[_authority] = _isAuthorised;
  }

  function startAuction(uint256 _nftId, uint256 _reservePrice, uint256 _endTime, uint64 _avnOpId,
      IAvnNftRoyaltyStorage.Royalty[] calldata _royalties, bytes calldata _proof)
    external
    override
    isNotListed(_nftId)
  {
    require(_nftId != 0, "Missing NFT ID");
    checkProof(keccak256(abi.encode(AUCTION_INSTRUCTION, address(this), _nftId, msg.sender, _endTime, _avnOpId, _royalties)),
        _proof);
    avnNftRoyaltyStorage.setRoyalties(_nftId, _royalties);
    emit LogStartAuction(_nftId, msg.sender, _reservePrice, _endTime);

    if (block.timestamp > _endTime) {
      emit LogAuctionCancelled(_nftId);
      emit AvnCancelNftListing(_nftId, _avnOpId);
    } else {
      listing[_nftId].state = State.Auction;
      listing[_nftId].seller = msg.sender;
      listing[_nftId].avnOpId = _avnOpId;
      listing[_nftId].endTime = _endTime;
      highBid[_nftId].amount = (_reservePrice > 0) ? _reservePrice - 1 : 0;
    }
  }

  function bid(uint256 _nftId, bytes32 _avnPublicKey)
    external
    override
    payable
    hasAvnPublicKey(_avnPublicKey)
    isListedForAuction(_nftId)
  {
    require(block.timestamp <= listing[_nftId].endTime, "Bidding has ended");
    require(msg.value > highBid[_nftId].amount, "Bid too low");

    refundAnyExistingBid(_nftId);
    highBid[_nftId].bidder = msg.sender;
    highBid[_nftId].avnPublicKey = _avnPublicKey;
    highBid[_nftId].amount = msg.value;
    emit LogBid(_nftId, highBid[_nftId].bidder, highBid[_nftId].avnPublicKey, highBid[_nftId].amount);
  }

  function endAuction(uint256 _nftId)
    external
    override
    isListedForAuction(_nftId)
    onlySeller(listing[_nftId].seller)
  {
    require(block.timestamp > listing[_nftId].endTime, "Cannot end auction yet");

    if (highBid[_nftId].bidder == address(0)) {
      emit LogAuctionCancelled(_nftId);
      emit AvnCancelNftListing(_nftId, listing[_nftId].avnOpId);
    } else {
      distributeFunds(avnNftRoyaltyStorage.getRoyalties(_nftId), highBid[_nftId].amount, msg.sender);
      emit LogAuctionComplete(_nftId, highBid[_nftId].avnPublicKey, highBid[_nftId].bidder, highBid[_nftId].amount);
      emit AvnTransferTo(_nftId, highBid[_nftId].avnPublicKey, listing[_nftId].avnOpId);
      delete highBid[_nftId];
    }

    delete listing[_nftId];
  }

  function cancelAuction(uint256 _nftId)
    external
    override
    isListedForAuction(_nftId)
    onlySellerOrAuthorityOrOwner(_nftId)
  {
    refundAnyExistingBid(_nftId);
    emit LogAuctionCancelled(_nftId);
    emit AvnCancelNftListing(_nftId, listing[_nftId].avnOpId);
    delete listing[_nftId];
  }

  function startBatchSale(uint256 _batchId, uint256 _price, uint256 _endTime, uint64 _supply,
      IAvnNftRoyaltyStorage.Royalty[] calldata _royalties, bytes calldata _proof)
    external
    override
    isNotListed(_batchId)
  {
    require(_batchId != 0, "Missing batch ID");
    require(_price != 0, "Missing price");
    require(_supply != 0, "Missing supply");
    require(_batchId & SUPPLY_LIMIT == 0, "Invalid batch ID");

    checkProof(keccak256(abi.encode(BATCH_INSTRUCTION, address(this), _batchId, msg.sender, _endTime, _royalties)), _proof);
    avnNftRoyaltyStorage.setRoyalties(_batchId, _royalties);
    emit LogStartBatchSale(_batchId, msg.sender, _price, _supply, _endTime);

    if (block.timestamp > _endTime) {
      emit LogBatchSaleCancelled(_batchId);
      emit AvnCancelBatchListing(_batchId);
    } else {
      listing[_batchId].state = State.Batch;
      listing[_batchId].seller = msg.sender;
      listing[_batchId].price = _price;
      listing[_batchId].endTime = _endTime;
      listing[_batchId].supply = _supply;
    }
  }

  function buyFromBatch(uint256 _batchId, bytes32 _avnPublicKey)
    external
    override
    payable
    hasAvnPublicKey(_avnPublicKey)
    isListedForBatchSale(_batchId)
  {
    require(block.timestamp <= listing[_batchId].endTime, "Sales have ended");
    require(msg.value == listing[_batchId].price, "Incorrect price");
    require(listing[_batchId].supply - listing[_batchId].saleIndex > 0, "Sold out");
    listing[_batchId].saleIndex++;
    uint256 nftId = _batchId + listing[_batchId].saleIndex;
    avnNftRoyaltyStorage.setRoyaltyId(_batchId, nftId);
    listing[_batchId].saleFunds += msg.value;
    emit LogSold(nftId, _avnPublicKey, msg.sender);
    emit AvnMintTo(nftId, _avnPublicKey);
  }

  function endBatchSale(uint256 _batchId)
    external
    override
    isListedForBatchSale(_batchId)
    onlySeller(listing[_batchId].seller)
  {
    require(block.timestamp > listing[_batchId].endTime, "Cannot end sales yet");

    if (listing[_batchId].saleIndex == 0) {
      emit LogBatchSaleCancelled(_batchId);
      emit AvnCancelBatchListing(_batchId);
    } else {
      uint256 totalSalesAmount = listing[_batchId].saleFunds;
      listing[_batchId].saleFunds = 0;
      distributeFunds(avnNftRoyaltyStorage.getRoyalties(_batchId), totalSalesAmount, msg.sender);
      emit LogBatchSaleComplete(_batchId, listing[_batchId].saleIndex);
    }

    delete listing[_batchId];
  }

  function startNftSale(uint256 _nftId, uint256 _price, uint64 _avnOpId, bytes calldata _proof)
    external
    override
    isNotListed(_nftId)
  {
    require(_nftId != 0, "Missing NFT ID");
    require(_price != 0, "Missing price");
    checkProof(keccak256(abi.encode(SALE_INSTRUCTION, address(this), _nftId, msg.sender, _avnOpId)), _proof);
    listing[_nftId].state = State.Sale;
    listing[_nftId].seller = msg.sender;
    listing[_nftId].avnOpId = _avnOpId;
    listing[_nftId].price = _price;
    emit LogStartNftSale(_nftId, msg.sender, _price);
  }

  function buyNft(uint256 _nftId, bytes32 _avnPublicKey)
    external
    override
    payable
    hasAvnPublicKey(_avnPublicKey)
    isListedForSale(_nftId)
  {
    require(msg.value == listing[_nftId].price, "Incorrect price");
    distributeFunds(avnNftRoyaltyStorage.getRoyalties(_nftId), msg.value, listing[_nftId].seller);
    emit LogSold(_nftId, _avnPublicKey, msg.sender);
    emit AvnTransferTo(_nftId, _avnPublicKey, listing[_nftId].avnOpId);
    delete listing[_nftId];
  }

  function cancelNftSale(uint256 _nftId)
    external
    override
    isListedForSale(_nftId)
    onlySellerOrAuthorityOrOwner(_nftId)
  {
    emit LogNftSaleCancelled(_nftId);
    emit AvnCancelNftListing(_nftId, listing[_nftId].avnOpId);
    delete listing[_nftId];
  }

  function sendFunds(address _recipient, uint256 _amount)
    private
    returns (bool success_)
  {
    (success_, ) = _recipient.call{value: _amount}("");
  }

  function checkProof(bytes32 _msgHash, bytes memory _proof)
    private
  {
    require(!proofUsed[_msgHash], "Proof already used");
    proofUsed[_msgHash] = true;
    address signer = recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _msgHash)), _proof);
    require(authority[signer], "Invalid proof");
  }

  function recover(bytes32 hash, bytes memory signature)
    private
    pure
    returns (address)
  {
    if (signature.length != 65) return address(0);

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);
    if (v < 27) v += 27;
    if (v != 27 && v != 28) return address(0);

    return ecrecover(hash, v, r, s);
  }

  function refundAnyExistingBid(uint256 _nftId)
    private
  {
    if (highBid[_nftId].bidder == address(0)) return;

    address bidder = highBid[_nftId].bidder;
    uint256 amount = highBid[_nftId].amount;
    delete highBid[_nftId];
    sendFunds(bidder, amount);
  }

  function distributeFunds(IAvnNftRoyaltyStorage.Royalty[] memory _royalties, uint256 _amount, address _seller)
    private
  {
    assert(!payingOut);
    payingOut = true;
    uint256 remaining = _amount;

    if (_royalties.length > 0) {
      uint256 royaltyPayment;
      for (uint256 i = 0; i < _royalties.length; i++) {
        royaltyPayment = _amount * _royalties[i].partsPerMil / ONE_MILLION;
        remaining -= royaltyPayment;
        sendFunds(_royalties[i].recipient, royaltyPayment);
      }
    }

    sendFunds(_seller, remaining);
    payingOut = false;
  }
}