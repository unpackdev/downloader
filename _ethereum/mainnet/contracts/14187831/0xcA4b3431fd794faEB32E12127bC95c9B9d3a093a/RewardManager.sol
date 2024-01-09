// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./Context.sol";
import "./TokenERC20.sol";
import "./Operator.sol";
import "./Rewarder.sol";

contract RewardManager is Context, Ownable, Operator, Rewarder {
    TokenERC20 tokenERC20;
    address operator;

    constructor(TokenERC20 _tokenERC20) {
        tokenERC20 = _tokenERC20;
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

        tokenERC20.transfer(_user, _amount);
    }
}