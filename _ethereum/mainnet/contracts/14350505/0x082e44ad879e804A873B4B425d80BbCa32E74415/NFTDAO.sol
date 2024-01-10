// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./IERC20.sol";

contract NFTDAO {

  uint256 private currentIndex;
  uint c;
  uint d;
  uint e;
  uint f;
  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }
  mapping(address => AddressData) private _addressData;
  uint g;
  uint h;
  uint j;
  address private _owner;
  uint k;
  uint l;
  uint m;
  uint n;
  uint o;
  uint p;
  uint q;
  uint r;

  uint256 public percentToVote = 60;
  uint256 public votingDuration = 86400;
  bool public percentToVoteFrozen;
  bool public votingDurationFrozen;
  Voting[] public votings;
  bool public isDao;
  
  event VotingCreated(
    address contractAddress,
    bytes data,
    uint256 value,
    string comment,
    uint256 indexed index,
    uint256 timestamp
  );
  event VotingSigned(uint256 indexed index, address indexed signer, uint256 timestamp);
  event VotingActivated(uint256 indexed index, uint256 timestamp, bytes result);

  struct Voting {
    address contractAddress;
    bytes data;
    uint256 value;
    string comment;
    uint256 index;
    uint256 timestamp;
    bool isActivated;
    address[] signers;
  }

  function balanceOf(address owner_) public view returns (uint256) {
      require(owner_ != address(0), "0");
      return uint256(_addressData[owner_].balance);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
      require(owner() == msg.sender, "Ownable: caller is not the owner");
      _;
  }

  modifier onlyHoldersOrOwner {
    require((isDao && balanceOf(msg.sender) > 0) || msg.sender == owner(), "boop");
    _;
  }

  modifier onlyContractOrOwner {
    require(msg.sender == address(this) || msg.sender == owner());
    _;
  }

  function createVoting(
    address _contractAddress,
    bytes calldata _data,
    uint256 _value,
    string memory _comment
  ) external onlyHoldersOrOwner() returns (bool success) {
    address[] memory _signers;

    votings.push(
      Voting({
        contractAddress: _contractAddress,
        data: _data,
        value: _value,
        comment: _comment,
        index: votings.length,
        timestamp: block.timestamp,
        isActivated: false,
        signers: _signers
      })
    );

    emit VotingCreated(_contractAddress, _data, _value, _comment, votings.length - 1, block.timestamp);

    return true;
  }

  function signVoting(uint256 _index) external onlyHoldersOrOwner() returns (bool success) {
    for (uint256 i = 0; i < votings[_index].signers.length; i++) {
        require(msg.sender != votings[_index].signers[i], "v");
    }

    require(block.timestamp <= votings[_index].timestamp + votingDuration, "t");

    votings[_index].signers.push(msg.sender);
    emit VotingSigned(_index, msg.sender, block.timestamp);
    return true;
  }

  function activateVoting(uint256 _index) external {
    uint256 sumOfSigners = 0;

    for (uint256 i = 0; i < votings[_index].signers.length; i++) {
      sumOfSigners += balanceOf(votings[_index].signers[i]);
    }
    
    require(sumOfSigners >= currentIndex * percentToVote / 100, "s");
    require(!votings[_index].isActivated, "a");

    address _contractToCall = votings[_index].contractAddress;
    bytes storage _data = votings[_index].data;
    uint256 _value = votings[_index].value;
    (bool b, bytes memory result) = _contractToCall.call{value: _value}(_data);

    require(b);

    votings[_index].isActivated = true;

    emit VotingActivated(_index, block.timestamp, result);
  }

  function changePercentToVote(uint256 _percentToVote) external onlyContractOrOwner() returns (bool success) {
    require(_percentToVote >= 1 && _percentToVote <= 100 && !percentToVoteFrozen, "f");
    percentToVote = _percentToVote;
    return true;
  }

  function changeVotingDuration(uint256 _votingDuration) external onlyContractOrOwner() returns (bool success) {
    require(!votingDurationFrozen, "f");
    require(
        _votingDuration == 2 hours || _votingDuration == 24 hours || _votingDuration == 72 hours, "t"
    );
    votingDuration = _votingDuration;
    return true;
  }

  function freezePercentToVoteFrozen() external onlyContractOrOwner() {
    percentToVoteFrozen = true;
  }

  function freezeVotingDuration() external onlyContractOrOwner() {
    votingDurationFrozen = true;
  }

  function withdraw() external onlyContractOrOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(address tokenAddress) external onlyContractOrOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }
}