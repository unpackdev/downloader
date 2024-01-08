//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Babel is ERC20, ERC20Burnable, Ownable {

  bool public canImmediateMint;
  uint256 public nextMintTimestamp;
  address public nextMintTarget;
  uint256 public nextMintAmount;

  uint256 public timeToFulfill;

  uint256 public nextTimeToFulfill;
  uint256 public changeTimeToFulfillTimestamp;

  constructor (string memory name_, string memory symbol_) Ownable() ERC20(name_, symbol_) {
    canImmediateMint = true;
    timeToFulfill = 86400 * 7; // 7 days by default
  }

  function mint(address target, uint256 amount) public onlyOwner {
    require(canImmediateMint, "Cannot perform immediate mint anymore");
    _mint(target, amount);
  }

  function giveUpImmediateMint() public onlyOwner {
    canImmediateMint = false;
  }

  function intendToMint(address target, uint256 amount) public onlyOwner {
    // timeToFulfill is capped
    nextMintTimestamp = block.timestamp + timeToFulfill;
    nextMintAmount = amount;
    nextMintTarget = target;
  }

  function fulfillMint() public onlyOwner {
    require(block.timestamp >= nextMintTimestamp, "Time has to pass");
    require(nextMintTimestamp != 0, "Need to publish intention first");
    _mint(nextMintTarget, nextMintAmount);
    nextMintTimestamp = 0;
    nextMintAmount = 0;
    nextMintTarget = address(0);
  }

  function intendToChangeTimeToFulfill(uint256 newTime) public onlyOwner {
    require(newTime <= 365 * 86400 * 3, "Overflow prevention: cannot be longer than 3 years");
    nextTimeToFulfill = newTime;
    // always requires to wait 1 week
    changeTimeToFulfillTimestamp = block.timestamp + 86400 * 7;
  }

  function changeTimetoFulfill() public onlyOwner {
    require(block.timestamp >= changeTimeToFulfillTimestamp, "Time has to pass");
    timeToFulfill = nextTimeToFulfill;
  }
}