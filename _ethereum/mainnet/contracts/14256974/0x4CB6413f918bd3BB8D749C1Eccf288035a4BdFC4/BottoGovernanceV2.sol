pragma solidity >=0.6.0 <0.8.0;

import "./BottoGovernance.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract BottoGovernanceV2 is BottoGovernance, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using TransferHelper for address;

    uint256 public totalRewards;
    uint256 public totalClaimedRewards;
    uint256 public startRewardsTime;
    uint256 public firstStakeRewardsTime;
    uint256 public endRewardsTime;

    uint256 private _totalWeight;
    uint256 private _mostRecentValueCalcTime;

    mapping(address => uint256) public userClaimedRewards;

    mapping(address => uint256) private _userWeighted;
    mapping(address => uint256) private _userAccumulated;

    uint256 private _perSecondReward;

    event Deposit(uint256 totalRewards, uint256 startTime, uint256 endTime);
    event Payout(address indexed staker, uint256 reward);

    /// @param _botto ERC20 contract address of BOTTO token
    /// @dev BOTTO token contract address is initialized
    function init(address _botto) external virtual initializer {
        BottoGovernance.initialize(_botto);
        __ReentrancyGuard_init();
    }

    function deposit(
        uint256 _totalRewards,
        uint256 _startTime,
        uint256 _endTime
    ) external virtual onlyOwner {
        require(
            startRewardsTime == 0,
            "Governance::deposit: already received deposit"
        );

        require(
            _startTime >= block.timestamp,
            "Governance::deposit: start time must be in future"
        );

        require(
            _endTime > _startTime,
            "Governance::deposit: end time must after start time"
        );

        require(
            IERC20(botto).balanceOf(address(this)) >= _totalRewards,
            "Governance::deposit: contract balance does not equal expected _totalRewards"
        );

        totalRewards = _totalRewards;
        startRewardsTime = _startTime;
        endRewardsTime = _endTime;

        emit Deposit(_totalRewards, _startTime, _endTime);
    }

    modifier update() virtual {
        if (_mostRecentValueCalcTime == 0) {
            _mostRecentValueCalcTime = firstStakeRewardsTime;
        }

        if (
            totalStaked > 0 &&
            firstStakeRewardsTime > 0 &&
            _mostRecentValueCalcTime < endRewardsTime
        ) {
            uint256 value = 0;
            uint256 sinceLastCalc = block.timestamp.sub(
                _mostRecentValueCalcTime
            );

            if (_perSecondReward == 0) {
                _perSecondReward = totalRewards.div(
                    endRewardsTime.sub(firstStakeRewardsTime)
                );
            }

            if (block.timestamp < endRewardsTime) {
                value = sinceLastCalc.mul(_perSecondReward);
            } else {
                uint256 sinceEndTime = block.timestamp.sub(endRewardsTime);
                value = (sinceLastCalc.sub(sinceEndTime)).mul(_perSecondReward);
            }

            _totalWeight = _totalWeight.add(value.mul(10**18).div(totalStaked));

            _mostRecentValueCalcTime = block.timestamp;
        }
        _;
    }

    function stake(uint256 _botto) public virtual override update nonReentrant {
        require(_botto > 0, "Governance::stake: missing stake");

        IERC20(botto).transferFrom(msg.sender, address(this), _botto);

        if (
            startRewardsTime != 0 &&
            block.timestamp >= startRewardsTime &&
            firstStakeRewardsTime == 0
        ) {
            firstStakeRewardsTime = block.timestamp;
        }

        _stakeRewards(_botto, msg.sender);

        emit Staked(msg.sender, _botto);
    }

    function _stakeRewards(uint256 _bottoIn, address _account) private {
        uint256 addBackBotto;

        if (userStakes[_account] > 0) {
            (uint256 bottoOut, uint256 reward) = _applyReward(_account);
            addBackBotto = bottoOut;
            userStakes[_account] = bottoOut;
            _userAccumulated[_account] = reward;
        }

        userStakes[_account] = userStakes[_account].add(_bottoIn);
        _userWeighted[_account] = _totalWeight;

        totalStaked = totalStaked.add(_bottoIn);

        if (addBackBotto > 0) {
            totalStaked = totalStaked.add(addBackBotto);
        }
    }

    /// @notice Unstake previously staked tokens
    /// @dev Existing token stake is transferred back to owner
    function unstake() public virtual override update nonReentrant {
        (uint256 bottoOut, uint256 reward) = _applyReward(msg.sender);
        uint256 totalBottoOut = bottoOut.add(reward);

        if (totalBottoOut > 0) {
            IERC20(botto).transfer(msg.sender, totalBottoOut);
        }

        if (reward > 0) {
            userClaimedRewards[msg.sender] = userClaimedRewards[msg.sender].add(
                reward
            );
            totalClaimedRewards = totalClaimedRewards.add(reward);
            emit Payout(msg.sender, reward);
        }

        emit Unstaked(msg.sender, bottoOut);
    }

    function payout()
        external
        virtual
        update
        nonReentrant
        returns (uint256 reward)
    {
        (uint256 _bottoOut, uint256 _reward) = _applyReward(msg.sender);

        reward = _reward;

        if (reward > 0) {
            IERC20(botto).transfer(msg.sender, reward);
            userClaimedRewards[msg.sender] = userClaimedRewards[msg.sender].add(
                reward
            );
            totalClaimedRewards = totalClaimedRewards.add(reward);
        }

        _stakeRewards(_bottoOut, msg.sender);

        emit Payout(msg.sender, _reward);
    }

    function _applyReward(address _account)
        private
        returns (uint256 bottoOut, uint256 reward)
    {
        uint256 _totalUserStake = userStakes[_account];
        require(
            _totalUserStake > 0,
            "Governance::_applyReward: no botto staked"
        );

        bottoOut = userStakes[_account];

        reward = _totalUserStake
            .mul(_totalWeight.sub(_userWeighted[_account]))
            .div(10**18)
            .add(_userAccumulated[_account]);

        totalStaked = totalStaked.sub(bottoOut);

        userStakes[_account] = 0;
        _userAccumulated[_account] = 0;
    }

    /// @notice Sweeps excess tokens to a specified recipient address
    /// @param _token address of token to recover
    /// @param _recipient payable address for token beneficiary
    /// @dev Token amount is recovered; only excess non-staked tokens & due rewards in case of BOTTO
    function recover(address _token, address payable _recipient)
        public
        virtual
        override
        onlyOwner
        nonReentrant
    {
        uint256 _balance = IERC20(_token).balanceOf(address(this));

        if (_token == botto) {
            _balance = _balance.sub(
                totalStaked.add(totalRewards.sub(totalClaimedRewards))
            );
            require(
                _balance > 0,
                "Governance::recover: that Botto belongs to stakers"
            );
        }

        TransferHelper.safeTransfer(_token, _recipient, _balance);
        emit RecoveryTransfer(_token, _balance, _recipient);
    }
}
