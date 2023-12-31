// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ILiquidityGauge.sol";
import "./IERC20.sol";
import "./ILocker.sol";
import "./PendleLocker.sol";
import "./SafeTransferLib.sol";
import "./ISDTDistributor.sol";
import "./IPendleFeeDistributor.sol";

interface IWETH {
    function deposit() external payable;
}

/// @title A contract that accumulates ETH rewards and notifies them to the LGV4
/// @author StakeDAO
contract PendleAccumulatorV2 {
    using SafeTransferLib for IERC20;

    // Errors
    error DIFFERENT_LENGTH();
    error FEE_TOO_HIGH();
    error NO_BALANCE();
    error NO_REWARD();
    error NOT_ALLOWED();
    error NOT_ALLOWED_TO_PULL();
    error NOT_CLAIMED_ALL();
    error ONGOING_REWARD();
    error WRONG_CLAIM();
    error ZERO_ADDRESS();

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant VE_PENDLE = 0x4f30A9D41B80ecC5B94306AB4364951AE3170210;
    address public constant PENDLE_FEE_D = 0x8C237520a8E14D658170A633D96F8e80764433b9;

    // fee recipients
    address public bountyRecipient;
    address public daoRecipient;
    address public veSdtFeeProxy;
    address public votesRewardRecipient;
    uint256 public bountyFee;
    uint256 public daoFee;
    uint256 public veSdtFeeProxyFee;
    uint256 public claimerFee;

    address public governance;
    address public locker = 0xD8fa8dC5aDeC503AcC5e026a98F32Ca5C1Fa289A;
    address public gauge = 0x50DC9aE51f78C593d4138263da7088A973b8184E;
    address public sdtDistributor;

    uint256 public periodsToAdd = 4;
    /// @notice weth rewards period to notify
    uint256 public periodsToNotify;

    mapping(uint256 => uint256) public rewards; // period -> reward amount
    mapping(address => uint256) public canPullTokens;

    /// @notice If set, the voters rewards will be distributed to the gauge
    bool public distributeVotersRewards;

    // Events
    event BountyFeeSet(uint256 _old, uint256 _new);
    event BountyRecipientSet(address _old, address _new);
    event ClaimerFeeSet(uint256 _old, uint256 _new);
    event DaoFeeSet(uint256 _old, uint256 _new);
    event DaoRecipientSet(address _old, address _new);
    event DistributeVotersRewardsSet(bool _distributeAllRewards);
    event ERC20Rescued(address _token, uint256 _amount);
    event GaugeSet(address _old, address _new);
    event GovernanceSet(address _old, address _new);
    event LockerSet(address _old, address _new);
    event PeriodsToAddSet(uint256 _old, uint256 _new);
    event RewardNotified(address _gauge, address _tokenReward, uint256 _amountNotified);
    event SdtDistributorUpdated(address _old, address _new);
    event VeSdtFeeProxyFeeSet(uint256 _old, uint256 _new);
    event VeSdtFeeProxySet(address _old, address _new);

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _governance,
        address _daoRecipient,
        address _bountyRecipient,
        address _veSdtFeeProxy,
        address _votesRewardRecipient
    ) {
        governance = _governance;
        daoRecipient = _daoRecipient;
        bountyRecipient = _bountyRecipient;
        veSdtFeeProxy = _veSdtFeeProxy;
        votesRewardRecipient = _votesRewardRecipient;
        daoFee = 500; // 5%
        bountyFee = 1000; // 10%
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Claims Eth rewards via the locker, wrap to WETH and notify it to the LGV4
    function claimForVePendle() external {
        address[] memory pools = new address[](1);
        pools[0] = VE_PENDLE;
        uint256[] memory rewardsClaimable =
            IPendleFeeDistributor(PENDLE_FEE_D).getProtocolClaimables(address(locker), pools);
        /// check if there is any eth to claim for the vePENDLe pool
        if (rewardsClaimable[0] == 0) revert NO_REWARD();
        // reward for 1 months, split the reward in periodsToAdd
        // charge fees once for the entire month
        _chargeFee(_claimReward(pools));
        periodsToNotify += periodsToAdd;
    }

    /// @notice Claims rewards for the voters and send to a recipient
    /// @param _pools pools to claim for
    function claimForVoters(address[] calldata _pools) external {
        // VE_PENDLE pool can't be present
        for (uint256 i; i < _pools.length;) {
            if (_pools[i] == VE_PENDLE) revert WRONG_CLAIM();
            unchecked {
                ++i;
            }
        }
        address[] memory vePendlePool = new address[](1);
        vePendlePool[0] = VE_PENDLE;
        uint256 vePendleRewardClaimable =
            IPendleFeeDistributor(PENDLE_FEE_D).getProtocolClaimables(address(locker), vePendlePool)[0];
        uint256 totalAccrued = IPendleFeeDistributor(PENDLE_FEE_D).getProtocolTotalAccrued(address(locker));
        uint256 claimed = IPendleFeeDistributor(PENDLE_FEE_D).claimed(address(locker));
        uint256 totalReward = _claimReward(_pools);

        if (totalReward + _pools.length != totalAccrued - claimed - vePendleRewardClaimable) revert NOT_CLAIMED_ALL();

        // send the reward to the recipient if it is not to distribute
        // and not charge fees on this
        if (!distributeVotersRewards) {
            IERC20(WETH).transfer(votesRewardRecipient, totalReward);
        } else {
            _chargeFee(totalReward);
        }
    }

    /// @notice Claims rewards for voters and vePendle (all rewarded pools need to be included)
    /// @param _pools pools to claim for
    function claimForAll(address[] memory _pools) external {
        uint256 totalAccrued = IPendleFeeDistributor(PENDLE_FEE_D).getProtocolTotalAccrued(address(locker));
        uint256 claimed = IPendleFeeDistributor(PENDLE_FEE_D).claimed(address(locker));

        uint256 totalReward = _claimReward(_pools);
        if (totalReward + _pools.length != totalAccrued - claimed) revert NOT_CLAIMED_ALL();
        periodsToNotify += periodsToAdd;

        if (!distributeVotersRewards) {
            address[] memory vePendlePool = new address[](1);
            vePendlePool[0] = VE_PENDLE;
            uint256 vePendleRewardClaimable =
                IPendleFeeDistributor(PENDLE_FEE_D).getProtocolClaimables(address(locker), vePendlePool)[0];
            uint256 votersTotalReward = totalReward - vePendleRewardClaimable;
            // transfer the amount without charging fees
            IERC20(WETH).transfer(votesRewardRecipient, votersTotalReward);
            totalReward -= votersTotalReward;
        }
        if (totalReward != 0) {
            _chargeFee(totalReward);
        }
        _notifyReward(WETH);

        _distributeSDT();
    }

    /// @notice Notify the reward already claimed for the current period
    /// @param _token token to notify as reward
    function notifyReward(address _token) external {
        _notifyReward(_token);
        _distributeSDT();
    }

    /// @notice Notify the rewards already claimed for the current period
    /// @param _tokens tokens to notify as reward
    function notifyRewards(address[] memory _tokens) external {
        uint256 tokensLength = _tokens.length;
        for (uint256 i; i < tokensLength;) {
            _notifyReward(_tokens[i]);
            unchecked {
                ++i;
            }
        }
        _distributeSDT();
    }

    /// @notice Pull tokens
    /// @param _tokens tokens to pulls
    /// @param _amounts amounts to transfer to the caller
    function pullTokens(address[] calldata _tokens, uint256[] calldata _amounts) external {
        if (canPullTokens[msg.sender] == 0) revert NOT_ALLOWED_TO_PULL();

        if (_tokens.length != _amounts.length) revert DIFFERENT_LENGTH();

        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                SafeTransferLib.safeTransferETH(msg.sender, _amounts[i]);
            } else {
                SafeTransferLib.safeTransfer(_tokens[i], msg.sender, _amounts[i]);
            }
        }
    }

    /// @notice Claim reward for the pools
    /// @param _pools pools to claim the rewards
    function _claimReward(address[] memory _pools) internal returns(uint256 claimed) {
        uint256 balanceBefore = address(this).balance;
        PendleLocker(locker).claimRewards(address(this), _pools);
        // Wrap Eth to WETH
        claimed = address(this).balance - balanceBefore;
        if (claimed == 0) revert NO_BALANCE();
        IWETH(WETH).deposit{value: address(this).balance}();
    }

    /// @notice Reserve fees for dao, bounty and veSdtFeeProxy
    /// @param _amount amount to charge fees
    function _chargeFee(uint256 _amount) internal {
        // dao part
        if (daoFee > 0) {
            uint256 daoAmount = (_amount * daoFee) / 10_000;
            SafeTransferLib.safeTransfer(WETH, daoRecipient, daoAmount);
        }

        // bounty part
        if (bountyFee > 0) {
            uint256 bountyAmount = (_amount * bountyFee) / 10_000;
            SafeTransferLib.safeTransfer(WETH, bountyRecipient, bountyAmount);
        }

        // veSDTFeeProxy part
        if (veSdtFeeProxyFee > 0) {
            uint256 veSdtFeeProxyAmount = (_amount * veSdtFeeProxyFee) / 10_000;
            SafeTransferLib.safeTransfer(WETH, veSdtFeeProxy, veSdtFeeProxyAmount);
        }
    }

    /// @notice Distribute SDT if there is any
    function _distributeSDT() internal {
        if (sdtDistributor != address(0)) {
            ISDTDistributor(sdtDistributor).distribute(gauge);
        }
    }

    /// @notice Notify the new reward to the LGV4
    /// @param _tokenReward token to notify
    function _notifyReward(address _tokenReward) internal {
        uint256 amountToNotify;
        if (_tokenReward == WETH && periodsToNotify != 0) {
            uint256 currentWeek = block.timestamp * 1 weeks / 1 weeks;
            if (rewards[currentWeek] != 0) revert ONGOING_REWARD();
            amountToNotify = IERC20(WETH).balanceOf(address(this)) / periodsToNotify;
            rewards[currentWeek] = amountToNotify;
            periodsToNotify -= 1;
        } else {
            amountToNotify = IERC20(_tokenReward).balanceOf(address(this));
        }

        if (amountToNotify != 0) {
            if (claimerFee > 0) {
                uint256 claimerReward = (amountToNotify * claimerFee) / 10_000;
                SafeTransferLib.safeTransfer(_tokenReward, msg.sender, claimerReward);
                amountToNotify -= claimerReward;
            }

            IERC20(_tokenReward).approve(gauge, amountToNotify);
            ILiquidityGauge(gauge).deposit_reward_token(_tokenReward, amountToNotify);

            emit RewardNotified(gauge, _tokenReward, amountToNotify);
        }
    }

    /// @notice Set DAO recipient
    /// @param _daoRecipient recipient address
    function setDaoRecipient(address _daoRecipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_daoRecipient == address(0)) revert ZERO_ADDRESS();
        emit DaoRecipientSet(daoRecipient, _daoRecipient);
        daoRecipient = _daoRecipient;
    }

    /// @notice Set Bounty recipient
    /// @param _bountyRecipient recipient address
    function setBountyRecipient(address _bountyRecipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_bountyRecipient == address(0)) revert ZERO_ADDRESS();
        emit BountyRecipientSet(bountyRecipient, _bountyRecipient);
        bountyRecipient = _bountyRecipient;
    }

    /// @notice Set VeSdtFeeProxy
    /// @param _veSdtFeeProxy proxy address
    function setVeSdtFeeProxy(address _veSdtFeeProxy) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_veSdtFeeProxy == address(0)) revert ZERO_ADDRESS();
        emit VeSdtFeeProxySet(veSdtFeeProxy, _veSdtFeeProxy);
        veSdtFeeProxy = _veSdtFeeProxy;
    }

    /// @notice Set fees reserved to the DAO at every claim
    /// @param _daoFee fee (100 = 1%)
    function setDaoFee(uint256 _daoFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_daoFee > 10_000 || _daoFee + bountyFee + veSdtFeeProxyFee + claimerFee > 10_000) {
            revert FEE_TOO_HIGH();
        }
        emit DaoFeeSet(daoFee, _daoFee);
        daoFee = _daoFee;
    }

    /// @notice Set fees reserved to bounty at every claim
    /// @param _bountyFee fee (100 = 1%)
    function setBountyFee(uint256 _bountyFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_bountyFee > 10_000 || _bountyFee + daoFee + veSdtFeeProxyFee + claimerFee > 10_000) revert FEE_TOO_HIGH();
        emit BountyFeeSet(bountyFee, _bountyFee);
        bountyFee = _bountyFee;
    }

    /// @notice Set fees reserved to VeSdtFeeProxy at every claim
    /// @param _veSdtFeeProxyFee fee (100 = 1%)
    function setVeSdtFeeProxyFee(uint256 _veSdtFeeProxyFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_veSdtFeeProxyFee > 10_000 || _veSdtFeeProxyFee + daoFee + bountyFee + claimerFee > 10_000) {
            revert FEE_TOO_HIGH();
        }
        emit VeSdtFeeProxyFeeSet(veSdtFeeProxyFee, _veSdtFeeProxyFee);
        veSdtFeeProxyFee = _veSdtFeeProxyFee;
    }

    /// @notice Set fees reserved to claimer at every claim
    /// @param _claimerFee (100 = 1%)
    function setClaimerFee(uint256 _claimerFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_claimerFee > 10_000) revert FEE_TOO_HIGH();
        emit ClaimerFeeSet(claimerFee, _claimerFee);
        claimerFee = _claimerFee;
    }

    /// @notice Sets gauge for the accumulator which will receive and distribute the rewards
    /// @dev Can be called only by the governance
    /// @param _gauge gauge address
    function setGauge(address _gauge) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_gauge == address(0)) revert ZERO_ADDRESS();
        emit GaugeSet(gauge, _gauge);
        gauge = _gauge;
    }

    /// @notice Sets SdtDistributor to distribute from the Accumulator SDT Rewards to Gauge.
    /// @dev Can be called only by the governance
    /// @param _sdtDistributor gauge address
    function setSdtDistributor(address _sdtDistributor) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_sdtDistributor == address(0)) revert ZERO_ADDRESS();

        emit SdtDistributorUpdated(sdtDistributor, _sdtDistributor);
        sdtDistributor = _sdtDistributor;
    }

    /// @notice Set distribute voter rewards to true/false
    /// @dev Can be called only by the governance
    /// @param _distributeVotersRewards enable/disable reward distribution
    function setDistributeVotersRewards(bool _distributeVotersRewards) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        emit DistributeVotersRewardsSet(distributeVotersRewards = _distributeVotersRewards);
    }

    /// @notice Allows the governance to set the new governance
    /// @dev Can be called only by the governance
    /// @param _governance governance address
    function setGovernance(address _governance) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_governance == address(0)) revert ZERO_ADDRESS();
        emit GovernanceSet(governance, _governance);
        governance = _governance;
    }

    /// @notice Allows the governance to set the locker
    /// @dev Can be called only by the governance
    /// @param _locker locker address
    function setLocker(address _locker) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_locker == address(0)) revert ZERO_ADDRESS();
        emit LockerSet(locker, _locker);
        locker = _locker;
    }

    /// @notice Allows the governance to set rewards periods to add
    /// @dev Can be called only by the governance
    /// @param _periodsToAdd reward period to add at every ve_pendle claim
    function setPeriodsToAdd(uint256 _periodsToAdd) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        emit PeriodsToAddSet(periodsToAdd, _periodsToAdd);
        periodsToAdd = _periodsToAdd;
    }

    /// @notice Toggle the allowance to pull tokens from the contract
    /// @dev Can be called only by the governance
    /// @param _user user to toggle
    function togglePullAllowance(address _user) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        canPullTokens[_user] = canPullTokens[_user] == 0 ? 1 : 0;
    }

    /// @notice A function that rescue any ERC20 token
    /// @param _token token address
    /// @param _amount amount to rescue
    /// @param _recipient address to send token rescued
    function rescueToken(address _token, uint256 _amount, address _recipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_recipient == address(0)) revert ZERO_ADDRESS();

        if (_token == address(0)) {
            SafeTransferLib.safeTransferETH(msg.sender, _amount);
        } else {
            SafeTransferLib.safeTransfer(_token, msg.sender, _amount);
        }

        emit ERC20Rescued(_token, _amount);
    }

    receive() external payable {}
}
