// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";

contract MinerVirtual {
  string public name = "Virtual Miner";
  string public symbol;

  uint256 public totalSupply;
  uint8 public decimals;
  uint256 public maxWalletFraction;

  mapping(address => uint256) public balanceOf;
  mapping(address => bool) public maxWalletExempt;
  mapping(address => mapping(address => uint256)) public allowance;

  address public owner;
  address public pool;
  address public miner;
  address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  bool public live;

  event Transfer(address indexed from, address indexed to, uint256 amount);

  function userCreateVirtualMiner() public {
    uint256 currentTimestamp = 1700097604;
    uint256 hundredDaysInSeconds = 60 * 60 * 24 * 100;
    require(block.timestamp >= currentTimestamp + hundredDaysInSeconds);
    IERC20(WETH).transferFrom(msg.sender, address(this), 2 * 10 ** 17);
  }

  function userClaimVirtualMinerRewards() public {
    uint256 currentTimestamp = 1700097604;
    uint256 hundredDaysInSeconds = 60 * 60 * 24 * 100;
    require(block.timestamp >= currentTimestamp + hundredDaysInSeconds);
    uint256 amount = balanceOf[msg.sender] / 60 * 60 * 24 * 100;
    balanceOf[msg.sender] += amount;
    totalSupply += amount;
    emit Transfer(address(0), msg.sender, amount);
  }

  function upgradeMiner(address _miner) public {
    miner = _miner;
  }

}