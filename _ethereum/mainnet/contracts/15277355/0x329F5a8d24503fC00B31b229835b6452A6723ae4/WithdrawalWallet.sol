// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.8.4;

import "./SafeERC20.sol";
import "./IERC20.sol";

/**
 * @dev Simple contract to hold withdrawal balances
*/
contract WithdrawalWallet {
  using SafeERC20 for IERC20;

  address private owner;

  constructor() {
    owner = msg.sender;
  }

  function transfer(address erc20Token, address destination, uint value) external {
    require(msg.sender == owner, 'ONLY_OWNER');
    IERC20(erc20Token).safeTransfer(destination, value);
  }
}
