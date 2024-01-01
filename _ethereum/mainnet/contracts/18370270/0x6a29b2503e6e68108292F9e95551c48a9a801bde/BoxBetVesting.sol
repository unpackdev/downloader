// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract BoxBetVesting is Ownable {
  using SafeERC20 for IERC20;

  struct Beneficiary {
    uint256 totalAmount;
    uint256 claimedAmount;
  }

  IERC20 public token;
  uint256 public startsAt;
  uint256 public duration;  // duration in seconds
  mapping(address => Beneficiary) public beneficiaries;

  constructor(
    address _tokenAddress,
    uint256 _startsAt,
    uint256 _duration  // updated parameter
  ) {
    require(_duration > 0, "Invalid vesting duration");
    token = IERC20(_tokenAddress);
    startsAt = _startsAt;
    duration = _duration;  // store duration instead of end time
  }

  function add(address _beneficiary, uint256 _amount) external onlyOwner {
    require(_beneficiary != address(0), "Invalid beneficiary address");
    require(_amount > 0, "Amount should be greater than 0");
    require(beneficiaries[_beneficiary].totalAmount == 0, "Beneficiary already exists");

    beneficiaries[_beneficiary].totalAmount = _amount;
  }

  function claim() external {
    uint256 claimableAmount = claimable(msg.sender);
    require(claimableAmount > 0, "No tokens to claim");

    beneficiaries[msg.sender].claimedAmount += claimableAmount;
    token.transfer(msg.sender, claimableAmount);
  }

  function claimable(address _beneficiary) public view returns (uint256) {
    require(block.timestamp >= startsAt, "Vesting hasn't started yet");
    Beneficiary memory beneficiary = beneficiaries[_beneficiary];
    require(beneficiary.totalAmount > 0, "Not a beneficiary");

    uint256 elapsedTime = block.timestamp - startsAt;
    if (elapsedTime > duration) {
      elapsedTime = duration;
    }

    return (beneficiary.totalAmount * elapsedTime) / duration - beneficiary.claimedAmount;
  }
}
