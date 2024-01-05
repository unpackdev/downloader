// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./Context.sol";
import "./TotemToken.sol";
import "./Operator.sol";
import "./Rewarder.sol";

contract RewardManager is Context, Ownable, Operator, Rewarder {
    TotemToken totemToken;
    address operator;

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

    constructor(TotemToken _totemToken) {
        totemToken = _totemToken;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0), "Rewards: New Operator address cannot be zero.");

        addOperator(_newOperator);
        emit SetOperator(_newOperator);
    }

    function addPool(address _poolAddress) public onlyOperator {
        require(_poolAddress != address(0), "Rewards: Pool address cannot be zero.");

        addRewarder(_poolAddress);
        emit SetRewarder(_poolAddress);
    }

    function rewardUser(address _user, uint256 _amount) public onlyRewarder {
        require(_user != address(0), "Rewards: User address cannot be zero.");

        require(totemToken.transfer(_user, _amount));
    }
}
