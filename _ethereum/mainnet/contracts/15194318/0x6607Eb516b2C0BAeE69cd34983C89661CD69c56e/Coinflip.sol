// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./console.sol";
import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

error CoinflipInProgress();
error BetAmountOutOfRange();
error InsufficientContractFunds();
error NoBetSent();

contract Coinflip is VRFConsumerBaseV2, Ownable {
  VRFCoordinatorV2Interface public COORDINATOR;

  struct Bet {
    address player;
    uint256 amount;
    uint256 bet;
  }

  // contract variables
  uint256 public feeFactor;
  uint256 public maxBetAmount;
  uint256 public minBetAmount;
  uint256 private pendingPayouts;
  address payable public VAULT;

  // chainlink vrf variables
  uint64 private immutable s_subscriptionId;
  bytes32 private immutable keyHash;

  // game paused/unpaused
  bool public _isGameActive = false;

  // mappings
  mapping(uint256 => Bet) public requestIdToBet;
  mapping(address => bool) public coinFlipsInProgress;

  // events
  event RandomnessRequested(uint256 requestId);
  event CoinflipEnd(uint256 requestId, uint256 amount, bool didWin, address walletAddress);
  event CoinflipStarted(address participant, uint256 amount, uint256 bet);

  constructor(
    uint64 subscriptionId,
    address vrfCoordinator,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    keyHash = _keyHash;
  }

  function requestCoinflip(uint256 bet) external payable {
    require(_isGameActive, "Game not active");
    if (msg.value == 0) {
      revert NoBetSent();
    }
    if (coinFlipsInProgress[msg.sender]) {
      revert CoinflipInProgress();
    }
    if (msg.value > maxBetAmount || msg.value < minBetAmount) {
      revert BetAmountOutOfRange();
    }
    uint256 potentialReward = msg.value * 2;
    pendingPayouts += potentialReward;
    if (pendingPayouts > address(this).balance) {
      revert InsufficientContractFunds();
    }
    uint256 requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      3,
      100000,
      1
    );
    requestIdToBet[requestId] = Bet(msg.sender, msg.value, bet);
    coinFlipsInProgress[msg.sender] = true;
    emit RandomnessRequested(requestId);
    emit CoinflipStarted(msg.sender, msg.value, bet);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    Bet storage playerBet = requestIdToBet[requestId];
    uint256 betAmountWithoutFees = playerBet.amount * 100 / feeFactor;
    bool hasWon = (randomWords[0] % 2 == playerBet.bet);
    if (hasWon) {
      payable(playerBet.player).transfer(betAmountWithoutFees * 2);
    }
    VAULT.transfer(playerBet.amount - betAmountWithoutFees);
    pendingPayouts -= (playerBet.amount * 2);
    coinFlipsInProgress[playerBet.player] = false;
    emit CoinflipEnd(requestId, betAmountWithoutFees, hasWon, playerBet.player);
    delete requestIdToBet[requestId];
  }

  function setVaultAddress(address vault) public onlyOwner {
    VAULT = payable(vault);
  }

  function setMaxBet(uint256 maxAmount) public onlyOwner {
    maxBetAmount = maxAmount;
  }

  function setMinBet(uint256 minAmount) public onlyOwner {
    minBetAmount = minAmount;
  }

  function setIsGameActive(bool val) public onlyOwner {
    _isGameActive = val;
  }

  function setFeeFactor(uint256 factor) public onlyOwner {
    require(factor >= 100, "factor needs to be greater than or equal to 100");
    feeFactor = factor;
  }

  receive() external payable {}
}
