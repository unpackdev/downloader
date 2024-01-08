// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./VRFConsumerBase.sol";
import "./BattleRoyale.sol";
import "./AddressArray.sol";
import "./CustomAccessControl.sol";

contract BattleRoyaleArena is CustomAccessControl, VRFConsumerBase {
  using AddressArray for AddressArray.Addresses;

  // Chainlink properties
  bytes32 internal keyHash;
  uint256 public fee;
  // Address of primary wallet
  address payable public walletAddress;
  // temp mapping for battles in random elimination mechanic
  mapping(bytes32 => address payable) requestToBattle;

  // Look into elimination logic and how to maintain state of all NFTs in and out of play
  AddressArray.Addresses battleQueue;

  constructor(
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint256 _fee
  )
  public VRFConsumerBase(_vrfCoordinator, _linkToken)
  {
    keyHash = _keyHash;
    fee = _fee; // Set to Chainlink fee for network, Rinkeby and Kovan is 0.1 LINK and MAINNET is 2 LINK

    walletAddress = payable(owner());
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }
  /**
   * Fallback function to receive ETH
   */
  receive() external payable {}
  /*
   * Method to withdraw ETH
   */
  function withdraw(uint256 amount) external onlyAdmin {
    uint256 balance = address(this).balance;
    require(amount <= balance);

    if (walletAddress != address(0)) {
      payable(walletAddress).transfer(amount);
    } else {
      msg.sender.transfer(amount);
    }
  }
  /*
   * Get Current ETH Balance from contract
   */
  function getCurrentBalance() external onlySupport view returns (uint256) {
    uint256 balance = address(this).balance;
    return balance;
  }
  /*
   * Method to withdraw LINK
   */
  function withdrawLink(uint256 amount) external onlyAdmin returns (bool) {
    uint256 balance = LINK.balanceOf(address(this));
    require(amount <= balance);

    if (walletAddress != address(0)) {
      return LINK.transfer(address(walletAddress), amount);
    } else {
      return LINK.transfer(msg.sender, amount);
    }
  }
  /*
   * Get Current LINK Balance from contract
   */
  function getCurrentLinkBalance() external onlySupport view returns (uint256) {
    return LINK.balanceOf(address(this));
  }

  /* ===== Battle Royale Arena Methods ===== */
  function addToBattleQueue(address payable _nftAddress) external payable onlySupport returns(bool) {
    return battleQueue.push(_nftAddress);
  }

  function getBattleQueue() external view returns (address payable[] memory) {
    return battleQueue.getAll();
  }

  function isContractInQueue(address payable _contract) external view returns (bool) {
    return battleQueue.exists(_contract);
  }

  function removeFromQueue(address payable nftAddress) external onlySupport payable returns(address payable[] memory) {
    battleQueue.remove(nftAddress);
    return battleQueue.getAll();
  }

  function setWalletAddress(address payable _wallet) external onlyOwner payable {
    walletAddress = _wallet;
  }

  function bytesToAddress(bytes memory bys) internal pure returns (address payable addr) {
    assembly {
      addr := mload(add(bys,20))
    }
  }
  /*
   * addressToBytes
   * @param  {[type]} address [description]
   * @return {[type]}         [description]
   */
  function addressToBytes(address payable a) internal pure returns (bytes memory b) {
    return abi.encodePacked(a);
  }
  /* ==========================
   * CHAINLINK METHODS
   * ========================== */
  /* === Keeper Network === */
  /*
   * Check upkeep will excute upkeep when intervals hit 0
   */
  function checkUpkeep(bytes calldata checkData)
  external
  returns(
    bool upkeepNeeded,
    bytes memory performData
  ) {
    for (uint i = 0; i < battleQueue.size(); i++) {
      address payable nftAddress = battleQueue.atIndex(i);
      BattleRoyale battle = BattleRoyale(nftAddress);
      uint256 timestamp = battle.timestamp();
      uint256 intervalTime = battle.intervalTime();

      if (battle.getBattleStateInt() == 1
        && block.timestamp >= timestamp + (intervalTime * 1 minutes)) {
        return (true, addressToBytes(nftAddress));
      }
    }
    return (false, checkData);
  }
  /*
   * Perform Upkeep execute random elimination
   */
  function performUpkeep(bytes calldata performData) onlySupport external {
    address payable nftAddress = bytesToAddress(performData);
    // Adjust queue
    battleQueue.remove(nftAddress);
    battleQueue.push(nftAddress);
    // execute upkeep
    executeBattle(nftAddress);
  }
  /* === Verifiable Random Function === */
  function executeBattle(address payable _nftAddress) internal returns (bytes32) {
    BattleRoyale battle = BattleRoyale(_nftAddress);

    require(LINK.balanceOf(address(this)) >= fee);
    require(battle.getBattleStateInt() == 1);
    require(battle.getInPlaySize() > 1);

    bytes32 requestId = requestRandomness(keyHash, fee);
    requestToBattle[requestId] = _nftAddress;

    return requestId;
  }

  function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
    address payable nftAddress = requestToBattle[_requestId];
    BattleRoyale battle = BattleRoyale(nftAddress);
    battle.executeRandomElimination(_randomNumber);
    delete requestToBattle[_requestId];
  }
  // Delegate callback method called when game has ended
  function gameDidEnd(address payable _address) external payable {
    BattleRoyale battle = BattleRoyale(_address);
    uint256 balance = battle.getCurrentBalance();
    battle.withdraw(balance);
    battleQueue.remove(_address);
  }

  function executeEliminationByQueue() external onlySupport returns(bool) {
    for (uint i = 0; i < battleQueue.size(); ++i) {
      address payable nftAddress = battleQueue.atIndex(i);

      return executeElimination(nftAddress);
    }
    return false;
  }

  function executeElimination(address payable _nftAddress) public onlySupport returns(bool) {
    require(battleQueue.exists(_nftAddress));
    BattleRoyale battle = BattleRoyale(_nftAddress);
    uint256 timestamp = battle.timestamp();
    uint256 intervalTime = battle.intervalTime();

    if (battle.getBattleStateInt() == 1
    && block.timestamp >= timestamp + (intervalTime * 1 minutes)) {
      // execute upkeep
      battleQueue.remove(_nftAddress);
      battleQueue.push(_nftAddress);
      executeBattle(_nftAddress);
      return true;
    }
    return false;
  }

  /* ======== Battle Royale Methods ======== */
  function getInPlayOnNFT(address payable _nft) external view onlySupport returns (uint256[] memory) {
    BattleRoyale battle = BattleRoyale(_nft);

    return battle.getInPlay();
  }

  function getOutOfPlayOnNFT(address payable _nft) external view onlySupport returns (uint256[] memory) {
    BattleRoyale battle = BattleRoyale(_nft);

    return battle.getOutOfPlay();
  }

  function setIntervalTimeOnNFT(address payable _nft, uint256 _intervalTime) external payable onlySupport returns (uint256) {
    BattleRoyale battle = BattleRoyale(_nft);

    return battle.setIntervalTime(_intervalTime);
  }

  function setPriceOnNFT(address payable _nft, uint256 _price) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);
    battle.setPrice(_price);
  }

  function NFTAutoStartOn(address payable _nft, bool _autoStart) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);
    battle.autoStartOn(_autoStart);
  }

  function NFTAutoPayoutOn(address payable _nft, bool _autoPayout) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);
    battle.autoPayoutOn(_autoPayout);
  }

  function setFeeRateOnNFT(address payable _nft, uint256 _feeRate) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);
    battle.setFeeRate(_feeRate);
  }

  function setUnitsPerTransactionOnNFT(address payable _nft,uint256 _units) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);

    battle.setUnitsPerTransaction(_units);
  }

  function setMaxSupplyOnNFT(address payable _nft, uint256 _supply) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);

    battle.setMaxSupply(_supply);
  }

  function setDefaultTokenURIOnNFT(address payable _nft, string memory _tokenUri) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);

    battle.setDefaultTokenURI(_tokenUri);
  }

  function setPrizeTokenURIOnNFT(address payable _nft, string memory _tokenUri) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);

    battle.setPrizeTokenURI(_tokenUri);
  }

  function setArtistOnNFT(address payable _nft, address payable _artist) external onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);

    battle.setArtist(_artist);
  }

  function beginBattleOnNFT(address payable _nft) external onlySupport {
    BattleRoyale battle = BattleRoyale(_nft);

    battle.beginBattle();
  }

  function executePayoutOnNFT(address payable _nft) public onlySupport payable {
    BattleRoyale battle = BattleRoyale(_nft);

    battle.executePayout();
  }

  /* ======== Battle Royale Methods ======== */
  function transferContractOwnership(address payable newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    revokeAccessRole(payable(owner()));
    grantSupportAccess(newOwner);
    transferOwnership(newOwner);
  }
}
