// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./Context.sol";
import "./DARTToken.sol";
import "./Operator.sol";
import "./Rewarder.sol";

contract RewardManager is Context, Ownable, Operator, Rewarder {
    DARTToken dARTToken;
    address operator;

    constructor(DARTToken _dARTToken) {
        dARTToken = _dARTToken;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0));

        addOperator(_newOperator);
    }

    function addPool(address _poolAddress) public onlyOperator {
        require(_poolAddress != address(0));

        addRewarder(_poolAddress);
    }

    function rewardUser(address _user, uint256 _amount) public onlyRewarder {
        require(_user != address(0));

        dARTToken.transfer(_user, _amount);
    }
}
