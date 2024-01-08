// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./IUniswap.sol";
import "./SafeERC20.sol";


/// @author Nathan Worsley (https://github.com/CodeForcer)
/// @title MistX Gasless Router
contract MistXJar {
  /***********************
  + Global Settings      +
  ***********************/

  using SafeERC20 for IERC20;

  address public owner;
  mapping (address => bool) public managers;

  address public pool;

  uint256 public bribePercent;

  receive() external payable {}
  fallback() external payable {}

  /***********************
  + Jar Functions        +
  ***********************/

  function deposit() public payable {
    require(msg.value > 0, "Don't be stingy");
    uint256 bribe = (msg.value * bribePercent) / 100;
    block.coinbase.transfer(bribe);
  }

  function empty(
    uint256 _amountOutMin,
    address _to,
    uint256 _deadline
  ) public onlyOwner {
    address[] memory path = new address[](2);
    path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    path[1] = pool;

    IUniswapRouter(
      payable(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a)
    ).swapExactETHForTokens{value: address(this).balance}(
      _amountOutMin,
      path,
      _to,
      _deadline
    );
  }

  /***********************
  + Administration       +
  ***********************/

  constructor() {
    owner = msg.sender;
    managers[msg.sender] = true;
    bribePercent = 80;
    pool = 0xCD6bcca48069f8588780dFA274960F15685aEe0e;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this");
    _;
  }

  modifier onlyManager() {
    require(managers[msg.sender] == true, "Only managers can call this");
    _;
  }

  function addManager(
    address _manager
  ) external onlyOwner {
    managers[_manager] = true;
  }

  function removeManager(
    address _manager
  ) external onlyOwner {
    managers[_manager] = false;
  }

  function changeBribe(
    uint256 _bribePercent
  ) public onlyManager {
    if (_bribePercent > 100) {
      revert("Split must be a valid percentage");
    }
    bribePercent = _bribePercent;
  }

  function changePool(
    address _pool
  ) public onlyManager {
    pool = _pool;
  }

  function changeOwner(
    address _owner
  ) public onlyOwner {
    owner = _owner;
  }

  function rescueStuckToken(
    address _tokenContract,
    uint256 _value,
    address _to
  ) external onlyManager {
    IERC20(_tokenContract).safeTransfer(_to, _value);
  }
}
