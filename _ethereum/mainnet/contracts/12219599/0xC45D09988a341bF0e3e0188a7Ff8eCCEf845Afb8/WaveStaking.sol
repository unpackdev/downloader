pragma solidity 0.5.17;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20Mintable.sol";

contract WaveStaking {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Mintable;

    event CreateStake(
        uint256 idx,
        address user,
        uint256 stakeAmount,
        uint256 stakeTimeInDays,
        uint256 interestAmount
    );
    event WithdrawReward(uint256 idx, address user, uint256 rewardAmount);
    event WithdrawStake(uint256 idx, address user);

    uint256 internal constant PRECISION = 10**8;
    uint256 internal constant DAILY_BASE_REWARD = 32000; // dailyBaseReward = 0.00032
    uint256 internal constant DAILY_GROWING_REWARD = 50; // dailyGrowingReward = 5e-7
    uint256 internal constant MAX_STAKE_PERIOD = 1000; // Max staking time is 1000 days
    uint256 internal constant MIN_STAKE_PERIOD = 10; // Min staking time is 10 days
    uint256 internal constant MAX_STAKE_LIMIT = 5000000 * (10 **6); // Max staking limit = 5 million wave
    uint256 internal constant MIN_STAKE_LIMIT = 25000 * (10 **6); // Min staking limit = 25k wave
    uint256 internal constant DAY_IN_SECONDS = 86400;

    struct Stake {
        address staker;
        uint256 stakeAmount;
        uint256 interestAmount;
        uint256 withdrawnInterestAmount;
        uint256 stakeTimestamp;
        uint256 stakeTimeInDays;
        bool active;
    }
    Stake[] public stakeList;
    mapping(address => uint256) public userStakeAmount;
    uint256 public mintedWaveTokens;

    ERC20Mintable public waveToken;

    constructor(address _waveToken) public {
        waveToken = ERC20Mintable(_waveToken);
    }

    function stake(
        uint256 stakeAmount,
        uint256 stakeTimeInDays
    ) public returns (uint256 stakeIdx) {
        require(
            stakeTimeInDays >= MIN_STAKE_PERIOD,
            "WaveStaking: stakeTimeInDays < MIN_STAKE_PERIOD"
        );
        require(
            stakeTimeInDays <= MAX_STAKE_PERIOD,
            "WaveStaking: stakeTimeInDays > MAX_STAKE_PERIOD"
        );
        require(
            stakeAmount >= MIN_STAKE_LIMIT,
            "WaveStaking: stakeAmount < MIN_STAKE_LIMIT"
        );
        require(
            stakeAmount <= MAX_STAKE_LIMIT,
            "WaveStaking: stakeAmount > MAX_STAKE_LIMIT"
        );

        // record stake
        uint256 interestAmount = getInterestAmount(
            stakeAmount,
            stakeTimeInDays
        );
        stakeIdx = stakeList.length;
        stakeList.push(
            Stake({
                staker: msg.sender,
                stakeAmount: stakeAmount,
                interestAmount: interestAmount,
                withdrawnInterestAmount: 0,
                stakeTimestamp: now,
                stakeTimeInDays: stakeTimeInDays,
                active: true
            })
        );
        mintedWaveTokens = mintedWaveTokens.add(interestAmount);
        userStakeAmount[msg.sender] = userStakeAmount[msg.sender].add(
            stakeAmount
        );

        // transfer WAVE from msg.sender
        waveToken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        // mint WAVE interest
        waveToken.mint(address(this), interestAmount);

        emit CreateStake(
            stakeIdx,
            msg.sender,
            stakeAmount,
            stakeTimeInDays,
            interestAmount
        );
    }

    function withdraw(uint256 stakeIdx) public {
        Stake storage stakeObj = stakeList[stakeIdx];
        require(
            stakeObj.staker == msg.sender,
            "WaveStaking: Sender not staker"
        );
        require(stakeObj.active, "WaveStaking: Not active");

        // calculate amount that can be withdrawn
        uint256 stakeTimeInSeconds = stakeObj.stakeTimeInDays.mul(
            DAY_IN_SECONDS
        );
        uint256 withdrawAmount;
        if (now >= stakeObj.stakeTimestamp.add(stakeTimeInSeconds)) {
            // matured, withdraw all
            withdrawAmount = stakeObj
                .stakeAmount
                .add(stakeObj.interestAmount)
                .sub(stakeObj.withdrawnInterestAmount);
            stakeObj.active = false;
            stakeObj.withdrawnInterestAmount = stakeObj.interestAmount;
            userStakeAmount[msg.sender] = userStakeAmount[msg.sender].sub(
                stakeObj.stakeAmount
            );

            emit WithdrawReward(
                stakeIdx,
                msg.sender,
                stakeObj.interestAmount.sub(stakeObj.withdrawnInterestAmount)
            );
            emit WithdrawStake(stakeIdx, msg.sender);
        } else {
            // not mature, partial withdraw
            withdrawAmount = stakeObj
                .interestAmount
                .mul(uint256(now).sub(stakeObj.stakeTimestamp))
                .div(stakeTimeInSeconds)
                .sub(stakeObj.withdrawnInterestAmount);

            // record withdrawal
            stakeObj.withdrawnInterestAmount = stakeObj
                .withdrawnInterestAmount
                .add(withdrawAmount);

            emit WithdrawReward(stakeIdx, msg.sender, withdrawAmount);
        }

        // withdraw interest to sender
        waveToken.safeTransfer(msg.sender, withdrawAmount);
    }

    function getInterestAmount(uint256 stakeAmount, uint256 stakeTimeInDays)
        public
        pure
        returns (uint256)
    {
        uint256 interestRate = _longerBonus(stakeTimeInDays);
        uint256 interestAmount = stakeAmount.mul(interestRate).div(PRECISION);
        return interestAmount;
    }

    function _longerBonus(uint256 stakeTimeInDays)
        internal
        pure
        returns (uint256)
    {
        return
            DAILY_BASE_REWARD.mul(stakeTimeInDays).add(
                DAILY_GROWING_REWARD
                    .mul(stakeTimeInDays)
                    .mul(stakeTimeInDays.add(1))
            );
    }

    function stakeLength() external view returns (uint256) {
        return stakeList.length;
    }
}