// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TokenTimelock.sol";
import "./IERC20.sol";

contract TimedVault is TokenTimelock {
  uint256 public _actualReleaseTime;
  constructor(address token, address beneficiary) TokenTimelock(IERC20(token), beneficiary, block.timestamp + 1) public {
  }
  modifier onlyBeneficiary {
    require(beneficiary() == msg.sender, "only can be called by beneficiary");
    _;
  }
  function deposit(uint256 amount) public virtual onlyBeneficiary {
    require(IERC20(token()).transferFrom(beneficiary(), address(this), amount), "failed to transferFrom token");
    _actualReleaseTime = block.timestamp + 60*60*24*30*6; // 6 month holding period
  }
  function releaseTime() public view virtual override returns (uint256) {
    return _actualReleaseTime;
  }
}
