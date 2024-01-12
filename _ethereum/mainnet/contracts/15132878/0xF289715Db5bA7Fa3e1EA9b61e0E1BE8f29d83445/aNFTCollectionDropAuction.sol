// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

/// @title: aNFT Collection
/// @author: circle.xyz

import "./aNFTCollectionInterface.sol";
import "./aNFTLogic.sol";
import "./EnumerableSet.sol";

contract aNFTCollectionDropAuction is aNFTLogic {

  constructor() aNFTLogic() {}

  uint256 public startTime;
  uint256 public pauseTime;
  uint256 public pauseDuration;
  uint256 public startPrice;
  uint256 public minPrice;
  uint256 constant auctionStepsPeriod = 20 minutes;

  struct MintLog {
    uint256 price;
    uint256 amount;
  }

  mapping (address => MintLog[]) private alRefundDetails;
  bool allowlistRefunded;

  using EnumerableSet for EnumerableSet.AddressSet;
  EnumerableSet.AddressSet alAddresses;

  uint256 public alRefundPool;
  bool public alRefundStatus;
  
  /**
  @notice initialize dutch auction collection contract
  @param _startPrice nft start dutch auction price in wei
  @param _collectionConfig includes: name, symbol, baseURI, supply
  @param _maxMint nft public mint limit per wallet address
  @param _allowlistMerkleRoot merkle tree root for allowlist
  @param _claimlistMerkleRoot merkle tree root for claim list
  @param _royaltiesConfig royalty info for nft marketplaces ERC2981
  @param _feeConfig withdraw fee percentage and recipient 
  @param _mintState public mint state
  @param _mintListSate allowlist and claim list mint state
  */
  function initializeDutchAuction(
      uint256 _startPrice,
      aNFTCollectionInterface.AccessConfig memory _collectionConfig, 
      uint256 _maxMint,
      bytes32 _allowlistMerkleRoot,
      bytes32 _claimlistMerkleRoot,
      aNFTCollectionInterface.RoyaltiesConfig memory _royaltiesConfig,
      aNFTCollectionInterface.FeeConfig memory _feeConfig,
      bool _mintState,
      bool _mintListSate,
      address _owner
    ) external {
      _setPrice(_startPrice);
      if(_mintState){
        startTime = block.timestamp;
      }

      initialize(
            _collectionConfig, 
            _maxMint,
            _allowlistMerkleRoot,
            _claimlistMerkleRoot,
            _royaltiesConfig,
            _feeConfig,
            _mintState,
            _mintListSate,
            _owner
          );
  }


  //returns nft price depending on current timestamp
  function getPrice() public override view returns (uint256) {

    if(startTime == 0){
      return startPrice;
    }

    uint256 _pauseDuration = pauseDuration;
    if(pauseTime > 0){
      _pauseDuration += block.timestamp - pauseTime;
    }
    uint256 auctionSteps = (block.timestamp - startTime - _pauseDuration) / auctionStepsPeriod;

    if(startPrice <= 0.1 ether){
      if(0.01 ether * auctionSteps >= startPrice)return 0.01 ether;
      return startPrice - 0.01 ether * auctionSteps;
    }
    
    if(0.5 ether * auctionSteps < startPrice){
      return startPrice - 0.5 ether * auctionSteps;
    }

    if(0.5 ether * auctionSteps == startPrice){
      return 0.25 ether;
    }

    uint256 stepsToSkip = 0;
    if(startPrice >= 0.5 ether){
      stepsToSkip = startPrice / 0.5 ether;
    }

    if(auctionSteps - stepsToSkip >= 10)return 0.01 ether;

    return 0.11 ether - (0.01 ether * (auctionSteps - stepsToSkip));
  }

  //change state of public mint
  function setMintState(bool _mintState) override external onlyOwner {
    require(_mintState != mintState, 'state is already set');
    mintState = _mintState;

    if(_mintState == true){

      if(startTime == 0){
        startTime = block.timestamp;
        return;
      }
      
      pauseDuration += block.timestamp - pauseTime;
      pauseTime = 0;

    }else{
      pauseTime = block.timestamp;
    }

  }

  //status of allowlist refund
  function setALRefundStatus(bool _alRefundStatus) external onlyOwner {
    alRefundStatus = _alRefundStatus;
  }

  //update nft public mint price
  function setPrice(uint256 _startPrice) external onlyOwner {
    require(mintState == false, 'sale is active');
    _setPrice(_startPrice);
    startTime = 0;
    pauseDuration = 0;
    pauseTime = 0;
  }

  function _setPrice(uint256 _startPrice) internal {
    require(_startPrice > 0.01 ether, 'price must be higher than 0.01 eth');
    require(_startPrice <= 10 ether, 'price must be lower or equal to 10 eth');


    if(_startPrice >= 0.5 ether){
      require( (_startPrice / 0.5 ether) * 0.5 ether == _startPrice, 'should be mod 0.5');
    }else if(_startPrice > 0.1 ether){
      require(_startPrice == 0.25 ether, 'new price should be 0.25');
    }else{
      require( (_startPrice / 0.01 ether) * 0.01 ether == _startPrice, 'should be mod 0.01');
    }

    startPrice = _startPrice;
  }

  //allowlist mint
  function mintAllowlist(bytes32[] calldata _merkleProof, uint256 mintAllocation, uint256 mintAmount) external override payable {
    require(allowlistRefunded == false, 'allowlist refund permanently disabled');
    _listMint(aNFTCollectionInterface.DropType.allowlist, allowlistMerkleRoot, _merkleProof, mintAllocation, mintAmount);
    _txRefund(startPrice * mintAmount);

    _addAlRefund(msg.sender, startPrice, mintAmount);
    alRefundPool += startPrice * mintAmount;
  }

  function _addAlRefund(address _address, uint256 _price, uint256 _amount) internal {
    uint256 refundALcount = alRefundCount(msg.sender);
    
    for(uint256 c = 0; c < refundALcount; c++){
      if(alRefundDetails[_address][c].price == _price){
        alRefundDetails[_address][c].amount += _amount;
        return;
      }
    }

    alRefundDetails[_address].push(MintLog(_price, _amount));
    alAddresses.add(_address);
  }

  function _catchMinPrice(uint256 _price) internal override {
     if(minPrice == 0 || minPrice > _price){
        minPrice = _price;
     }
  }

  function _afterTokenTransfers(
      address from,
      address,
      uint256,
      uint256
  ) internal override {
    if(from == address(0) && _totalMinted() == maxSupply()){
      alRefundStatus = true;
    }
  }

  //number of unclaimed allowlist mint transactions at unique price points
  function alRefundCount(address userAddress) public view returns(uint256){
    return (allowlistRefunded == false)?alRefundDetails[userAddress].length:0;
  }

  //total balance subtracting allowlist refund pool
  function getBalance() public override view returns (uint256){
    return address(this).balance - alRefundPool;
  }

  //refund allowlist mint users the difference between nft start auction price and lowest auction price reached
  function claimAllowlistRefund() external nonReentrant {
    require(alRefundStatus, 'not yet enabled');
    require(allowlistRefunded == false, 'already refunded');
    
    uint256 refundALcount = alRefundCount(msg.sender);
    require(refundALcount > 0, 'nothing to refund');
    
    for(uint256 c = refundALcount; c > 0; c--){
        MintLog memory mintLog = alRefundDetails[msg.sender][c-1];
        if(minPrice > 0 && mintLog.price > minPrice){
          payable(msg.sender).transfer((mintLog.price - minPrice)*mintLog.amount);
        }
        
        alRefundPool -= mintLog.price*mintLog.amount;
        alRefundDetails[msg.sender].pop();
    }

    alAddresses.remove(msg.sender);
  }

  function alRefundEstimate(address _address) external view returns(uint256) {
    if(!alRefundStatus || allowlistRefunded || minPrice == 0){
      return 0;
    }

    uint256 refundALcount = alRefundCount(_address);
    if(refundALcount == 0){
      return 0;
    }
    
    uint256 total = 0;
    MintLog memory mintLog;
    for(uint256 c = refundALcount; c > 0; c--){
        mintLog = alRefundDetails[_address][c-1];
        if(mintLog.price > minPrice){
          total += (mintLog.price - minPrice)*mintLog.amount;
        }
    }
    return total;
  }

  //when executed it will permanently disable allowlist mint and refunds
  function withdrawRefundPool() external onlyOwner {
    require(allowlistRefunded == false, 'already refunded');
    allowlistRefunded = true;
    delete alAddresses;
    payable(msg.sender).transfer(alRefundPool);
    alRefundPool = 0;
  }

}