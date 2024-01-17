// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./StakingRewards.sol";

import "./AccessControl.sol";
import "./IVeToken.sol";
import "./IMint.sol";
import "./ILockSubscription.sol";


contract BonusCampaign is StakingRewards, ILockSubscription, AccessControl {

    uint256 public bonusEmission;
    uint256 public startMintTime;
    uint256 public stopRegisterTime;

    bool private _mintStarted;

    mapping(address => bool) public registered;

    bytes32 public constant REGISTRATOR_ROLE = keccak256("REGISTRATOR_ROLE");

    constructor(
        IERC20 _rewardsToken,
        IERC20 _votingEscrowedToken,
        uint256 _startMintTime,
        uint256 _stopRegisterTime,
        uint256 _rewardsDuration,
        uint256 _bonusEmission
    ) {
        _configure(
            address(0),
            _rewardsToken,
            _votingEscrowedToken,
            _rewardsDuration
        );
        startMintTime = _startMintTime;
        stopRegisterTime = _stopRegisterTime;
        bonusEmission = _bonusEmission;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyRegistrator() {
        require(hasRole(REGISTRATOR_ROLE, msg.sender), "!registrator");
        _;
    }

    function startMint() external onlyOwner updateReward(address(0)) {
        require(!_mintStarted, "mintAlreadyHappened");
        rewardRate = bonusEmission / rewardsDuration;

        // Ensure the provided bonusEmission amount is not more than the balance in the contract.
        // This keeps the bonusEmission rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.

        IMint(address(rewardsToken)).mint(address(this), bonusEmission);

        lastUpdateTime = startMintTime;
        periodFinish = startMintTime + rewardsDuration;
        _mintStarted = true;
        emit RewardAdded(bonusEmission);
    }

    function processLockEvent(
        address account,
        uint256 lockStart,
        uint256 lockEnd,
        uint256 amount
    ) external override onlyRegistrator {
        IVeToken veToken = IVeToken(address(stakingToken));
        uint256 WEEK = 604800; // 24 * 60 * 60 * 7
        if (
            lockEnd >= block.timestamp / WEEK * WEEK + veToken.MAXTIME() &&
            _canRegister(account)
        ) {
            _registerFor(account);
        }
    }

    function processWitdrawEvent(
        address account,
        uint256 amount
    ) external override {}

    function registerFor(address account) external onlyRegistrator {
        _registerFor(account);
    }

    function register() external {
        require(block.timestamp <= stopRegisterTime, "registerNowIsBlocked");
        require(!registered[msg.sender], "alreadyRegistered");
        _registerFor(msg.sender);
    }

    function _canRegister(address account) internal view returns (bool) {
        return block.timestamp <= stopRegisterTime && !registered[account];
    }

    function canRegister(address account) external view returns (bool) {
        return _canRegister(account);
    }

    function _registerFor(address account)
        internal
        nonReentrant
        whenNotPaused
        updateReward(account)
    {
        // avoid double staking in this very block by subtracting one from block.number
        IVeToken veToken = IVeToken(address(stakingToken));
        uint256 amount = veToken.balanceOfAt(account, block.number);
        require(amount > 0, "!stake0");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        registered[account] = true;
        emit Staked(account, amount);
    }

    function lastTimeRewardApplicable()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return Math.max(startMintTime, Math.min(block.timestamp, periodFinish));
    }

    function hasMaxBoostLevel(address account) external view returns (bool) {
        return
            (block.timestamp < periodFinish || periodFinish == 0) && // is campaign active or mint not started
            registered[account]; // is user registered
    }

    function stake(uint256 amount) external override {
        revert("!allowed");
    }

    function withdraw(uint256 amount) public override {
        revert("!allowed");
    }

    function notifyRewardAmount(uint256 reward) external override {
        revert("!allowed");
    }
}
