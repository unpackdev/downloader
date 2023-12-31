// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Address.sol";
import "./IERC20.sol";
import "./Utils.sol";
import "./IGasReimberser.sol";
import "./IPoolContract.sol";

// this contract was modeled after the following tweet:
// https://twitter.com/TantoNomini/status/1630677746795057152
contract GasReimberser is IGasReimberser, Utils {
  using Address for address payable;
  address public immutable POOL_ADDRESS;
  constructor(address poolAddress) {
    POOL_ADDRESS = poolAddress;
  }
  receive() external payable {}
  function flush() external {
    IPoolContract pc = IPoolContract(POOL_ADDRESS);
    address payable ender = payable(pc.getEndStaker());
    require(msg.sender == ender, "Only End Staker can run this function.");
    uint256 amount = address(this).balance;
    if (amount > 0) {
      ender.sendValue(amount);
    }
  }
  function flush_erc20(address token_contract_address) external {
    IPoolContract pc = IPoolContract(POOL_ADDRESS);
    address ender = pc.getEndStaker();
    require(msg.sender == ender, "Only End Staker can run this function.");
    uint256 balance = IERC20(token_contract_address).balanceOf(address(this));
    if (balance > 0) {
      IERC20(token_contract_address).transfer(ender, balance);
    }
  }
}
