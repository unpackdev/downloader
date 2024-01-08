/*
    Copyright 2021 Memento Blockchain Pte. Ltd.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";

/**
 * @title RewardsManager
 * @author DEXTF Protocol
 *
 * Contract for Rewards Manager that has a mapping of approved and unapproved
 * stake pools, as well as holding the supply of rewards token and transfering
 * rewards token to relevant stakers.
 * Only approved stake pools can call rewards manager to transfer reward tokens
 * to the stake pool's stakers.
*/

contract RewardsManager is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Contract address for rewards token
    IERC20 public rewardsToken;

    mapping(address => bool) private approvedStakePools;

    constructor(address _rewardsToken) {
        rewardsToken = IERC20(_rewardsToken);
    }

    /**
    * Function to check if stake pool is approved by rewards manager
    * @param _stakePool      Address of stake pool
    * @return bool           Boolean approval of stake pool in rewards manager
    */
    function stakePoolApproved(address _stakePool) public view returns(bool) {
        return approvedStakePools[_stakePool];
    }

    /**
    * Function for owner to approve stake pool in rewards manager
    * @param _stakePool      Address of stake pool
    */
    function approveStakePool(address _stakePool) external onlyOwner {
        approvedStakePools[_stakePool] = true;
    }

    /**
    * Function for owner to reject stake pool in rewards manager
    * @param _stakePool      Address of stake pool
    */
    function rejectStakePool(address _stakePool) external onlyOwner {
        approvedStakePools[_stakePool] = false;
    }

    /**
    * Function for stake pool to call to transfer appropriate reward tokens
    * to staker
    * @param _account      Address of user to send rewards to
    * @param _rewards      Amount of reward tokens to send to user
    */
    function transferRewardsToUser(address _account, uint256 _rewards) external {
        require(approvedStakePools[msg.sender] == true, "Stake pool not approved");

        rewardsToken.safeTransfer(_account, _rewards);
    }

    /**
    * Owner only function to recover any ERC20 tokens in contract
    * @param tokenAddress     Address of ERC20 token to recover
    * @param tokenAmount      Amount of ERC 20 token to recover
    */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    }
}
