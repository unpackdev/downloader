// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

contract Governance {
  address public owner;
  address public ownerCandidate;

  address public boosterEscrow;

  mapping(address => bool) public games;
  mapping(address => bool) public gemlyMinters;
  mapping(address => bool) public gameMinters;

  event OwnerCandidateSet(address indexed ownerCandidate);
  event OwnerConfirmed(address indexed owner);
  event BoosterEscrowSet(address indexed escrow);
  event GemlyMinterGranted(address indexed minter);
  event GemlyMinterRevoked(address indexed minter);
  event GameMinterGranted(address indexed minter);
  event GameMinterRevoked(address indexed minter);
  event GameGranted(address indexed game);
  event GameRevoked(address indexed game);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(isOwner(msg.sender), "Not owner");
    _;
  }

  modifier onlyOwnerCandidate() {
    require(isOwnerCandidate(msg.sender), "Not owner candidate");
    _;
  }

  function setOwnerCandidate(address _ownerCandidate) external onlyOwner {
    require(_ownerCandidate != address(0), "New owner shouldn't be empty");
    ownerCandidate = _ownerCandidate;

    emit OwnerCandidateSet(ownerCandidate);
  }

  function confirmOwner() external onlyOwnerCandidate {
    owner = ownerCandidate;
    ownerCandidate = address(0x0);

    emit OwnerConfirmed(owner);
  }

  function setBoosterEscrow(address _escrow) external onlyOwner {
    boosterEscrow = _escrow;

    emit BoosterEscrowSet(boosterEscrow);
  }

  function grantGemlyMinter(address _minter) external onlyOwner {
    gemlyMinters[_minter] = true;

    emit GemlyMinterGranted(_minter);
  }

  function revokeGemlyMinter(address _minter) external onlyOwner {
    gemlyMinters[_minter] = false;

    emit GemlyMinterRevoked(_minter);
  }

  function grantGameMinter(address _minter) external onlyOwner {
    gameMinters[_minter] = true;

    emit GameMinterGranted(_minter);
  }

  function revokeGameMinter(address _minter) external onlyOwner {
    gameMinters[_minter] = false;

    emit GameMinterRevoked(_minter);
  }

  function grantGame(address _minter) external onlyOwner {
    games[_minter] = true;

    emit GameGranted(_minter);
  }

  function revokeGame(address _minter) external onlyOwner {
    games[_minter] = false;

    emit GameRevoked(_minter);
  }

  function isOwner(address _account) public view returns (bool) {
    return _account == owner;
  }

  function isOwnerCandidate(address _account) public view returns (bool) {
    return _account == ownerCandidate;
  }

  function isGemlyMinter(address _minter) public view returns (bool) {
    return gemlyMinters[_minter];
  }

  function isGameMinter(address _minter) public view returns (bool) {
    return gameMinters[_minter];
  }

  function isGame(address _game) public view returns (bool) {
    return games[_game];
  }

  function isBoosterEscrow(address _address) public view returns (bool) {
    return _address == boosterEscrow;
  }
}