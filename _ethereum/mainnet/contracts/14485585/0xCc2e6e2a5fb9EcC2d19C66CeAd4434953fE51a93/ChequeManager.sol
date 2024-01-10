// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./MinimalForwarder.sol";
import "./Counters.sol";

import "./ERC2771Ownable.sol";
import "./Cheque.sol";
import "./IChequeManager.sol";

contract ChequeManager is ERC2771Ownable, IChequeManager {
  using Counters for Counters.Counter;

  struct ChequeDetail {
    uint256 issuedAt;
    uint256 balance;
    uint256 unlockAt;
    address issuer;
  }

  struct ChequeOption {
    uint256 fee;
    uint256 reward;
    uint256 gas;
    address tokenContract;
  }

  Counters.Counter private _optionIdTracker;
  address private _relayer;
  mapping(uint256 => ChequeOption) private _chequeOptions;
  mapping(uint256 => uint256) private _issueFees;
  mapping(address => uint256) private _memberActivities;
  mapping(bytes32 => ChequeDetail) private _cheques;
  mapping(address => uint256) private _locked;

  constructor(
    MinimalForwarder forwarder,
    address relayer
  ) ERC2771Ownable(address(forwarder)) {
    _relayer = relayer;
  }

  modifier validFeeDistribution(uint256 fee, uint256 reward, uint256 gas) {
    require(fee > reward + gas, "Reward plus gas deposit should not exceed issue fee");
    _;
  }

  modifier validOption(uint256 checkOptionId) {
    require(_chequeOptions[checkOptionId].tokenContract != address(0), "Option does not exist");
    _;
  }

  modifier enoughIssueFee(uint256 checkOptionId) {
    require(msg.value >= _chequeOptions[checkOptionId].fee, "Payment is not enough to cover issue fee");
    _;
  }

  modifier isClaimable(address claimer) {
    require(_locked[claimer] > 0, "Nothing to claim");
    _;
  }

  modifier isChequeOwner(uint256 optionId, uint256 tokenId) {
    Cheque cheque = Cheque(_chequeOptions[optionId].tokenContract);
    require(cheque.ownerOf(tokenId) == _msgSender(), "Must be the owner of the cheque");
    _;
  }

  modifier hasIssuedBefore(address user) {
    if (user != address(0)) {
      require(_memberActivities[user] > 0, "Should have issued cards before");
    }
    _;
  }

  function addChequeOption(address chequeAddress, uint256 fee, uint256 reward, uint256 gasDeposit)
    external
    onlyOwner
    validFeeDistribution(fee, reward, gasDeposit)
  {
    console.log("Adding cheque option %s", _optionIdTracker.current());
    uint256 id = _optionIdTracker.current();
    _chequeOptions[id].tokenContract = chequeAddress;
    _chequeOptions[id].fee = fee;
    _chequeOptions[id].reward = reward;
    _chequeOptions[id].gas = gasDeposit;
    _optionIdTracker.increment();
    console.log("Next cheque option %s", _optionIdTracker.current());
  }

  function setTrustedRelayer(address relayer) external onlyOwner {
    require(relayer != address(0), "Invalid relayer");
    _relayer = relayer;
  }

  function setRewardAmount(uint256 optionId, uint256 reward)
    external
    onlyOwner
    validOption(optionId)
    validFeeDistribution(_chequeOptions[optionId].fee, reward, _chequeOptions[optionId].gas)
  {
    _chequeOptions[optionId].reward = reward;
  }

  function setGasDepositAmount(uint256 optionId, uint256 gas)
    external
    onlyOwner
    validOption(optionId)
    validFeeDistribution(_chequeOptions[optionId].fee, _chequeOptions[optionId].reward, gas)
  {
    _chequeOptions[optionId].gas = gas;
  }

  function claim()
    external
    isClaimable(_msgSender())
  {
    uint256 amount = _locked[_msgSender()];
    _locked[_msgSender()] = 0;
    console.log("Claim locked value %s", amount);
    payable(_msgSender()).transfer(amount);

    emit Claim(_msgSender(), amount);
  }

  function numOfCardIssued() external view returns (uint256) {
    return _memberActivities[_msgSender()];
  }

  function issueWithUnlock(uint256 optionId, address toAddress, uint256 unlockTime) payable external {
    return _safeIssue(optionId, toAddress, unlockTime, address(0));
  }

  function issue(uint256 optionId, address toAddress) payable external {
    return _safeIssue(optionId, toAddress, 0, address(0));
  }

  function issueWithReferrer(uint256 optionId, address toAddress, uint256 unlockTime, address referrer) payable external {
    return _safeIssue(optionId, toAddress, unlockTime, referrer);
  }


  function _safeIssue(
    uint256 optionId,
    address toAddress,
    uint256 unlockTime,
    address referrer
  )
    internal
    validOption(optionId)
    enoughIssueFee(optionId)
    hasIssuedBefore(referrer)
  {
    console.log("Issue cheque address %s", _chequeOptions[optionId].tokenContract);
    Cheque cheque = Cheque(_chequeOptions[optionId].tokenContract);
    uint256 tokenId = cheque.mint(toAddress);
    console.log("Token %s minted", tokenId);
    bytes32 id = keccak256(abi.encodePacked(_chequeOptions[optionId].tokenContract, tokenId));
    console.log("Issue fee is %s", _chequeOptions[optionId].fee);
    uint256 deposit = msg.value - _chequeOptions[optionId].fee;
    console.log("Card deposit is %s", deposit);

    uint256 toOwner = _chequeOptions[optionId].fee - _chequeOptions[optionId].gas;
    if (referrer != address(0)) {
      toOwner -= _chequeOptions[optionId].reward;
      _locked[referrer] += _chequeOptions[optionId].reward;
    }

    _memberActivities[_msgSender()] += 1;
    _cheques[id].issuer = _msgSender();
    _cheques[id].issuedAt = block.timestamp;
    _cheques[id].unlockAt = unlockTime;
    _cheques[id].balance += deposit;
    console.log("Balance is %s", _cheques[id].balance);

    payable(owner()).transfer(toOwner);
    payable(_relayer).transfer(_chequeOptions[optionId].gas);

    emit Issue(_msgSender(), toAddress, referrer, optionId, tokenId, deposit);
  }

  // function redeem(uint256 optionId, uint256 tokenId, uint256 amount)
  //   external
  //   validOption(optionId)
  //   isChequeOwner(optionId, tokenId)
  // {
  //   return _safeRedeem(optionId, tokenId, amount);
  // }

  function redeemAll(uint256 optionId, uint256 tokenId)
    external
    validOption(optionId)
    isChequeOwner(optionId, tokenId)
  {
    bytes32 id = keccak256(abi.encodePacked(_chequeOptions[optionId].tokenContract, tokenId));
    console.log("Balance of cheque address: %s, tokenId: %s is ", _chequeOptions[optionId].tokenContract, tokenId, _cheques[id].balance);
    return _safeRedeem(optionId, tokenId, _cheques[id].balance);
  }

  function balanceOf(uint256 optionId, uint256 tokenId)
    view
    external
    validOption(optionId)
    returns (uint256)
  {
    bytes32 id = keccak256(abi.encodePacked(_chequeOptions[optionId].tokenContract, tokenId));
    return _cheques[id].balance;
  }

  function unlockAt(uint256 optionId, uint256 tokenId)
    view
    external
    validOption(optionId)
    returns (uint256)
  {
    bytes32 id = keccak256(abi.encodePacked(_chequeOptions[optionId].tokenContract, tokenId));
    return _cheques[id].unlockAt;
  }

  function issuedBy(uint256 optionId, uint256 tokenId)
    view
    external
    validOption(optionId)
    returns (address)
  {
    bytes32 id = keccak256(abi.encodePacked(_chequeOptions[optionId].tokenContract, tokenId));
    return _cheques[id].issuer;
  }

  function issueFee(uint256 optionId)
    view
    external
    validOption(optionId)
    returns (uint256)
  {
    return _chequeOptions[optionId].fee;
  }

  function issuedAt(uint256 optionId, uint256 tokenId)
    view
    external
    validOption(optionId)
    returns (uint256)
  {
    bytes32 id = keccak256(abi.encodePacked(_chequeOptions[optionId].tokenContract, tokenId));
    return _cheques[id].issuedAt;
  }

  function _safeRedeem(uint256 optionId, uint256 tokenId, uint256 amount) internal {
    require(amount > 0, "Nothing to redeem");
    bytes32 id = keccak256(abi.encodePacked(_chequeOptions[optionId].tokenContract, tokenId));
    require(_cheques[id].unlockAt <= block.timestamp, "Not unlocked yet");
    require(_cheques[id].balance >= amount, "Insufficient funds");

    _cheques[id].balance -= amount;
    if (_cheques[id].balance == 0) {
      Cheque cheque = Cheque(_chequeOptions[optionId].tokenContract);
      cheque.burn(tokenId);
    }

    payable(_msgSender()).transfer(amount);

    emit Redeem(_msgSender(), optionId, tokenId, amount);
  }

  function claimableAmount() view external returns (uint256) {
    return _locked[_msgSender()];
  }
}
