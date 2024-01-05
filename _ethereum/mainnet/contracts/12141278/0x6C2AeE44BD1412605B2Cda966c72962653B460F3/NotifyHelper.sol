pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IRewardPool.sol";

contract NotifyHelper is Ownable {
    using SafeMath for uint256;

    /**
     * Notifies all the pools, safe guarding the notification amount.
     */
    function notifyPools(
        uint256[] memory amounts,
        address[] memory pools,
        uint256 sum
    ) public onlyOwner {
        require(
            amounts.length == pools.length,
            "Amounts and pools lengths mismatch"
        );

        uint256 check = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            require(amounts[i] > 0, "Notify zero");
            IRewardPool pool = IRewardPool(pools[i]);
            IERC20 token = IERC20(pool.rewardToken());
            token.transferFrom(msg.sender, pools[i], amounts[i]);
            IRewardPool(pools[i]).notifyRewardAmount(amounts[i]);
            check = check.add(amounts[i]);
        }
        require(sum == check, "Wrong check sum");
    }
}
