// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./XMust.sol";

/**
 * @dev Rewarder deals with the rewards of an holder.
 */
abstract contract Rewarder is XMust {
    using SafeMath for uint256;

    mapping(address => uint256) internal _rewards;
    mapping(address => uint256) internal _lastUpdate;

    constructor() public { }

    /**
     * @dev Reward earned of an holder since last update. The ratio is one
     * reward for one xMust by day.
     *
     * @param holder Holder of xMust.
     */
    function rewardsOf(address holder) public view returns (uint256) {
        uint256 timeDifference = block.timestamp.sub(_lastUpdate[holder]);
        uint256 balance = balanceOf(holder);
        uint256 decimals = 10**uint256(decimals());
        uint256 x = balance / decimals;
        uint256 ratePerSec = decimals.mul(5).mul(x).div((uint256(20)).mul(x).add(10000)).div(60);
        return _rewards[holder].add(ratePerSec.mul(timeDifference));
    }

    function _updateRewards(address holder) internal {
        _rewards[holder] = rewardsOf(holder);
        _lastUpdate[holder] = block.timestamp;
    }

    function _burnRewards(address holder, uint256 value) internal {
        _updateRewards(holder);
        require(_rewards[holder] >= value, "Rewarder: not enough reward");
        _rewards[holder] = _rewards[holder].sub(value);
    }
}
