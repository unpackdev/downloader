// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Address.sol";

import "./IReferralProgram.sol";
import "./IInflation.sol";
import "./IFeeReceiving.sol";
import "./IAutoStakeFor.sol";
import "./IVeToken.sol";

// Token distribution is very similar to MasterChef's distribution
// logic, but MasterChef's mint is supposed to be unlimited in
// time and has fixed amount of reward per period, so we made some
// changes in the staking logic. In particular, we changed earned()
// and updatePool() functions, so now arbitrary Token portions are
// distributed correctly. Also we make the virtual stake for the
// owner to avoid stacking Token reward on the contract. The virtual
// stake is only 1 wei so it won't affect other users' stakes, but
// there will always be a non-zero stake, so if some Token remains
// on the contract, owner can claim it. Token can remain because
// MasterChef doesn't mint reward if there are no stakers, but
// Inflation mints it in any case.

abstract contract BaseVault is ERC20, Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct Reward {
        address rewardToken;    // Reward token address
        uint128 accRewardPerShare;  // Accumulated reward per share
        uint256 lastBalance;    // Balance of this contract at the last moment when pool was updated
        uint256 payedRewardForPeriod;   // Reward amount payed for all the period
    }

    struct FeeReceiver {
        address receiver;   // Address of fee receiver
        uint256 bps; // Amount of reward token for the receiver (in BPs)
        bool isFeeReceivingCallNeeded;  // Flag if the feeReceiving() call needed or not
        mapping(address => bool) isTokenAllowedToBeChargedOfFees;   // Map if fee will be charged on this token
    }

    address public inflation;    // Inflation contract address
    uint256 public startTime;   // Timestamp when the vault was configured
    IERC20 public immutable stakeToken;   // Stake token address
    IReferralProgram public referralProgram;    // Referral program contract address
    IAutoStakeFor public votingStakingRewards;  // VSR contract address

    Reward[] public rewards;    // Array of reward tokens addresses

    mapping(uint256 => FeeReceiver) public feeReceivers;  // Reward token receivers
    uint256 public feeReceiversLength;  // Reward token receivers count

    bool public isGetRewardFeesEnabled; // Flag if fee distribution on getting reward enabled or not

    uint256 public depositFeeBps;   // On deposit fee amount (in BPs)
    address public depositFeeReceiver;  // On deposit fee receiver

    mapping(address => int256[]) public rewardDebts;  // users' reward debts
    mapping(address => address) public rewardDelegates;  // delegates addresses

    uint256 public percentageToBeLocked;
    address public veToken;

    uint256 internal constant ACC_REWARD_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256[] amounts);
    event LogUpdatePool(uint256 lpSupply, uint256[] rewardsPerPeriod);
    event NewRewardToken(address newToken);
    event Delegated(address delegator, address recipient);

    modifier onlyInflation {
        require(_msgSender() == inflation, "not inflation");
        _;
    }

    /**
    * @param _rewardToken reward token
    * @param _stakeToken stake token (LP)
    * @param _inflation Inflation address
    * @param _name LP Vault token name
    * @param _symbol LP Vault token symbol
    * @param _referralProgramAddress Referral program contract address
    */
    constructor(
        address _rewardToken,
        IERC20 _stakeToken,
        address _inflation,
        string memory _name,
        string memory _symbol,
        address _referralProgramAddress,
        uint256 _percentageToBeLocked,
        address _veToken
    ) ERC20(_name, _symbol) {
        rewards.push(Reward(_rewardToken, 0, 0, 0));
        stakeToken = _stakeToken;
        inflation = _inflation;
        referralProgram = IReferralProgram(_referralProgramAddress);
        percentageToBeLocked = _percentageToBeLocked;
        veToken = _veToken;
        IERC20(_rewardToken).approve(address(veToken), type(uint256).max);
        _pause();
    }

    /**
    * @notice Deletes all fee receivers
    * @dev Can be called only by owner
    */
    function deleteAllFeeReceivers() external onlyOwner {
        feeReceiversLength = 0;
    }


    function setPercentageToBeLocked(uint256 _percentageToBeLocked) external onlyOwner {
        require(_percentageToBeLocked <= 100, "invalid percentage");
        percentageToBeLocked = _percentageToBeLocked;
    }

    function setVeToken(address _veToken) external onlyOwner {
        address token = rewards[0].rewardToken;
        IERC20(token).approve(veToken, 0);
        IERC20(token).approve(_veToken, type(uint256).max);
        veToken = _veToken;
    }

    function setVotingStakingRewards(IAutoStakeFor _votingStakingRewards) external onlyOwner {
        votingStakingRewards = _votingStakingRewards;
    }

    /**
    * @notice Adds fee receiver
    * @dev Can be called only by owner
    * @param _receiver New receiver address
    * @param _bps Amount of BPs for the new receiver
    * @param _isFeeReceivingCallNeeded Flag if feeReceiving() call needed
    * @param _rewardsTokens Reward token addresses
    * @param _statuses Flags if vault should pay fee on this token or not
    * @return feeReceiverIndex Index of the new added receiver
    */
    function addFeeReceiver(
        address _receiver,
        uint256 _bps,
        bool _isFeeReceivingCallNeeded,
        address[] calldata _rewardsTokens,
        bool[] calldata _statuses
    )
        external
        onlyOwner
        returns(uint256 feeReceiverIndex)
    {
        require(_rewardsTokens.length == _statuses.length, "invalidLengths");
        feeReceiverIndex = feeReceiversLength++;
        FeeReceiver storage feeReceiver = feeReceivers[feeReceiverIndex];
        feeReceiver.receiver = _receiver;
        feeReceiver.bps = _bps;
        feeReceiver.isFeeReceivingCallNeeded = _isFeeReceivingCallNeeded;
        for (uint256 i; i < _rewardsTokens.length; i++) {
            _setFeeReceiversTokensToBeChargedOfFees(feeReceiverIndex, _rewardsTokens[i], _statuses[i]);
        }
    }

    /**
    * @notice Returns reward token array length
    */
    function rewardsCount() external view returns(uint256) {
        return rewards.length;
    }

    /**
    * @notice Sets fee receiver address
    * @dev Can be called only by owner
    * @param _index Receiver index
    * @param _receiver New receiver address
    */
    function setFeeReceiverAddress(uint256 _index, address _receiver) external onlyOwner {
        feeReceivers[_index].receiver = _receiver;
    }

    /**
    * @notice Sets BPs for fee receiver
    * @dev Can be called only by owner
    * @param _index Receiver index
    * @param _bps New receiver BPs
    */
    function setFeeReceiverBps(uint256 _index, uint256 _bps) external onlyOwner {
        require(_bps < 10000, "incorrect BPs");
        feeReceivers[_index].bps = _bps;
    }

    /**
    * @notice Sets isFeeReceivingCallNeeded flag for fee receiver
    * @dev Can be called only by owner
    * @param _index Receiver index
    * @param _isFeeReceivingCallNeeded New flag
    */
    function setFeeReceiversCallNeeded(uint256 _index, bool _isFeeReceivingCallNeeded) external onlyOwner {
        feeReceivers[_index].isFeeReceivingCallNeeded = _isFeeReceivingCallNeeded;
    }

    /**
    * @notice Sets isTokenAllowedToBeChargedOfFees flag for specified token at specified fee receiver
    * @dev Can be called only by owner
    * @param _index Receiver index
    * @param _rewardsToken Reward token address to change isTokenAllowedToBeChargedOfFees status
    * @param _status New status for isTokenAllowedToBeChargedOfFees flag
    */
    function setFeeReceiversTokensToBeChargedOfFees(uint256 _index, address _rewardsToken, bool _status) external onlyOwner {
        _setFeeReceiversTokensToBeChargedOfFees(_index, _rewardsToken, _status);
    }

    /**
    * @notice Sets isTokenAllowedToBeChargedOfFees flags for several fee receivers
    * @dev Can be called only by owner
    * @param _indices Receivers indices
    * @param _rewardsTokens Reward tokens addresses to change isTokenAllowedToBeChargedOfFees statuses
    * @param _statuses New statuses for isTokenAllowedToBeChargedOfFees flags
    */
    function setFeeReceiversTokensToBeChargedOfFeesMulti(
        uint256[] calldata _indices,
        address[] calldata _rewardsTokens,
        bool[] calldata _statuses
    ) external onlyOwner {
        require(_indices.length == _rewardsTokens.length, "invalidLengthsOfRewardsTokens");
        require(_indices.length == _statuses.length, "invalidLengthsOfStatuses");
        for (uint256 i; i < _indices.length; i++) {
            _setFeeReceiversTokensToBeChargedOfFees(_indices[i], _rewardsTokens[i], _statuses[i]);
        }
    }

    /**
    * @notice Sets Inflation contract address
    * @dev can be called only by owner
    * @param _inflation new Inflation contract address
    */
    function setInflation(address _inflation) external onlyOwner {
        inflation = _inflation;
    }

    /**
    * @notice Sets Referral program contract address
    * @dev Can be called only by owner
    * @param _refProgram New Referral program contract address
    */
    function setReferralProgram(address _refProgram) external onlyOwner {
        referralProgram = IReferralProgram(_refProgram);
    }

    /**
    * @notice Sets the flag if fee on getting reward is claimed or not
    * @dev Can be called only by owner
    * @param _isEnabled New onGetRewardFeesEnabled status
    */
    function setOnGetRewardFeesEnabled(bool _isEnabled) external onlyOwner {
        isGetRewardFeesEnabled = _isEnabled;
    }

    /**
    * @notice Sets deposit fee BPs
    * @dev can be called only by owner
    * @param _bps New deposit fee BPs
    */
    function setDepositFeeBps(uint256 _bps) external onlyOwner {
        require(_bps < 10000, "incorrect BPs");
        depositFeeBps = _bps;
    }

    /**
    * @notice Sets deposit fee receiver
    * @dev can be called only by owner
    * @param _receiver New deposit fee receiver
    */
    function setDepositFeeReceiver(address _receiver) external onlyOwner {
        depositFeeReceiver = _receiver;
    }

    /**
    * @notice Configures Vault
    * @dev can be called only by Inflation
    */
    function configure() external virtual onlyInflation whenPaused {
        _unpause();
        updatePool();
        address owner_ = owner();
        _mint(owner_, 1 wei);
        _depositFor(1 wei, owner_);
        startTime = block.timestamp;
    }

    /**
    * @notice Returns user's reward debt
    * @param _account User's address
    * @param _index Index of reward token
    */
    function getRewardDebt(address _account, uint256 _index) external view returns(int256) {
        if (_index < rewardDebts[_account].length) return rewardDebts[_account][_index];
        return 0;
    }

    /**
    * @notice Adds reward token
    * @dev Can be called only by owner
    * @param _newToken New reward token
    */

    function addRewardToken(address _newToken) external onlyOwner {
        rewards.push(Reward(_newToken, 0, 0, 0));
        updatePool();
        emit NewRewardToken(_newToken);
    }

    /**
    * @notice Returns user's earned reward
    * @dev Mutability speciefier should be manually switched to 'view'
    * in ABI due to Curve's claimable_tokens function implementation
    * @param _user User's address
    * @param _index Index of reward token
    * @return pending Amount of pending reward
    */
    function earned(address _user, uint256 _index) external virtual returns (uint256 pending) {
        Reward[] memory _rewards = rewards;
        require(_index < _rewards.length, "index exceeds amount of reward tokens");
        uint256 accRewardPerShare_ = _rewards[_index].accRewardPerShare;
        uint256 lpSupply = totalSupply() - balanceOf(address(this));
        uint256 vaultEarned;

        if (_index == 0) {
            vaultEarned = IInflation(inflation).claimable(address(this)); 
        } else {
            vaultEarned = _getEarnedAmountFromExternalProtocol(_user, _index);
        }
        uint256 balance = IERC20(_rewards[_index].rewardToken).balanceOf(address(this));
        uint256 rewardForPeriod = balance + vaultEarned - (_rewards[_index].lastBalance - _rewards[_index].payedRewardForPeriod);
        if (lpSupply != 0) {
            uint256 reward = rewardForPeriod;
            accRewardPerShare_ += reward * ACC_REWARD_PRECISION / lpSupply;
        }
        if (_index < rewardDebts[_user].length) {
            pending = uint256(int256(balanceOf(_user) * accRewardPerShare_ / ACC_REWARD_PRECISION) - rewardDebts[_user][_index]);
        } else {
            pending = balanceOf(_user) * accRewardPerShare_ / ACC_REWARD_PRECISION;
        }

    }

    /**
    * @notice Updates pool
    * @dev Mints Token if available, claims all reward from the gauge
    */
    function updatePool() public virtual whenNotPaused {
        Reward[] memory _rewards = rewards;
        uint256 length = _rewards.length;
        _harvestFromExternalProtocol();
        IInflation(inflation).getToken(address(this));
        uint256[] memory rewardsForPeriod = new uint256[](length);
        uint256 lpSupply = totalSupply() - balanceOf(address(this));
        uint256 multiplier = ACC_REWARD_PRECISION;
        for (uint256 i; i < length; i++) {
            uint256 balance = IERC20(_rewards[i].rewardToken).balanceOf(address(this)); // get the balance after claim/mint
            rewardsForPeriod[i] = balance - (_rewards[i].lastBalance - _rewards[i].payedRewardForPeriod);   // calculate how much reward came from the last time
            rewards[i].lastBalance = balance;
            rewards[i].payedRewardForPeriod = 0;
            if (lpSupply > 0) rewards[i].accRewardPerShare += uint128(rewardsForPeriod[i] * multiplier / lpSupply);
        }

        emit LogUpdatePool(lpSupply, rewardsForPeriod);
    }

    /**
    * @notice Deposits stake tokens for user for reward allocation
    * @param _amount Amount of tokens to deposit
    * @param _to Address of a beneficiary
    */
    function depositFor(uint256 _amount, address _to) public virtual nonReentrant whenNotPaused {
        _depositForFrom(_amount, _to, _msgSender());
    }

    function _depositForFrom(uint256 _amount, address _to, address _from) internal virtual {
        _amount = _chargeFeesOnDeposit(_amount);
        updatePool();
        _mint(_to, _amount);
        _depositFor(_amount, _to);
        _depositToExternalProtocol(_amount, _from);
        IReferralProgram referral = referralProgram;
        if(!referral.users(_to).exists) {
            address rootAddress = referral.rootAddress();
            referral.registerUser(rootAddress, _to);
        }
        emit Deposit(_from, _amount, _to);
    }

    /**
    * @notice Withdraw Vault LP tokens.
    * @dev Withdraws underlying tokens from Gauge, transfers Vault LP to 'to' address
    * @param _amount Vault LP token amount to unwrap.
    * @param _to The receiver of Vault LP tokens.
    */
    function withdraw(uint256 _amount, address _to) public nonReentrant virtual whenNotPaused {
        updatePool();
        _withdraw(_amount, _msgSender());
        _withdrawFromExternalProtocol(_amount, _to);
        _burn(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _amount, _to);
    }

    /**
    * @notice Harvest all available reward for the user.
    * @param _to The receiver of the reward tokens.
    */
    function getReward(address _to) public virtual nonReentrant whenNotPaused {
        _getReward(_msgSender(), _to, false);
    }

    function _getReward(address _for, address _to, bool _hardSend) internal virtual {
        updatePool();
        Reward[] memory _rewards = rewards;
        uint256 rewardsLength = _rewards.length;
        uint256[] memory _pendingRewards = new uint256[](rewardsLength);
        uint256 multiplier = ACC_REWARD_PRECISION;

        // Interactions
        for (uint256 i; i < rewardsLength; i++) {
            int256 accumulatedReward = int256(balanceOf(_for) * _rewards[i].accRewardPerShare / multiplier);
            if (i >= rewardDebts[_for].length) rewardDebts[_for].push(0);
            _pendingRewards[i] = uint256(accumulatedReward - rewardDebts[_for][i]);

            rewardDebts[_for][i] = accumulatedReward;
            if (_pendingRewards[i] > 0) {
                address rewardTokenAddress = _rewards[i].rewardToken;
                uint256 rewardsAmountWithFeesTaken = _chargeFees(_for, rewardTokenAddress, _pendingRewards[i]);
                _transferOrLock(rewardTokenAddress, rewardsAmountWithFeesTaken, _to, _hardSend);
                rewards[i].payedRewardForPeriod += _pendingRewards[i];
                _pendingRewards[i] = rewardsAmountWithFeesTaken;
            }
        }

        emit Harvest(_for, _pendingRewards);
    }

    /**
    * @notice Withdraw tokens from Vault and harvest reward for transaction sender to `_to`
    * @param _amount LP token amount to withdraw
    * @param _to Receiver of the LP tokens and rewards
    */
    function withdrawAndHarvest(uint256 _amount, address _to) public virtual nonReentrant whenNotPaused {
        updatePool();
        address sender = _msgSender();
        Reward[] memory _rewards = rewards;
        uint256 multiplier = ACC_REWARD_PRECISION;
        // Effects

        _withdrawFromExternalProtocol(_amount, _to);
        _burn(sender, _amount);

        uint256 rewardsLength = _rewards.length;
        uint256[] memory _pendingRewards = new uint256[](rewardsLength);

        for (uint256 i; i < rewardsLength; i++) {
            if (i >= rewardDebts[sender].length) {
                rewardDebts[sender].push(-int256(_amount * _rewards[i].accRewardPerShare / multiplier));
            } else {
                rewardDebts[sender][i] -= int256(_amount * _rewards[i].accRewardPerShare / multiplier);
            }
            int256 accumulatedReward = int256(balanceOf(sender) * _rewards[i].accRewardPerShare / multiplier);
            _pendingRewards[i] = uint256(accumulatedReward - rewardDebts[sender][i]);

            rewardDebts[sender][i] = accumulatedReward;
            if (_pendingRewards[i] > 0) {
                address rewardTokenAddress = _rewards[i].rewardToken;
                uint256 rewardsAmountWithFeesTaken = _chargeFees(sender, rewardTokenAddress, _pendingRewards[i]);
                _transferOrLock(rewardTokenAddress, rewardsAmountWithFeesTaken, _to, false);
                rewards[i].payedRewardForPeriod += _pendingRewards[i];
                _pendingRewards[i] = rewardsAmountWithFeesTaken;
            }
        }
        emit Harvest(sender, _pendingRewards);
        emit Withdraw(_msgSender(), _amount, _to);
    }

    function setDelegate(address _baseReceiver, address _delegate) external onlyOwner {
        require(rewardDelegates[_baseReceiver] != _delegate, "!new");
        rewardDelegates[_baseReceiver] = _delegate;
        emit Delegated(_baseReceiver, _delegate);
    }

    function getRewardForDelegator(address _baseReceiver)
        nonReentrant
        virtual 
        external {
        require(_msgSender() == rewardDelegates[_baseReceiver], "unknown sender");
        _getReward(_baseReceiver, _msgSender(), true);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {
        updatePool();
        _withdraw(amount, sender);
        super._transfer(sender, recipient, amount);
        _depositFor(amount, recipient);
    }

    function _depositFor(uint256 _amount, address _to) internal virtual {
        Reward[] memory _rewards = rewards;
        // Effects
        uint256 multiplier = ACC_REWARD_PRECISION;

        for (uint256 i; i < _rewards.length; i++) {
            if (i >= rewardDebts[_to].length) {
                rewardDebts[_to].push(int256(_amount * _rewards[i].accRewardPerShare / multiplier));
            } else {
                rewardDebts[_to][i] += int256(_amount * _rewards[i].accRewardPerShare / multiplier);
            }
        }

    }

    function _withdraw(uint256 _amount, address _user) internal virtual {
        Reward[] memory _rewards = rewards;
        uint256 multiplier = ACC_REWARD_PRECISION;
        // Effects
        for (uint256 i; i < _rewards.length; i++) {
            if (i >= rewardDebts[_user].length) {
                rewardDebts[_user].push(-int256(_amount * _rewards[i].accRewardPerShare / multiplier));
            } else {
                rewardDebts[_user][i] -= int256(_amount * _rewards[i].accRewardPerShare / multiplier);
            }
        }

    }

    function _chargeFees(
        address _sender,
        address _rewardToken,
        uint256 _amount
    ) internal virtual returns (uint256) {
        if (!isGetRewardFeesEnabled) {
            return _amount;
        }
        uint256 fee;
        uint256 amountAfterFee = _amount;

        for (uint256 i = 0; i < feeReceiversLength; i++) {
            FeeReceiver storage _feeReceiver = feeReceivers[i];
            if (_feeReceiver.isTokenAllowedToBeChargedOfFees[_rewardToken]) {
                fee = _feeReceiver.bps * _amount / 10000;
                IERC20(_rewardToken).safeTransfer(_feeReceiver.receiver, fee);
                amountAfterFee -= fee;
                if (_feeReceiver.isFeeReceivingCallNeeded) {
                    IFeeReceiving(_feeReceiver.receiver).feeReceiving(
                        _sender,
                        _rewardToken,
                        fee
                    );
                }
            }
        }
        return amountAfterFee;
    }

    function _transferOrLock(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _hardSend
    ) internal {
        if (_token != rewards[0].rewardToken || _hardSend) {
            IERC20(_token).safeTransfer(_receiver, _amount);
        } else {
            uint256 toLock = percentageToBeLocked * _amount / 100;
            uint256 toTransfer = _amount - toLock;
            IVeToken veToken_ = IVeToken(veToken);
            uint256 unlockTime = veToken_.lockedEnd(_receiver);
            if (unlockTime == 0) {
                IVeToken.Point memory initialPoint = veToken_.pointHistory(0);
                uint256 rewardsDuration = votingStakingRewards.rewardsDuration();
                uint256 lockTime = veToken_.MAXTIME();
                uint256 week = veToken_.WEEK();
                if (initialPoint.ts + lockTime + rewardsDuration < block.timestamp) { // reward program is surely over
                    IERC20(_token).safeTransfer(_receiver, _amount);
                } else {
                    IERC20(_token).safeTransfer(_receiver, toTransfer);
                    uint256 unlockDate = 
                        (initialPoint.ts + lockTime) / week * week <= block.timestamp ? // if we are between 100 and 101 week
                        block.timestamp + 2 * rewardsDuration : 
                        initialPoint.ts + lockTime;
                    veToken_.createLockFor(_receiver, toLock, unlockDate);
                }

            } else {
                require(unlockTime > block.timestamp, "withdraw the lock first");
                IERC20(_token).safeTransfer(_receiver, toTransfer);
                veToken_.increaseAmountFor(_receiver, toLock);
            }
        }
    }

    function _chargeFeesOnDeposit(uint256 _amount)
        internal 
        virtual
        returns (uint256 _sumWithoutFee)
    {
        uint256 bps = depositFeeBps;
        if (bps > 0) {
            uint256 _fee = bps * _amount / 10000;
            stakeToken.safeTransferFrom(_msgSender(), depositFeeReceiver, _fee);
            _sumWithoutFee = _amount - _fee;

        } else {
            _sumWithoutFee = _amount;
        }
    }

    function _setFeeReceiversTokensToBeChargedOfFees(uint256 _index, address _rewardsToken, bool _status) internal {
        feeReceivers[_index].isTokenAllowedToBeChargedOfFees[_rewardsToken] = _status;
    }

    function _getEarnedAmountFromExternalProtocol(
        address _user, 
        uint256 _index
    ) internal virtual returns(uint256 vaultEarned);
    function _harvestFromExternalProtocol() internal virtual;
    function _depositToExternalProtocol(uint256 _amount, address _from) internal virtual;
    function _withdrawFromExternalProtocol(uint256 _amount, address _to) internal virtual;

}
