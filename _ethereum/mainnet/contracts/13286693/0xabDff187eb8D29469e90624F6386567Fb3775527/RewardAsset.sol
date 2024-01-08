// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";

/**
 * @notice This ERC20 is only for the testnet.
 */
contract RewardAsset is ERC20 {
  constructor() ERC20('Reward', 'Reward') {
    _mint(msg.sender, 1e30 / 2);
    _mint(address(this), 1e30 / 2);
  }

  /**
   * @notice The faucet is for testing ELYFI functions
   */
  function faucet() external {
    _transfer(address(this), msg.sender, 10000 * 1e18);
  }
}
