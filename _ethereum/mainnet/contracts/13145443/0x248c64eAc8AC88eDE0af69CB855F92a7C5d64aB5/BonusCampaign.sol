pragma solidity ^0.6.0;

import "./StakingRewards.sol";

import "./IMint.sol";
import "./IVotingEscrow.sol";
import "./ILockSubscriber.sol";

contract BonusCampaign is StakingRewards, ILockSubscriber {
    using SafeMath for uint256;

    uint256 public bonusEmission;
    uint256 public startMintTime;
    uint256 public stopRegisterTime;

    bool private _mintStarted;

    mapping(address => bool) public registered;

    address public registrator;

    function configure(
        IERC20 _rewardsToken,
        IERC20 _votingEscrowedToken,
        uint256 _startMintTime,
        uint256 _stopRegisterTime,
        uint256 _rewardsDuration,
        uint256 _bonusEmission
    ) external onlyOwner initializer {
        _configure(
            address(0),
            _rewardsToken,
            _votingEscrowedToken,
            _rewardsDuration
        );
        startMintTime = _startMintTime;
        stopRegisterTime = _stopRegisterTime;
        bonusEmission = _bonusEmission;
    }

    modifier onlyRegistrator() {
        require(msg.sender == registrator, "!registrator");
        _;
    }

    function setRegistrator(address _registrator) external onlyOwner {
        require(_registrator != address(0), "zeroAddress");
        registrator = _registrator;
    }

    function startMint() external onlyOwner updateReward(address(0)) {
        require(!_mintStarted, "mintAlreadyHappened");
        rewardRate = bonusEmission.div(rewardsDuration);

        // Ensure the provided bonusEmission amount is not more than the balance in the contract.
        // This keeps the bonusEmission rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.

        IMint(address(rewardsToken)).mint(address(this), bonusEmission);

        lastUpdateTime = startMintTime;
        periodFinish = startMintTime.add(rewardsDuration);
        _mintStarted = true;
        emit RewardAdded(bonusEmission);
    }

    function processLockEvent(
        address account,
        uint256 lockStart,
        uint256 lockEnd,
        uint256 amount
    ) external override onlyRegistrator {
        IVotingEscrow veToken = IVotingEscrow(address(stakingToken));
        uint256 WEEK = 604800; // 24 * 60 * 60 * 7
        if (
            veToken.lockedEnd(account) >=
            block.timestamp.div(WEEK).mul(WEEK).add(veToken.MAXTIME()) &&
            _canRegister(account)
        ) {
            _registerFor(account);
        }
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
        IVotingEscrow veToken = IVotingEscrow(address(stakingToken));
        uint256 amount = veToken.balanceOfAt(account, block.number);
        uint256 WEEK = 604800; // 24 * 60 * 60 * 7
        require(amount > 0, "!stake0");
        require(
            veToken.lockedEnd(account) >=
                block.timestamp.div(WEEK).mul(WEEK).add(veToken.MAXTIME()),
            "stakedForNotEnoughTime"
        );
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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
