// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./BribesRewardPool.sol";

/**
 * @title   BribesRewardFactory
 * @author  ConvexFinance -> WombexFinance
 */
contract BribesRewardFactory {
    using Address for address;

    address public immutable operator;

    event RewardPoolCreated(address rewardPool, address depositToken);

    /**
     * @param _operator   Contract operator is Booster
     */
    constructor(address _operator) public {
        operator = _operator;
    }

    /**
     * @notice Create a Managed Reward Pool to handle distribution of all crv/wom mined in a pool
     */
    function CreateBribesRewards(address _stakingToken, address _lptoken, bool _callOperatorOnGetReward) external returns (address) {
        require(msg.sender == operator, "!auth");

        BribesRewardPool rewardPool = new BribesRewardPool(_stakingToken, operator, _lptoken, _callOperatorOnGetReward);

        emit RewardPoolCreated(address(rewardPool), _stakingToken);
        return address(rewardPool);
    }
}
