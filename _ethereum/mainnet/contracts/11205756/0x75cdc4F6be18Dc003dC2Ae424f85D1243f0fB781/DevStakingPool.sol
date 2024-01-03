// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import "./IERC20.sol";

import "./StakingPool.sol";

contract DevStakingPool is StakingPool {
  address private immutable _weth;

  constructor (address weth) ERC20('JDFI ETH Fund', 'JDFI/E') {
    _weth = weth;
    _ignoreWhitelist();
    _mint(msg.sender, 10000 ether);
  }

  /**
   * @notice withdraw earned WETH rewards
   */
  function withdraw () external {
    IERC20(_weth).transfer(msg.sender, rewardsOf(msg.sender));
    _clearRewards(msg.sender);
  }

  /**
   * @notice distribute rewards to stakers
   * @param amount quantity to distribute
   */
  function distributeRewards (uint amount) override external {
    IERC20(_weth).transferFrom(msg.sender, address(this), amount);
    _distributeRewards(amount);
  }
}
