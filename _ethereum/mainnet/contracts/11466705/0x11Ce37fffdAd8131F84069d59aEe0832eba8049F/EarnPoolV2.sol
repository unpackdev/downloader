// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./Console.sol";
import "./EarnPool.sol";

contract EarnPoolV2 is EarnPool {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  constructor (string memory name, string memory symbol, bool allowAll, address fees) public EarnPool(name, symbol, allowAll, fees) {
  }

  function _harvest() internal override virtual {
    uint256[] memory prev = mapToken(_rewards, balanceOfToken);
    _harvestRewards();
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 tokenSupply = token.balanceOf(address(this)).sub(prev[i], 'tokenSupply<0');
      _rewardTotals[token] = _rewardTotals[token].add(tokenSupply);
      tokenSupply = _adjustRewardFees(token, tokenSupply);
      _updateRewardSharePrice(token, tokenSupply);
    }
  }

  function _adjustRewardFees(IERC20 /* token */, uint256 tokenSupply) internal virtual returns(uint256) {
    return tokenSupply;
  }

}
