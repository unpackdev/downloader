// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.6;

import "./IFoundation.sol";
import "./IERC20.sol";

contract Foundation is IFoundation {
  IERC20 public constant usdp = IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);

  address public duckStaking = 0x3f93dE882dA8150Dc98a3a1F4626E80E3282df46;
  address public usdpStakingCollector;
  
  address public auction = 0xC6733B8bb1eF64eF450e8fCd8682f6bEc0A5099a;

  uint public constant BASE = 100;

  uint public liquidationFee;
  uint public sfSharesForDuckStaking = 50;
  uint public lfSharesForDuckStaking = 100;

  // Unit multisig initially
  address public gov = 0xae37E8f9a3f960eE090706Fa4db41Ca2f2C56Cb8;

  event Distributed(uint usdpStaking, uint duckStaking);

  modifier auctionOnly() {
    require(msg.sender == auction, "Foundation: !auction");
    _;
  }

  modifier g() {
    require(msg.sender == gov, "Foundation: !gov");
    _;
  }

  constructor (address _usdpStaking) {
    usdpStakingCollector = _usdpStaking;
  }

  function setGov(address _gov) external g {
    gov = _gov;
  }

  function setDuckStaking(address _duckStaking) external g {
    duckStaking = _duckStaking;
  }

  function setUSDPStaking(address _usdpStakingCollector) external g {
    usdpStakingCollector = _usdpStakingCollector;
  }

  function setAuction(address _auction) external g {
    auction = _auction;
  }

  function setSFSharesForDuckStaking(uint _sfSharesForDuckStaking) external g {
    require(_sfSharesForDuckStaking <= BASE, "Foundation: shares > BASE");
    sfSharesForDuckStaking = _sfSharesForDuckStaking;
  }

  function setLFSharesForDuckStaking(uint _lfSharesForDuckStaking) external g {
    require(_lfSharesForDuckStaking <= BASE, "Foundation: shares > BASE");
    lfSharesForDuckStaking = _lfSharesForDuckStaking;
  }

  function submitLiquidationFee(uint fee) external override auctionOnly {
    liquidationFee = liquidationFee + fee;
  }

  function distribute() external override {
    uint usdpBalance = usdp.balanceOf(address(this));

    uint stabilityFee = usdpBalance - liquidationFee;

    uint duckStakingAmount = liquidationFee * lfSharesForDuckStaking / BASE + stabilityFee * sfSharesForDuckStaking / BASE;
    uint usdpStakingAmount = usdpBalance - duckStakingAmount;

    liquidationFee = 0;

    usdp.transfer(usdpStakingCollector, usdpStakingAmount);
    usdp.transfer(duckStaking, duckStakingAmount);

    emit Distributed(usdpStakingAmount, duckStakingAmount);
  }
}
