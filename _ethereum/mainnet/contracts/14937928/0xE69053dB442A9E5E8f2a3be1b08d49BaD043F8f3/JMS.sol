// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.14;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./IValidatorShare.sol";
import "./IValidatorRegistry.sol";
import "./IStakeManager.sol";
import "./IJMS.sol";

contract JMS is IJMS, ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private validatorRegistry;
    address private stakeManager;
    IERC20 private polygonERC20;

    address public override treasury;
    uint8 public override feePercent;

    struct Compound {
        bool isActive;
        uint256 minReward;
        uint256 minRestake;
    }

    Compound public compoundConfig;

    /// @notice Mapping of all user ids with withdraw requests.
    mapping(address => WithdrawalRequest[]) private userWithdrawalRequests;

    /**
     * @param _validatorRegistry - Address of the validator registry
     * @param _stakeManager - Address of the stake manager
     * @param _polygonERC20 - Address of matic token on Ethereum
     * @param _treasury - Address of the treasury
     */

    constructor(
        address _validatorRegistry,
        address _stakeManager,
        address _polygonERC20,
        address _treasury
    ) ERC20("Jamon Matic Stake", "JSM") {
        validatorRegistry = _validatorRegistry;
        stakeManager = _stakeManager;
        treasury = _treasury;
        polygonERC20 = IERC20(_polygonERC20);
        compoundConfig.isActive = true;
        compoundConfig.minReward = 2 ether;
        compoundConfig.minRestake = 1 ether;

        feePercent = 10;
        polygonERC20.safeApprove(stakeManager, type(uint256).max);
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////             ***Staking Contract Interactions***    ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    /**
     * @dev Send funds to JMS contract and mints JMS to msg.sender
     * @notice Requires that msg.sender has approved _amount of MATIC to this contract
     * @param _amount - Amount of MATIC sent from msg.sender to this contract
     * @return minted Amount of JMS shares generated
     */
    function submit(uint256 _amount)
        external
        override
        whenNotPaused
        nonReentrant
        returns (uint256 minted)
    {
        require(_amount > 0, "Invalid amount");
        polygonERC20.safeTransferFrom(msg.sender, address(this), _amount);
        minted = helper_delegate_to_mint(msg.sender, _amount);
        if (compoundConfig.isActive) {
            _doCompound();
        }
    }

    /**
     * @dev Stores user's request to withdraw into WithdrawalRequest struct
     * @param _amount - Amount of JMS that is requested to withdraw
     */
    function requestWithdraw(uint256 _amount)
        external
        override
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "Invalid amount");

        (uint256 totalAmount2WithdrawInMatic, , ) = convertJMSToMatic(_amount);

        _burn(msg.sender, _amount);

        uint256 leftAmount2WithdrawInMatic = totalAmount2WithdrawInMatic;
        uint256 totalDelegated = getTotalStakeAcrossAllValidators();

        require(
            totalDelegated >= totalAmount2WithdrawInMatic,
            "Too much to withdraw"
        );

        uint256[] memory validators = IValidatorRegistry(validatorRegistry)
            .getValidators();
        uint256 preferredValidatorId = IValidatorRegistry(validatorRegistry)
            .preferredWithdrawalValidatorId();
        uint256 currentIdx = 0;
        for (; currentIdx < validators.length; ++currentIdx) {
            if (preferredValidatorId == validators[currentIdx]) break;
        }

        while (leftAmount2WithdrawInMatic > 0) {
            uint256 validatorId = validators[currentIdx];

            address validatorShare = IStakeManager(stakeManager)
                .getValidatorContract(validatorId);
            (uint256 validatorBalance, ) = getTotalStake(
                IValidatorShare(validatorShare)
            );

            uint256 amount2WithdrawFromValidator = (validatorBalance <=
                leftAmount2WithdrawInMatic)
                ? validatorBalance
                : leftAmount2WithdrawInMatic;

            IValidatorShare(validatorShare).sellVoucher_new(
                amount2WithdrawFromValidator,
                type(uint256).max
            );

            userWithdrawalRequests[msg.sender].push(
                WithdrawalRequest(
                    IValidatorShare(validatorShare).unbondNonces(address(this)),
                    IStakeManager(stakeManager).epoch() +
                        IStakeManager(stakeManager).withdrawalDelay(),
                    validatorShare
                )
            );

            leftAmount2WithdrawInMatic -= amount2WithdrawFromValidator;
            currentIdx = currentIdx + 1 < validators.length
                ? currentIdx + 1
                : 0;
        }
        if (compoundConfig.isActive) {
            _doCompound();
        }
        emit RequestWithdraw(msg.sender, _amount, totalAmount2WithdrawInMatic);
    }

    /**
     * @dev Claims tokens from validator share and sends them to the
     * address if the request is in the userWithdrawalRequests
     * @param _idx - User withdrawal request array index
     */
    function claimWithdrawal(uint256 _idx)
        external
        override
        whenNotPaused
        nonReentrant
    {
        _claimWithdrawal(msg.sender, _idx);
        if (compoundConfig.isActive) {
            _doCompound();
        }
    }

    function doCompound() external whenNotPaused nonReentrant {
        _doCompound();
    }

    function withdrawRewards(uint256 _validatorId)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(_validatorId);

        uint256 balanceBeforeRewards = polygonERC20.balanceOf(address(this));
        IValidatorShare(validatorShare).withdrawRewards();
        uint256 rewards = polygonERC20.balanceOf(address(this)) -
            balanceBeforeRewards;

        emit WithdrawRewards(_validatorId, rewards);
        return rewards;
    }

    function stakeRewardsAndDistributeFees(uint256 _validatorId)
        external
        override
        whenNotPaused
        onlyOwner
    {
        require(
            IValidatorRegistry(validatorRegistry).validatorIdExists(
                _validatorId
            ),
            "Doesn't exist in validator registry"
        );

        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(_validatorId);

        uint256 rewards = polygonERC20.balanceOf(address(this));

        require(rewards > 0, "Reward is zero");

        uint256 treasuryFees = (rewards * feePercent) / 100;

        if (treasuryFees > 0) {
            polygonERC20.safeTransfer(treasury, treasuryFees);
            emit DistributeFees(treasury, treasuryFees);
        }

        uint256 amountStaked = rewards - treasuryFees;
        IValidatorShare(validatorShare).buyVoucher(amountStaked, 0);

        emit StakeRewards(_validatorId, amountStaked);
    }

    /**
     * @dev Migrate the staked tokens to another validaor
     */
    function migrateDelegation(
        uint256 _fromValidatorId,
        uint256 _toValidatorId,
        uint256 _amount
    ) external override whenNotPaused onlyOwner {
        require(
            IValidatorRegistry(validatorRegistry).validatorIdExists(
                _fromValidatorId
            ),
            "From validator id does not exist in our registry"
        );
        require(
            IValidatorRegistry(validatorRegistry).validatorIdExists(
                _toValidatorId
            ),
            "To validator id does not exist in our registry"
        );

        IStakeManager(stakeManager).migrateDelegation(
            _fromValidatorId,
            _toValidatorId,
            _amount
        );

        emit MigrateDelegation(_fromValidatorId, _toValidatorId, _amount);
    }

    /**
     * @dev Flips the pause state
     */
    function togglePause() external override onlyOwner {
        paused() ? _unpause() : _pause();
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////            ***Helpers & Utilities***               ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    function helper_delegate_to_mint(address deposit_sender, uint256 _amount)
        internal
        returns (uint256)
    {
        (uint256 amountToMint, , ) = convertMaticToJMS(_amount);

        _mint(deposit_sender, amountToMint);
        emit Submit(deposit_sender, _amount);

        uint256 preferredValidatorId = IValidatorRegistry(validatorRegistry)
            .preferredDepositValidatorId();
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(preferredValidatorId);
        IValidatorShare(validatorShare).buyVoucher(_amount, 0);

        emit Delegate(preferredValidatorId, _amount);
        return amountToMint;
    }

    function _doCompound() internal {
        uint256 preferredValidatorId = IValidatorRegistry(validatorRegistry)
            .preferredDepositValidatorId();
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(preferredValidatorId);
        uint256 pending = IValidatorShare(validatorShare).getLiquidRewards(
            address(this)
        );
        if (pending > compoundConfig.minReward) {
            IValidatorShare(validatorShare).withdrawRewards();
        }
        uint256 rewards = polygonERC20.balanceOf(address(this));
        if (rewards > compoundConfig.minRestake) {
            uint256 treasuryFees = (rewards * feePercent) / 100;
            if (treasuryFees > 0) {
                polygonERC20.safeTransfer(treasury, treasuryFees);
                emit DistributeFees(treasury, treasuryFees);
            }

            uint256 amountStaked = rewards - treasuryFees;
            IValidatorShare(validatorShare).buyVoucher(amountStaked, 0);
            emit StakeRewards(preferredValidatorId, amountStaked);
        }
    }

    /**
     * @dev Claims tokens from validator share and sends them to the
     * address if the request is in the userWithdrawalRequests
     * @param _to - Address of the withdrawal request owner
     * @param _idx - User withdrawal request array index
     */
    function _claimWithdrawal(address _to, uint256 _idx)
        internal
        returns (uint256)
    {
        uint256 amountToClaim = 0;
        uint256 balanceBeforeClaim = polygonERC20.balanceOf(address(this));
        WithdrawalRequest[] storage userRequests = userWithdrawalRequests[_to];
        WithdrawalRequest memory userRequest = userRequests[_idx];
        require(
            IStakeManager(stakeManager).epoch() >= userRequest.requestEpoch,
            "Not able to claim yet"
        );

        IValidatorShare(userRequest.validatorAddress).unstakeClaimTokens_new(
            userRequest.validatorNonce
        );

        // swap with the last item and pop it.
        userRequests[_idx] = userRequests[userRequests.length - 1];
        userRequests.pop();

        amountToClaim =
            polygonERC20.balanceOf(address(this)) -
            balanceBeforeClaim;

        polygonERC20.safeTransfer(_to, amountToClaim);

        emit ClaimWithdrawal(_to, _idx, amountToClaim);
        return amountToClaim;
    }

    /**
     * @dev Function that converts arbitrary JMS to Matic
     * @param _balance - Balance in JMS
     * @return Balance in Matic, totalShares and totalPooledMATIC
     */
    function convertJMSToMatic(uint256 _balance)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalShares = totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalPooledMATIC = getTotalPooledMatic();
        totalPooledMATIC = totalPooledMATIC == 0 ? 1 : totalPooledMATIC;

        uint256 balanceInMATIC = (_balance * (totalPooledMATIC)) / totalShares;

        return (balanceInMATIC, totalShares, totalPooledMATIC);
    }

    /**
     * @dev Function that converts arbitrary Matic to JMS
     * @param _balance - Balance in Matic
     * @return Balance in JMS, totalShares and totalPooledMATIC
     */
    function convertMaticToJMS(uint256 _balance)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalShares = totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalPooledMatic = getTotalPooledMatic();
        totalPooledMatic = totalPooledMatic == 0 ? 1 : totalPooledMatic;

        uint256 balanceInJMS = (_balance * totalShares) / totalPooledMatic;

        return (balanceInJMS, totalShares, totalPooledMatic);
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////                 ***Setters***                      ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    /**
     * @dev Function that sets fee percent
     * @notice Callable only by manager
     * @param _feePercent - Fee percent (10 = 10%)
     */
    function setFeePercent(uint8 _feePercent) external override onlyOwner {
        require(_feePercent <= 100, "_feePercent must not exceed 100");

        feePercent = _feePercent;

        emit SetFeePercent(_feePercent);
    }

    function setTreasury(address _address) external override onlyOwner {
        treasury = _address;

        emit SetTreasury(_address);
    }

    function setCompound(
        bool _set,
        uint256 _minReward,
        uint256 _minRestake
    ) external onlyOwner {
        require(_minReward >= 1 ether  && _minRestake >= 1 gwei, "invalid mins");
        compoundConfig.isActive = _set;
        compoundConfig.minReward = _minReward;
        compoundConfig.minRestake = _minRestake;
    }

    function setValidatorRegistry(address _address)
        external
        override
        onlyOwner
    {
        validatorRegistry = _address;

        emit SetValidatorRegistry(_address);
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////                 ***Getters***                      ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////
    /**
     * @dev API for getting total stake of this contract from validatorShare
     * @param _validatorShare - Address of validatorShare contract
     * @return Total stake of this contract and MATIC -> share exchange rate
     */
    function getTotalStake(IValidatorShare _validatorShare)
        public
        view
        override
        returns (uint256, uint256)
    {
        return _validatorShare.getTotalStake(address(this));
    }

    /**
     * @dev Helper function for that returns current epoch on stake manager
     * @return Current epoch
     */
    function currentEpoch() external view returns (uint256) {
        return IStakeManager(stakeManager).epoch();
    }

    /**
     * @dev Helper function for that returns total pooled MATIC
     * @return Total pooled MATIC
     */
    function getTotalStakeAcrossAllValidators()
        public
        view
        override
        returns (uint256)
    {
        uint256 totalStake;
        uint256[] memory validators = IValidatorRegistry(validatorRegistry)
            .getValidators();
        for (uint256 i = 0; i < validators.length; ++i) {
            address validatorShare = IStakeManager(stakeManager)
                .getValidatorContract(validators[i]);
            (uint256 currValidatorShare, ) = getTotalStake(
                IValidatorShare(validatorShare)
            );

            totalStake += currValidatorShare;
        }

        return totalStake;
    }

    /**
     * @dev Function that calculates total pooled Matic
     * @return Total pooled Matic
     */
    function getTotalPooledMatic() public view override returns (uint256) {
        uint256 totalStaked = getTotalStakeAcrossAllValidators();
        return totalStaked;
    }

    /**
     * @dev Retrieves all withdrawal requests initiated by the given address
     * @param _address - Address of an user
     * @return userWithdrawalRequests array of user withdrawal requests
     */
    function getUserWithdrawalRequests(address _address)
        external
        view
        override
        returns (WithdrawalRequest[] memory)
    {
        return userWithdrawalRequests[_address];
    }

    /**
     * @dev Retrieves shares amount of a given withdrawal request
     * @param _address - Address of an user
     * @return _idx index of the withdrawal request
     */
    function getSharesAmountOfUserWithdrawalRequest(
        address _address,
        uint256 _idx
    ) external view override returns (uint256) {
        WithdrawalRequest memory userRequest = userWithdrawalRequests[_address][
            _idx
        ];
        IValidatorShare validatorShare = IValidatorShare(
            userRequest.validatorAddress
        );
        IValidatorShare.DelegatorUnbond memory unbond = validatorShare
            .unbonds_new(address(this), userRequest.validatorNonce);

        return unbond.shares;
    }

    function getPendingRewards() external view returns (uint256) {
        uint256 preferredValidatorId = IValidatorRegistry(validatorRegistry)
            .preferredDepositValidatorId();
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(preferredValidatorId);
        return IValidatorShare(validatorShare).getLiquidRewards(address(this));
    }

    function getPendingRewardsAtValidator(uint256 _validatorId)
        external
        view
        returns (uint256)
    {
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(_validatorId);
        return IValidatorShare(validatorShare).getLiquidRewards(address(this));
    }

    function getContracts()
        external
        view
        override
        returns (
            address _stakeManager,
            address _polygonERC20,
            address _validatorRegistry
        )
    {
        _stakeManager = stakeManager;
        _polygonERC20 = address(polygonERC20);
        _validatorRegistry = validatorRegistry;
    }
}
