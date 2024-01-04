// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract DexmexMarketing is Ownable {
  using SafeMath for uint;
  
  struct Vest {
    uint remain;
    uint stepAmt;
    uint lastTime;
    uint timeframe;
    address token;
  }

  mapping(address => Vest) public vests;

  function escrowFund(address _vest, address _token, uint _fund, uint _timeframe, uint _stepAmount) external onlyOwner {
    vests[_vest].remain = _fund;
    vests[_vest].stepAmt = _stepAmount;
    vests[_vest].lastTime = block.timestamp;
    vests[_vest].timeframe = _timeframe;
    vests[_vest].token = _token;
  }

  function claimPayment() external {
    Vest storage partner = vests[msg.sender];
    require(partner.remain > 0, "No funds in vesting account");

    uint passed = block.timestamp.sub(partner.lastTime);
    uint stepPassed = passed.div(partner.timeframe);
    require(stepPassed > 0, "Required to wait for some more days from last claim.");

    uint payAmt = partner.stepAmt.mul(stepPassed);
    if (partner.remain < payAmt) {
      payAmt = partner.remain;
    }
    partner.remain = partner.remain.sub(payAmt);
    partner.lastTime = block.timestamp;
    IERC20(partner.token).transfer(msg.sender, payAmt);
  }
}