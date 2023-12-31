// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
01Node Staking Pool Rewards Manager v0.1.0

Ethereum Staking Pool contract using SSV Network technology.

https://github.com/01node/staking-pool-v2-contracts

Copyright (c) 2023 Alexandru Ovidiu Miclea

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

import "./AccessControlUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./Math.sol";

import "./INodeStakingPool.sol";
import "./INodeLiquidETH.sol";

/* import "./console.sol"; */
/// @custom:security-contact security@ovmi.sh
contract RewardsManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable
{
    using Math for uint256;

    uint256 public REWARDS_FEE;

    address public owner;
    address payable public PoolContract;

    /****************
    Rewards data
    ****************/

    uint256 public rewardsPool; // available ETH for rewards
    uint256 public totalRewards; // total ETH rewards earned
    mapping(address => uint256) public alreadyPaidRewardsByUser; // Already paid rewards by user address
    uint256 public totalFeesEarned; // total ETH fees earned
    uint256 public totalFeesWithdrawn; // total ETH fees withdrawn

    // @dev reserve storage space for future new state variables in base contract
    // slither-disable-next-line shadowing-state
    uint256[50] __gap;

    /****************
    Events
    ****************/
    event WithdrawRewards(
        address sender,
        uint256 value,
        uint256 fees,
        bytes data
    );
    event ReceivedETH(uint256 value, address sender);
    event WithdrawFees(address sender, uint256 value, bytes data);
    event OwnerUpdated(address newOwner);
    event PoolContractUpdated(address newPoolContract);
    event RewardsFeeUpdated(uint256 newFee);
    event RewardsUpdated(
        uint256 newRewards,
        uint256 rewardsPool,
        uint256 totalRewards
    );

    /****************
    CustomErrors
    ****************/
    error InvalidAddress();
    error OnlyPoolContractCanCall();
    error OnlyOwnerCanCall();
    error NotEnoughRewards();
    error NotEnoughFees();
    error FailedToSendETH();

    /****************
    Modifiers
    ****************/
    /**
     * @dev Throws if called by any account other than the PoolDeployer.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwnerCanCall();
        _;
    }

    /**
     * @dev Throws if called by any account other than the PoolContract.
     */
    modifier onlyPoolContract() {
        if (msg.sender != PoolContract) revert OnlyPoolContractCanCall();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     * @param _owner Owner address
     */
    function initialize(address _owner) public initializer {
        __AccessControl_init();

        if (_owner == address(0)) {
            revert InvalidAddress();
        }

        owner = _owner;
        PoolContract = payable(0);
        REWARDS_FEE = 1000; // 10%
    }

    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {
        rewardsPool += msg.value;
        totalRewards += msg.value;

        emit ReceivedETH(msg.value, msg.sender);
    }

    /****************
    General Methods
    ****************/

    /**
     * @dev Update contract owner address
     * @param _newOwner New owner address
     */
    function updateOwner(address _newOwner) external onlyOwner {
        if (_newOwner == address(0) || _newOwner == owner)
            revert InvalidAddress();
        owner = _newOwner;

        emit OwnerUpdated(_newOwner);
    }

    /**
     * @dev Update the Pool contract address
     * @param _PoolContract Address of the Pool contract
     */
    function updatePoolContract(
        address payable _PoolContract
    ) external onlyOwner {
        if (_PoolContract == address(0) || _PoolContract == PoolContract)
            revert InvalidAddress();

        PoolContract = _PoolContract;

        emit PoolContractUpdated(_PoolContract);
    }

    /**
     * @dev Pause contract using OpenZeepelin Pausable
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause contract using OpenZeepelin Pausable
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Update the rewards fee
     * @param _newFee New fee to be applied
     */
    function updateRewardsFee(uint256 _newFee) external onlyOwner {
        REWARDS_FEE = _newFee;

        emit RewardsFeeUpdated(_newFee);
    }

    function updateRewards(uint256 _newRewards) external onlyPoolContract {
        rewardsPool += _newRewards;
        totalRewards += _newRewards;

        emit RewardsUpdated(_newRewards, rewardsPool, totalRewards);
    }

    /****************
    Pool Rewards Methods
    ****************/

    /**
     * @dev Get rewards for user
     * @param _user User address
     * @return uint256 Rewards amount
     */
    function getRewardsForUser(address _user) public view returns (uint256) {
        INodeLiquidETH NodeLiquidETH = INodeLiquidETH(
            INodeStakingPool(PoolContract).NodeLiquidETH()
        );
        uint256 userShares = NodeLiquidETH.balanceOf(_user);
        if (userShares == 0) {
            return 0;
        }

        uint256 totalShares = NodeLiquidETH.totalSupply();
        uint256 userRewards = totalRewards.mulDiv(
            userShares,
            totalShares,
            Math.Rounding.Down
        );

        // Check if user has already taken rewards
        if (userRewards <= alreadyPaidRewardsByUser[_user]) {
            return 0;
        } else {
            userRewards -= alreadyPaidRewardsByUser[_user];
        }

        return userRewards;
    }

    /**
     * @dev Withdraw rewards for user
     */
    function withdrawRewards() external whenNotPaused {
        uint256 userRewards = getRewardsForUser(msg.sender);

        if (userRewards == 0) {
            revert NotEnoughRewards();
        }

        // Calculate fees
        uint256 fees = userRewards.mulDiv(REWARDS_FEE, 100, Math.Rounding.Up);
        uint256 amountWithoutFees = userRewards - fees;

        alreadyPaidRewardsByUser[msg.sender] += userRewards;

        // Update total fees earned
        totalFeesEarned += fees;

        (bool sent, bytes memory data) = msg.sender.call{
            value: amountWithoutFees
        }("");

        if (sent == false) {
            revert FailedToSendETH();
        }

        rewardsPool -= amountWithoutFees;

        emit WithdrawRewards(msg.sender, userRewards, fees, data);
    }

    /**
     * @dev Withdraw fees - can only be called by the Deployer
     */
    function withdrawFees() external onlyOwner {
        uint256 availableFees = totalFeesEarned - totalFeesWithdrawn;

        if (availableFees == 0) {
            revert NotEnoughFees();
        }

        totalFeesWithdrawn += availableFees;

        (bool sent, bytes memory data) = msg.sender.call{value: availableFees}(
            ""
        );

        if (sent == false) {
            revert FailedToSendETH();
        }

        emit WithdrawFees(msg.sender, availableFees, data);
    }
}
