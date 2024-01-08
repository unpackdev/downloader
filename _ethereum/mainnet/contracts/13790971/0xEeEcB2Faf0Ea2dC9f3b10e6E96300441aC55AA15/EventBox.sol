// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./Ownable.sol";

contract EventBox is Ownable {

  struct Event {
    uint deadline;
    bytes32 tokenIdsHash;
  }

  Event[] public events;

  // event id => user address => token ids
  mapping(uint => mapping(address => uint[])) public submissions;

  IERC721 public immutable floyds;

  constructor(IERC721 _floyds) {
    floyds = _floyds;
  }

  /* view functions */

  function getEligibleTokensOfUser(
    uint eventId,
    uint[] calldata tokenIds,
    address user
  ) external view returns (uint[] memory eligibleTokenIds) {

    bytes32 hash = keccak256(abi.encode(tokenIds));
    require(events[eventId].tokenIdsHash == hash, "Event token ids don't match");

    uint[] memory tempTokenIds = new uint[](tokenIds.length);
    uint idx;

    for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      if (floyds.ownerOf(tokenId) == user) {
        tempTokenIds[idx] = tokenId;
        idx++;
      }
    }

    eligibleTokenIds = new uint[](idx);

    if (idx == 0) {
      return eligibleTokenIds;
    }

    for (uint i = 0; i < idx; i++) {
      eligibleTokenIds[i] = tempTokenIds[i];
    }

    return eligibleTokenIds;
  }

  function timeLeft(uint eventId) external view returns (uint secondsLeft) {
    uint deadline = events[eventId].deadline;
    return deadline > block.timestamp ? deadline - block.timestamp : 0;
  }

  function getSubmissionsOfUser(
    uint eventId,
    address user
  ) external view returns (uint[] memory submittedTokenIds) {
    return submissions[eventId][user];
  }

  /* state changing functions */

  function addEvent(
    uint eventId,
    uint deadline,
    uint[] calldata tokenIds
  ) external onlyOwner {

    require(deadline > block.timestamp, "Deadline must be in the future");
    require(tokenIds.length > 0, "Must have at least one token");
    require(eventId == events.length, "Unexpected event id");

    bytes32 hash = keccak256(abi.encode(tokenIds));
    events.push(Event(deadline, hash));
  }

  function updateEventDeadline(uint eventId, uint deadline) external onlyOwner {

    require(deadline > block.timestamp, "Deadline must be in the future");
    require(eventId < events.length, "Unexpected event id");

    events[eventId].deadline = deadline;
  }

  function submit(
    uint eventId,
    uint[] calldata eventTokenIds,
    uint[] calldata tokenIdsToSubmit
  ) external {

    bytes32 hash = keccak256(abi.encode(eventTokenIds));
    require(events[eventId].tokenIdsHash == hash, "Event token ids don't match");
    require(block.timestamp < events[eventId].deadline, "Deadline has passed");
    require(tokenIdsToSubmit.length > 0, "Must submit at least one token");

    for (uint i = 0; i < tokenIdsToSubmit.length; i++) {

      uint tokenId = tokenIdsToSubmit[i];
      bool isEligible = false;

      for (uint j = 0; j < eventTokenIds.length; j++) {
        if (tokenId == eventTokenIds[j]) {
          isEligible = true;
          break;
        }
      }

      require(isEligible, "Token is not eligible");

      floyds.transferFrom(msg.sender, address(this), tokenId);
      submissions[eventId][msg.sender].push(tokenId);
    }
  }

  function _returnTokens(uint eventId, address[] memory users) internal {

    for (uint i = 0; i < users.length; i++) {

      address user = users[i];
      uint tokenCount = submissions[eventId][user].length;

      for (uint j = tokenCount; j > 0; j--) {
        uint tokenId = submissions[eventId][user][j - 1];
        submissions[eventId][user].pop();
        floyds.transferFrom(address(this), user, tokenId);
      }
    }
  }

  function returnTokens(uint eventId, address[] calldata users) external onlyOwner {
    _returnTokens(eventId, users);
  }

  function returnTokensAfterDeadline(uint eventId, address[] calldata users) external {
    uint deadline = events[eventId].deadline;
    require(block.timestamp > deadline, "Deadline has not passed yet");
    _returnTokens(eventId, users);
  }

}
