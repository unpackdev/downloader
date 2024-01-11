// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./Address.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./IVotingEscrow.sol";
import "./IDillGauge.sol";
import "./IGaugeProxy.sol";
import "./IMinter.sol";
import "./IFeeDistributor.sol";
import "./IFeeHandler.sol";
import "./IUpgradeSource.sol";
import "./IVault.sol";
import "./EternalStorage.sol";
import "./Errors.sol";
import "./SafeTransferLib.sol";
import "./GovernableInit.sol";

/// @notice Beluga VeManager (Dill-like gauges)
/// @author Chainvisions
/// @notice A contract for managing veToken locking and gauge farming/boosting.

contract VeManagerDillLike is GovernableInit, IUpgradeSource, EternalStorage {
    using SafeTransferLib for IERC20;

    /// @notice Info for each reward gauge.
    struct GaugeInfo {
        uint16 lockNumerator;  // Percentage of rewards on this gauge to lock.
        uint16 kickbackNumerator;    // Percentage of rewards to distribute to the kickback pool.
        address strategy;   // Permitted strategy contract for using this gauge.
        address gauge;      // Gauge contract of the token.
    }

    /// @notice Mapping for information on each reward gauge.
    mapping(address => GaugeInfo) public gaugeInfo;

    /// @notice Addresses permitted to handle veToken voting power.
    mapping(address => bool) public governors;

    mapping(address => bool) private infoExistsForGauge;

    /// @notice Emitted when a new implementation upgrade is queued.
    event UpgradeAnnounced(address newImplementation);

    modifier onlyGovernors {
        _require(
            msg.sender == governance()
            || governors[msg.sender],
            Errors.GOVERNORS_ONLY
        );
        _;
    }

    /// @notice Initializes the VeManager contract.
    /// @param _store Storage contract for access control.
    /// @param _MAX_LOCK_TIME Max time for locking tokens into the escrow.
    /// @param _escrow veToken reward escrow for locking.
    /// @param _controller veToken Gauge Controller for casting votes.
    function __Manager_init(
        address _store,
        uint256 _MAX_LOCK_TIME,
        address _escrow,
        address _controller
    ) external initializer {
        __Governable_init_(_store);

        // Set max lock time.
        _setMaxLockTime(_MAX_LOCK_TIME);

        // Assign state.
        _setVotingEscrow(_escrow);
        _setRewardToken(IVotingEscrow(_escrow).token());
        _setGaugeController(_controller);
        _setUpgradeTimelock(12 hours);
    }

    /// @notice Locks reward tokens for veTokens.
    /// @param _amount Amount of tokens to lock.
    function lockTokens(uint256 _amount) external onlyGovernors {
        _lockRewards(_amount);
    }

    /// @notice Locks all reward tokens held for veTokens.
    function lockAllTokens() external onlyGovernors {
        _lockRewards(rewardToken().balanceOf(address(this)));
    }

    /// @notice Withdraws the veToken lock.
    function withdrawLock() external onlyGovernors {
        votingEscrow().withdraw();
        _setVeTokenLockActive(false);
    }

    /// @notice Votes for a specific reward gauge weight.
    /// @param _gauges Gauges to vote for the weight of.
    /// @param _weights Reward weights of the gauges.
    function voteForGauge(address[] calldata _gauges, uint256[] calldata _weights) external onlyGovernors {
        gaugeController().vote(_gauges, _weights);
    }

    /// @notice Executes a transaction on the VeMananger. Governance only.
    /// @param _to Address to call to.
    /// @param _value Value to call the address with.
    /// @param _data Data to call the address with.
    /// @return Whether or not the call succeeded and the return data.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyGovernance returns (bool, bytes memory) {
        // Execute the transaction
        (bool success, bytes memory result) = _to.call{value: _value}(_data);

        // Return the results
        return (success, result);
    }

    /// @notice Deposits tokens into the VeManager contract.
    /// @param _token Token to deposit into the VeManager.
    /// @param _amount Amount of tokens to deposit.
    function depositGaugeTokens(address _token, uint256 _amount) external {
        // Read gauge data and store for reading the data of.
        GaugeInfo memory gaugeParams = gaugeInfo[_token];

        // Check if caller is the gauge's permitted strategy.
        _require(msg.sender == gaugeParams.strategy, Errors.CALLER_NOT_STRATEGY);

        // We can now transfer the tokens from the strategy and stake.
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeApprove(gaugeParams.gauge, 0);
        IERC20(_token).safeApprove(gaugeParams.gauge, _amount);

        IDillGauge(gaugeParams.gauge).deposit(_amount);
    }

    /// @notice Withdraws tokens from the VeManager contract.
    /// @param _token Token to withdraw from the VeManager.
    /// @param _amount Amount to withdraw from the contract.
    function withdrawGaugeTokens(address _token, uint256 _amount) external {
        // Read gauge data and store for reading the data of.
        GaugeInfo memory gaugeParams = gaugeInfo[_token];

        // Check if caller is the gauge's permitted strategy.
        _require(msg.sender == gaugeParams.strategy, Errors.CALLER_NOT_STRATEGY);

        // We can now the transfer the gauge tokens to the strategy.
        IDillGauge(gaugeParams.gauge).withdraw(_amount);
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice Withdraws all tokens from the VeManager contract.
    /// @param _token Token to withdraw all stake from the gauge of.
    function divestAllGaugeTokens(address _token) external {
        // Read gauge data and store for reading the data of.
        GaugeInfo memory gaugeParams = gaugeInfo[_token];

        // Check if caller is the gauge's permitted strategy.
        _require(msg.sender == gaugeParams.strategy, Errors.CALLER_NOT_STRATEGY);

        // We can now divest the gauge tokens and send them to the strategy.
        IDillGauge(gaugeParams.gauge).exit();
        IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    /// @notice Claims rewards from a specified gauge and sends to the strategy.
    /// @param _token Token to claim the rewards from the gauge contract of.
    function claimGaugeRewards(address _token) external {
        // Read gauge data and store for reading the data of.
        GaugeInfo memory gaugeParams = gaugeInfo[_token];
        IERC20 _rewardToken = rewardToken();

        // Check if caller is the gauge's permitted strategy.
        _require(msg.sender == gaugeParams.strategy, Errors.CALLER_NOT_STRATEGY);

        // We can now collect and distribute any reward tokens earned.
        IDillGauge(gaugeParams.gauge).getReward();

        uint256 gaugeEarnings = _rewardToken.balanceOf(address(this));
        if(gaugeEarnings > 0) {
            uint256 toLock = 0;
            uint256 kickback = 0;
            if(gaugeParams.lockNumerator > 0) {
                toLock = (gaugeEarnings * gaugeParams.lockNumerator) / 10000;
                _lockRewards(toLock);
            }

            if(gaugeParams.kickbackNumerator > 0) {
                IVault _kickbackPool = kickbackPool();
                kickback = (gaugeEarnings * gaugeParams.kickbackNumerator) / 10000;
                _rewardToken.safeTransfer(address(_kickbackPool), kickback);
                _kickbackPool.notifyRewardAmount(address(_rewardToken), kickback);
            }

            _rewardToken.safeTransfer(msg.sender, (gaugeEarnings - (toLock + kickback)));
        }
    }

    /// @notice Claims earned fees from the FeeDistributor.
    function claimEarnedFees() external {
        IFeeDistributor _feeDistributor = feeDistributor();
        address handlerAddress = address(feeHandler());
        address[] memory rewardTokens = _feeDistributor.tokens();
        uint256[] memory rewardBalances = new uint256[](rewardTokens.length);

        // Perform claim.
        _feeDistributor.claim();

        // Send rewards to the handler.
        if(handlerAddress != address(0)) {
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                address reward = rewardTokens[i];
                uint256 rewardBalance = IERC20(rewardTokens[i]).balanceOf(address(this));
                rewardBalances[i] = rewardBalance;

                IERC20(reward).safeTransfer(handlerAddress, rewardBalance);
            }
            IFeeHandler(handlerAddress).handleFees(rewardBalances);
        }
    }

    /// @notice Finalizes or cancels upgrades by setting the next implementation address to 0.
    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    /// @notice Whether or not the proxy should upgrade.
    /// @return If the proxy can be upgraded and the new implementation address.
    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
                && block.timestamp > nextImplementationTimestamp()
                && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /// @notice Total amount of tokens staked in a specific gauge.
    /// @param _token Token to fetch the gauge stake of.
    /// @return The amount of `_token` staked into its respective gauge.
    function totalStakeForGauge(address _token) external view returns (uint256) {
        return IDillGauge(gaugeInfo[_token].gauge).balanceOf(address(this));
    }

    /// @notice Schedules an upgrade to the vault.
    /// @param _impl Address of the new implementation.
    function scheduleUpgrade(address _impl) public onlyGovernance {
        _setNextImplementation(_impl);
        _setNextImplementationTimestamp(block.timestamp + upgradeTimelock());
        emit UpgradeAnnounced(_impl);
    }

    /// @notice Recovers a specified token from the VeManager contract.
    /// @param _token Token to recover from the manager.
    /// @param _amount Amount to recover from the manager.
    function recoverToken(
        address _token, 
        uint256 _amount
    ) public onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    /// @notice Adds a new gauge to the VeManager contract.
    /// @param _token Address of the token to add.
    /// @param _strategy Strategy that is permitted to use this gauge.
    /// @param _gauge Gauge of the token.
    /// @param _lockNumerator Percentage of gauge rewards to lock into veTokens.
    function addGauge(
        address _token,
        address _strategy,
        address _gauge,
        uint16 _lockNumerator,
        uint16 _kickbackNumerator
    ) public onlyGovernors {
        _require(!infoExistsForGauge[_token], Errors.GAUGE_INFO_ALREADY_EXISTS);
        // Create new GaugeInfo struct.
        GaugeInfo memory gaugeParams;
        gaugeParams.gauge = _gauge;
        gaugeParams.strategy = _strategy;
        gaugeParams.lockNumerator = _lockNumerator;
        gaugeParams.kickbackNumerator = _kickbackNumerator;

        // Set info.
        gaugeInfo[_token] = gaugeParams;
        infoExistsForGauge[_token] = true;
    }

    /// @notice Increases the VeManager's lock time.
    /// @param _increaseBy The time to increase the lock time by.
    function increaseLockTime(
        uint256 _increaseBy
    ) public onlyGovernors {
        IVotingEscrow _votingEscrow = votingEscrow();

        uint256 lockEnd = _votingEscrow.locked__end(address(this));
        _votingEscrow.increase_unlock_time((lockEnd + _increaseBy));
    }

    /// @notice Sets the strategy of a specified gauge.
    /// @param _token Token of the gauge to set the strategy of.
    /// @param _newStrategy New strategy for the gauge.
    function setGaugeStrategy(
        address _token,
        address _newStrategy
    ) public onlyGovernors {
        _require(infoExistsForGauge[_token], Errors.GAUGE_NON_EXISTENT);

        // Set strategy.
        GaugeInfo storage gaugeParams = gaugeInfo[_token];
        gaugeParams.strategy = _newStrategy;
    }

    /// @notice Sets the lock numerator of a specified gauge.
    /// @param _token Token of the gauge to set the strategy of.
    /// @param _newLockNumerator New lock numerator for the gauge.
    function setGaugeLockNumerator(
        address _token,
        uint16 _newLockNumerator
    ) public onlyGovernors {
        _require(infoExistsForGauge[_token], Errors.GAUGE_NON_EXISTENT);

        // Set lock numerator.
        GaugeInfo storage gaugeParams = gaugeInfo[_token];
        gaugeParams.lockNumerator = _newLockNumerator;
    }

    /// @notice Sets the kickback numerator of a specified gauge.
    /// @param _token Token of the gauge to set the kickback numerator of.
    /// @param _newKickbackNumerator New kickback numerator of the gauge.
    function setGaugeKickbackNumerator(
        address _token,
        uint16 _newKickbackNumerator
    ) public onlyGovernors {
        _require(infoExistsForGauge[_token], Errors.GAUGE_NON_EXISTENT);

        // Set kickback numerator.
        GaugeInfo storage gaugeParams = gaugeInfo[_token];
        gaugeParams.kickbackNumerator = _newKickbackNumerator;
    }

    /// @notice Sets the FeeDistributor contract for claiming fees.
    /// @param _feeDistributor FeeDistributor contract.
    function setFeeDistributor(
        address _feeDistributor
    ) public onlyGovernors {
        _setFeeDistributor(_feeDistributor);
    }

    /// @notice Sets the FeeHandler contract for fee conversion and handling.
    /// @param _feeHandler FeeHandler contract.
    function setFeeHandler(
        address _feeHandler
    ) public onlyGovernors {
        _setFeeHandler(_feeHandler);
    }

    /// @notice Sets the kickback pool contract for kickback rewards.
    /// @param _kickbackPool Kickback pool contract.
    function setKickbackPool(
        address _kickbackPool
    ) public onlyGovernors {
        _setKickbackPool(_kickbackPool);
    }

    /// @notice Adds a governor to the VeManager.
    /// @param _governor Governor to add from the manager.
    function addGovernor(
        address _governor
    ) public onlyGovernance {
        governors[_governor] = true;
    }

    /// @notice Removes a governor from the VeManager.
    /// @param _governor Governor to remove from the manager.
    function removeGovernor(
        address _governor
    ) public onlyGovernance {
        governors[_governor] = false;
    }

    /// @notice Amount of veTokens held by the VeManager.
    function netVeAssets() public view returns (uint256) {
        return IERC20(address(votingEscrow())).balanceOf(address(this));
    }

    /// @notice The VeManager's veToken lock expiration.
    function lockExpiration() public view returns (uint256) {
        return votingEscrow().locked__end(address(this));
    }

    /// @notice Next implementation contract for the proxy.
    function nextImplementation() public view returns (address) {
        return _getAddress("nextImplementation");
    }

    /// @notice Timestamp of when the next upgrade can be executed.
    function nextImplementationTimestamp() public view returns (uint256) {
        return _getUint256("nextImplementationTimestamp");
    }

    /// @notice Timelock for contract upgrades.
    function upgradeTimelock() public view returns (uint256) {
        return _getUint256("upgradeTimelock");
    }

    /// @notice Max lock time for locking for veTokens.
    function maxLockTime() public view returns (uint256) {
        return _getUint256("maxLockTime");
    }

    /// @notice veToken VotingEscrow contract.
    function votingEscrow() public view returns (IVotingEscrow) {
        return IVotingEscrow(_getAddress("votingEscrow"));
    }

    /// @notice Reward token to farm in gauges and lock.
    function rewardToken() public view returns (IERC20) {
        return IERC20(_getAddress("rewardToken"));
    }

    /// @notice Gauge controller contract for voting.
    function gaugeController() public view returns (IGaugeProxy) {
        return IGaugeProxy(_getAddress("gaugeController"));
    }

    /// @notice Fee distributor contract for claiming fees. Optional.
    function feeDistributor() public view returns (IFeeDistributor) {
        return IFeeDistributor(_getAddress("feeDistributor"));
    }

    /// @notice Beluga fee handler for handling claimed fees. Optional.
    function feeHandler() public view returns (IFeeHandler) {
        return IFeeHandler(_getAddress("feeHandler"));
    }

    /// @notice Whether or not a veToken lock is active on the escrow.
    function veTokenLockActive() public view returns (bool) {
        return _getBool("veTokenLockActive");
    }

    /// @notice Kickback pool for distributing kickback rewards.
    function kickbackPool() public view returns (IVault) {
        return IVault(_getAddress("kickbackPool"));
    }

    function _lockRewards(uint256 _amountToLock) internal {
        IERC20 _rewardToken = rewardToken();
        address escrowAddress = address(votingEscrow());

        _rewardToken.safeApprove(escrowAddress, 0);
        _rewardToken.safeApprove(escrowAddress, _amountToLock);

        if(veTokenLockActive()) {
            // We can simply increase the amount.
            IVotingEscrow(escrowAddress).increase_amount(_amountToLock);
        } else {
            // We need to create a new lock.
            IVotingEscrow(escrowAddress).create_lock(_amountToLock, (block.timestamp + maxLockTime()));
            _setVeTokenLockActive(true);
        }
    }

    function _setNextImplementation(address _address) internal {
        _setAddress("nextImplementation", _address);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        _setUint256("nextImplementationTimestamp", _value);
    }

    function _setUpgradeTimelock(uint256 _value) internal {
        _setUint256("upgradeTimelock", _value);
    }

    function _setMaxLockTime(uint256 _value) internal {
        _setUint256("maxLockTime", _value);
    }

    function _setVotingEscrow(address _value) internal {
        _setAddress("votingEscrow", _value);
    }

    function _setRewardToken(address _value) internal {
        _setAddress("rewardToken", _value);
    }

    function _setGaugeController(address _value) internal {
        _setAddress("gaugeController", _value);
    }

    function _setRewardMinter(address _value) internal {
        _setAddress("rewardMinter", _value);
    }

    function _setFeeDistributor(address _value) internal {
        _setAddress("feeDistributor", _value);
    }

    function _setFeeHandler(address _value) internal {
        _setAddress("feeHandler", _value);
    }

    function _setVeTokenLockActive(bool _value) internal {
        _setBool("veTokenLockActive", _value);
    }

    function _setKickbackPool(address _value) internal {
        _setAddress("kickbackPool", _value);
    }

    function findArrayItem(address[] memory _array, address _item) private pure returns (uint256) {
        for(uint256 i = 0; i < _array.length; i++) {
            if(_array[i] == _item) {
                return i;
            }
        }
        return type(uint256).max;
    }
}