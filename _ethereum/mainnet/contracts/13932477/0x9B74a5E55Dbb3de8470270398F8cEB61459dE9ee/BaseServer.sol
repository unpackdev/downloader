// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

interface IMasterChefV1 {
    function withdraw(uint256 _pid, uint256 _amount) external;
    function deposit(uint256 _pid, uint256 _amount) external;
}

abstract contract BaseServer is Ownable {
  IMasterChefV1 public constant masterchefV1 = IMasterChefV1(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
  IERC20 public constant sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

  uint256 public immutable pid;

  address public immutable minichef;

  event Harvest(uint256 indexed pid);
  event Withdraw(uint256 indexed pid, uint256 indexed amount);
  event Deposit(uint256 indexed pid, uint256 indexed amount);

  constructor(uint256 _pid, address _minichef) {
    pid = _pid;
    minichef = _minichef;
  }

  function harvestAndBridge() public {
    masterchefV1.withdraw(pid, 0);
    bridge();
    emit Harvest(pid);
  }

  function withdraw() public onlyOwner {
    masterchefV1.withdraw(pid, 1);
    emit Withdraw(pid, 1);
  }

  function deposit(address token) public onlyOwner {
    IERC20(token).approve(address(masterchefV1), 1);
    masterchefV1.deposit(pid, 1);
    emit Deposit(pid, 1);
  }

  function bridge() public virtual;
}