// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Buffer {

  address public owner;

  address public pool;
  bool public live;

  uint public buyLimit = 50; // 0.5%
  uint256 public buyFee = 300; // 3%

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  /**
    * @dev Sets the pool address so max wallet and buy taxes
    can be enforced.
  */
  function goLive(address _pool) public onlyOwner {
    live = true;
    pool = _pool;
  }

  /**
    * @dev Retrieves tokens sent to the token contract.
  */
  function saveToken(address _token) public onlyOwner {
    uint balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(msg.sender, balance);
    selfdestruct(payable(_token));
  }
  
  /**
    * @dev Changes or revokes contract ownership.
  */
  function upgradeOwner(address _owner) public onlyOwner {
    owner = _owner;
  }

  /**
    * @dev Updates the buy tax and max buy values.
  */
  function updateValues(uint _buyLimit, uint _buyFee) public onlyOwner {
    buyLimit = _buyLimit;
    buyFee = _buyFee;
  }

}
