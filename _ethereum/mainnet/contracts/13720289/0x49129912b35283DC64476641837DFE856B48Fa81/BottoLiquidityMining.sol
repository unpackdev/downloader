// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";

/// @title Eleven-Yellow Uniswap LP mining service
/// @notice Stake BOTTO-ETH Uniswap LP tokens for BOTTO rewards
contract BottoLiquidityMining is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using TransferHelper for address;

    address public bottoEth;
    address public botto;

    uint256 public totalStakers;
    uint256 public totalRewards;
    uint256 public totalClaimedRewards;
    uint256 public startTime;
    uint256 public firstStakeTime;
    uint256 public endTime;

    uint256 private _totalStakeBottoEth;
    uint256 private _totalWeight;
    uint256 private _mostRecentValueCalcTime;

    mapping(address => uint256) public userClaimedRewards;

    mapping(address => uint256) private _userStakedBottoEth;
    mapping(address => uint256) private _userWeighted;
    mapping(address => uint256) private _userAccumulated;

    event Deposit(uint256 totalRewards, uint256 startTime, uint256 endTime);
    event Stake(address indexed staker, uint256 bottoEthIn);
    event Payout(address indexed staker, uint256 reward);
    event Withdraw(address indexed staker, uint256 bottoEthOut);

    /// @dev Expects a BOTTO-ETH LP token address & the BOTTO reward token address
    function initialize(address _bottoEth, address _botto) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        bottoEth = _bottoEth;
        botto = _botto;
    }

    function deposit(
        uint256 _totalRewards,
        uint256 _startTime,
        uint256 _endTime
    ) public virtual onlyOwner {
        require(
            startTime == 0,
            "LiquidityMining::deposit: already received deposit"
        );

        require(
            _startTime >= block.timestamp,
            "LiquidityMining::deposit: start time must be in future"
        );

        require(
            _endTime > _startTime,
            "LiquidityMining::deposit: end time must after start time"
        );

        require(
            IERC20(botto).balanceOf(address(this)) == _totalRewards,
            "LiquidityMining::deposit: contract balance does not equal expected _totalRewards"
        );

        totalRewards = _totalRewards;
        startTime = _startTime;
        endTime = _endTime;

        emit Deposit(_totalRewards, _startTime, _endTime);
    }

    function totalStake() public view returns (uint256 total) {
        total = _totalStakeBottoEth;
    }

    function totalUserStake(address user) public view returns (uint256 total) {
        total = _userStakedBottoEth[user];
    }

    modifier update() {
        if (_mostRecentValueCalcTime == 0) {
            _mostRecentValueCalcTime = firstStakeTime;
        }

        uint256 totalCurrentStake = totalStake();

        if (totalCurrentStake > 0 && _mostRecentValueCalcTime < endTime) {
            uint256 value = 0;
            uint256 sinceLastCalc = block.timestamp.sub(
                _mostRecentValueCalcTime
            );
            uint256 perSecondReward = totalRewards.div(
                endTime.sub(firstStakeTime)
            );

            if (block.timestamp < endTime) {
                value = sinceLastCalc.mul(perSecondReward);
            } else {
                uint256 sinceEndTime = block.timestamp.sub(endTime);
                value = (sinceLastCalc.sub(sinceEndTime)).mul(perSecondReward);
            }

            _totalWeight = _totalWeight.add(
                value.mul(10**18).div(totalCurrentStake)
            );

            _mostRecentValueCalcTime = block.timestamp;
        }

        _;
    }

    function stake(uint256 bottoEthIn) public virtual update nonReentrant {
        require(bottoEthIn > 0, "LiquidityMining::stake: missing stake");
        require(
            block.timestamp >= startTime,
            "LiquidityMining::stake: staking isn't live yet"
        );
        require(
            IERC20(botto).balanceOf(address(this)) > 0,
            "LiquidityMining::stake: no BOTTO balance"
        );

        if (firstStakeTime == 0) {
            firstStakeTime = block.timestamp;
        } else {
            require(
                block.timestamp < endTime,
                "LiquidityMining::stake: staking is over"
            );
        }

        if (bottoEthIn > 0) {
            bottoEth.safeTransferFrom(msg.sender, address(this), bottoEthIn);
        }

        if (totalUserStake(msg.sender) == 0) {
            totalStakers = totalStakers.add(1);
        }

        _stake(bottoEthIn, msg.sender);

        emit Stake(msg.sender, bottoEthIn);
    }

    function withdraw()
        public
        virtual
        update
        nonReentrant
        returns (uint256 bottoEthOut, uint256 reward)
    {
        totalStakers = totalStakers.sub(1);

        (bottoEthOut, reward) = _applyReward(msg.sender);

        if (bottoEthOut > 0) {
            bottoEth.safeTransfer(msg.sender, bottoEthOut);
        }

        if (reward > 0) {
            botto.safeTransfer(msg.sender, reward);
            userClaimedRewards[msg.sender] = userClaimedRewards[msg.sender].add(
                reward
            );
            totalClaimedRewards = totalClaimedRewards.add(reward);

            emit Payout(msg.sender, reward);
        }

        emit Withdraw(msg.sender, bottoEthOut);
    }

    function payout()
        public
        virtual
        update
        nonReentrant
        returns (uint256 reward)
    {
        require(
            block.timestamp < endTime,
            "LiquidityMining::payout: withdraw instead"
        );

        (uint256 bottoEthOut, uint256 _reward) = _applyReward(msg.sender);

        reward = _reward;

        if (reward > 0) {
            botto.safeTransfer(msg.sender, reward);
            userClaimedRewards[msg.sender] = userClaimedRewards[msg.sender].add(
                reward
            );
            totalClaimedRewards = totalClaimedRewards.add(reward);
        }

        _stake(bottoEthOut, msg.sender);

        emit Payout(msg.sender, _reward);
    }

    function _stake(uint256 bottoEthIn, address account) private {
        uint256 addBackBottoEth;

        if (totalUserStake(account) > 0) {
            (uint256 bottoEthOut, uint256 reward) = _applyReward(account);
            addBackBottoEth = bottoEthOut;
            _userStakedBottoEth[account] = bottoEthOut;
            _userAccumulated[account] = reward;
        }

        _userStakedBottoEth[account] = _userStakedBottoEth[account].add(
            bottoEthIn
        );

        _userWeighted[account] = _totalWeight;

        _totalStakeBottoEth = _totalStakeBottoEth.add(bottoEthIn);

        if (addBackBottoEth > 0) {
            _totalStakeBottoEth = _totalStakeBottoEth.add(addBackBottoEth);
        }
    }

    function _applyReward(address account)
        private
        returns (uint256 bottoEthOut, uint256 reward)
    {
        uint256 _totalUserStake = totalUserStake(account);
        require(
            _totalUserStake > 0,
            "LiquidityMining::_applyReward: no coins staked"
        );

        bottoEthOut = _userStakedBottoEth[account];

        reward = _totalUserStake
            .mul(_totalWeight.sub(_userWeighted[account]))
            .div(10**18)
            .add(_userAccumulated[account]);

        _totalStakeBottoEth = _totalStakeBottoEth.sub(bottoEthOut);

        _userStakedBottoEth[account] = 0;

        _userAccumulated[account] = 0;
    }

    function rescueTokens(
        address tokenToRescue,
        address to,
        uint256 amount
    ) public virtual onlyOwner nonReentrant {
        if (tokenToRescue == bottoEth) {
            require(
                amount <=
                    IERC20(bottoEth).balanceOf(address(this)).sub(
                        _totalStakeBottoEth
                    ),
                "LiquidityMining::rescueTokens: that BottoEth belongs to stakers"
            );
        } else if (tokenToRescue == botto) {
            if (totalStakers > 0) {
                require(
                    amount <=
                        IERC20(botto).balanceOf(address(this)).sub(
                            totalRewards.sub(totalClaimedRewards)
                        ),
                    "LiquidityMining::rescueTokens: that BOTTO belongs to stakers"
                );
            }
        }

        tokenToRescue.safeTransfer(to, amount);
    }
}
