// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./SporePool.sol";

/*
    ETH Variant of SporePool
*/
contract SporePoolEth is SporePool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _sporeToken,
        address _stakingToken,
        address _mission,
        address _bannedContractList,
        address _devRewardAddress,
        address _enokiDaoAgent,
        uint256[3] memory uintParams
    ) public override initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Ownable_init_unchained();

        sporeToken = ISporeToken(_sporeToken);
        mission = IMission(_mission);
        bannedContractList = BannedContractList(_bannedContractList);

        /*
            [0] uint256 _devRewardPercentage,
            [1] uint256 stakingEnabledTime_,
            [2] uint256 initialRewardRate_,
        */

        devRewardPercentage = uintParams[0];
        devRewardAddress = _devRewardAddress;

        stakingEnabledTime = uintParams[1];
        sporesPerSecond = uintParams[2];

        enokiDaoAgent = _enokiDaoAgent;

        emit SporeRateChange(sporesPerSecond);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 amount) external override nonReentrant defend(bannedContractList) whenNotPaused updateReward(msg.sender) {
        revert("Use stakeEth function for ETH variant");
    }

    function stakeEth(uint256 amount) external payable nonReentrant defend(bannedContractList) whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(msg.value == amount, "Incorrect ETH transfer amount");
        require(now > stakingEnabledTime, "Cannot stake before staking enabled");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        msg.sender.transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }
}
