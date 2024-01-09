// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IWETH.sol";


abstract contract Managable {
  using SafeERC20 for IERC20;

  address public owner;

  /***********************
  + Construct / Kill     +
  ***********************/

  constructor(address _owner) {
    owner = _owner;
  }

  function destroy(address payable recipient) external onlyOwner {

    selfdestruct(recipient);
  }

  /***********************
  + Management          +
  ***********************/

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this");
    _;
  }

  function changeOwner(
    address _newOwner
  ) external onlyOwner {
    owner = _newOwner;
  }
}
