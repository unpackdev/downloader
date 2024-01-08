//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./IiToken.sol";
import "./IRewardDistributorV3.sol";
import "./IPriceOracle.sol";

import "./Initializable.sol";
import "./Ownable.sol";
import "./SafeRatioMath.sol";
import "./Controller.sol";

/**
 * @title dForce's lending reward distributor Contract
 * @author dForce
 */
contract RewardDistributorV3 is Initializable, Ownable, IRewardDistributorV3 {
    using SafeRatioMath for uint256;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice the controller
    Controller public controller;

    /// @notice the global Reward distribution speed
    uint256 public globalDistributionSpeed;

    /// @notice the Reward distribution speed of each iToken
    mapping(address => uint256) public distributionSpeed;

    /// @notice the Reward distribution factor of each iToken, 1.0 by default. stored as a mantissa
    mapping(address => uint256) public distributionFactorMantissa;

    struct DistributionState {
        // Token's last updated index, stored as a mantissa
        uint256 index;
        // The block number the index was last updated at
        uint256 block;
    }

    /// @notice the Reward distribution supply state of each iToken
    mapping(address => DistributionState) public distributionSupplyState;
    /// @notice the Reward distribution borrow state of each iToken
    mapping(address => DistributionState) public distributionBorrowState;

    /// @notice the Reward distribution state of each account of each iToken
    mapping(address => mapping(address => uint256))
        public distributionSupplierIndex;
    /// @notice the Reward distribution state of each account of each iToken
    mapping(address => mapping(address => uint256))
        public distributionBorrowerIndex;

    /// @notice the Reward distributed into each account
    mapping(address => uint256) public reward;

    /// @notice the Reward token address
    address public rewardToken;

    /// @notice whether the reward distribution is paused
    bool public paused;

    /// @notice the Reward distribution speed supply side of each iToken
    mapping(address => uint256) public distributionSupplySpeed;

    /// @notice the global Reward distribution speed for supply
    uint256 public globalDistributionSupplySpeed;

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(
            address(controller) == msg.sender,
            "onlyController: caller is not the controller"
        );
        _;
    }

    /**
     * @notice Initializes the contract.
     */
    function initialize(Controller _controller) external initializer {
        require(
            address(_controller) != address(0),
            "initialize: controller address should not be zero address!"
        );
        __Ownable_init();
        controller = _controller;
        paused = true;
    }

    /**
     * @notice set reward token address
     * @dev Admin function, only owner can call this
     * @param _newRewardToken the address of reward token
     */
    function _setRewardToken(address _newRewardToken)
        external
        override
        onlyOwner
    {
        address _oldRewardToken = rewardToken;
        require(
            _newRewardToken != address(0) && _newRewardToken != _oldRewardToken,
            "Reward token address invalid"
        );
        rewardToken = _newRewardToken;
        emit NewRewardToken(_oldRewardToken, _newRewardToken);
    }

    /**
     * @notice Add the iToken as receipient
     * @dev Admin function, only controller can call this
     * @param _iToken the iToken to add as recipient
     * @param _distributionFactor the distribution factor of the recipient
     */
    function _addRecipient(address _iToken, uint256 _distributionFactor)
        external
        override
        onlyController
    {
        distributionFactorMantissa[_iToken] = _distributionFactor;
        distributionSupplyState[_iToken] = DistributionState({
            index: 0,
            block: block.number
        });
        distributionBorrowState[_iToken] = DistributionState({
            index: 0,
            block: block.number
        });

        emit NewRecipient(_iToken, _distributionFactor);
    }

    /**
     * @notice Pause the reward distribution
     * @dev Admin function, pause will set global speed to 0 to stop the accumulation
     */
    function _pause() external override onlyOwner {
        // Set the global distribution speed to 0 to stop accumulation
        address[] memory _iTokens = controller.getAlliTokens();
        uint256 _len = _iTokens.length;
        for (uint256 i = 0; i < _len; i++) {
            _setDistributionBorrowSpeed(_iTokens[i], 0);
            _setDistributionSupplySpeed(_iTokens[i], 0);
        }

        _refreshGlobalDistributionSpeeds();

        _setPaused(true);
    }

    /**
     * @notice Unpause and set distribution speeds
     * @dev Admin function
     * @param _borrowiTokens The borrow asset array
     * @param _borrowSpeeds  The borrow speed array
     * @param _supplyiTokens The supply asset array
     * @param _supplySpeeds  The supply speed array
     */
    function _unpause(
        address[] calldata _borrowiTokens,
        uint256[] calldata _borrowSpeeds,
        address[] calldata _supplyiTokens,
        uint256[] calldata _supplySpeeds
    ) external override onlyOwner {
        _setPaused(false);

        _setDistributionSpeedsInternal(
            _borrowiTokens,
            _borrowSpeeds,
            _supplyiTokens,
            _supplySpeeds
        );

        _refreshGlobalDistributionSpeeds();
    }

    /**
     * @notice Pause/Unpause the reward distribution
     * @dev Admin function
     * @param _paused whether to pause/unpause the distribution
     */
    function _setPaused(bool _paused) internal {
        paused = _paused;
        emit Paused(_paused);
    }

    /**
     * @notice Set distribution speeds
     * @dev Admin function, will fail when paused
     * @param _borrowiTokens The borrow asset array
     * @param _borrowSpeeds  The borrow speed array
     * @param _supplyiTokens The supply asset array
     * @param _supplySpeeds  The supply speed array
     */
    function _setDistributionSpeeds(
        address[] calldata _borrowiTokens,
        uint256[] calldata _borrowSpeeds,
        address[] calldata _supplyiTokens,
        uint256[] calldata _supplySpeeds
    ) external onlyOwner {
        require(!paused, "Can not change speeds when paused");

        _setDistributionSpeedsInternal(
            _borrowiTokens,
            _borrowSpeeds,
            _supplyiTokens,
            _supplySpeeds
        );

        _refreshGlobalDistributionSpeeds();
    }

    function _setDistributionSpeedsInternal(
        address[] memory _borrowiTokens,
        uint256[] memory _borrowSpeeds,
        address[] memory _supplyiTokens,
        uint256[] memory _supplySpeeds
    ) internal {
        _setDistributionBorrowSpeedsInternal(_borrowiTokens, _borrowSpeeds);
        _setDistributionSupplySpeedsInternal(_supplyiTokens, _supplySpeeds);
    }

    /**
     * @notice Set borrow distribution speeds
     * @dev Admin function, will fail when paused
     * @param _iTokens The borrow asset array
     * @param _borrowSpeeds  The borrow speed array
     */
    function _setDistributionBorrowSpeeds(
        address[] calldata _iTokens,
        uint256[] calldata _borrowSpeeds
    ) external onlyOwner {
        require(!paused, "Can not change borrow speeds when paused");

        _setDistributionBorrowSpeedsInternal(_iTokens, _borrowSpeeds);

        _refreshGlobalDistributionSpeeds();
    }

    /**
     * @notice Set supply distribution speeds
     * @dev Admin function, will fail when paused
     * @param _iTokens The supply asset array
     * @param _supplySpeeds The supply speed array
     */
    function _setDistributionSupplySpeeds(
        address[] calldata _iTokens,
        uint256[] calldata _supplySpeeds
    ) external onlyOwner {
        require(!paused, "Can not change supply speeds when paused");

        _setDistributionSupplySpeedsInternal(_iTokens, _supplySpeeds);

        _refreshGlobalDistributionSpeeds();
    }

    function _refreshGlobalDistributionSpeeds() internal {
        address[] memory _iTokens = controller.getAlliTokens();
        uint256 _len = _iTokens.length;
        uint256 _borrowSpeed;
        uint256 _supplySpeed;
        for (uint256 i = 0; i < _len; i++) {
            _borrowSpeed = _borrowSpeed.add(distributionSpeed[_iTokens[i]]);
            _supplySpeed = _supplySpeed.add(
                distributionSupplySpeed[_iTokens[i]]
            );
        }

        globalDistributionSpeed = _borrowSpeed;
        globalDistributionSupplySpeed = _supplySpeed;

        emit GlobalDistributionSpeedsUpdated(_borrowSpeed, _supplySpeed);
    }

    function _setDistributionBorrowSpeedsInternal(
        address[] memory _iTokens,
        uint256[] memory _borrowSpeeds
    ) internal {
        require(
            _iTokens.length == _borrowSpeeds.length,
            "Length of _iTokens and _borrowSpeeds mismatch"
        );

        uint256 _len = _iTokens.length;
        for (uint256 i = 0; i < _len; i++) {
            _setDistributionBorrowSpeed(_iTokens[i], _borrowSpeeds[i]);
        }
    }

    function _setDistributionSupplySpeedsInternal(
        address[] memory _iTokens,
        uint256[] memory _supplySpeeds
    ) internal {
        require(
            _iTokens.length == _supplySpeeds.length,
            "Length of _iTokens and _supplySpeeds mismatch"
        );

        uint256 _len = _iTokens.length;
        for (uint256 i = 0; i < _len; i++) {
            _setDistributionSupplySpeed(_iTokens[i], _supplySpeeds[i]);
        }
    }

    function _setDistributionBorrowSpeed(address _iToken, uint256 _borrowSpeed)
        internal
    {
        // iToken must have been listed
        require(controller.hasiToken(_iToken), "Token has not been listed");

        // Update borrow state before updating new speed
        _updateDistributionState(_iToken, true);

        distributionSpeed[_iToken] = _borrowSpeed;
        emit DistributionBorrowSpeedUpdated(_iToken, _borrowSpeed);
    }

    function _setDistributionSupplySpeed(address _iToken, uint256 _supplySpeed)
        internal
    {
        // iToken must have been listed
        require(controller.hasiToken(_iToken), "Token has not been listed");

        // Update supply state before updating new speed
        _updateDistributionState(_iToken, false);

        distributionSupplySpeed[_iToken] = _supplySpeed;
        emit DistributionSupplySpeedUpdated(_iToken, _supplySpeed);
    }

    /**
     * @notice Update the iToken's  Reward distribution state
     * @dev Will be called every time when the iToken's supply/borrow changes
     * @param _iToken The iToken to be updated
     * @param _isBorrow whether to update the borrow state
     */
    function updateDistributionState(address _iToken, bool _isBorrow)
        external
        override
    {
        // Skip all updates if it is paused
        if (paused) {
            return;
        }

        _updateDistributionState(_iToken, _isBorrow);
    }

    function _updateDistributionState(address _iToken, bool _isBorrow)
        internal
    {
        require(controller.hasiToken(_iToken), "Token has not been listed");

        DistributionState storage state =
            _isBorrow
                ? distributionBorrowState[_iToken]
                : distributionSupplyState[_iToken];

        uint256 _speed =
            _isBorrow
                ? distributionSpeed[_iToken]
                : distributionSupplySpeed[_iToken];

        uint256 _blockNumber = block.number;
        uint256 _deltaBlocks = _blockNumber.sub(state.block);

        if (_deltaBlocks > 0 && _speed > 0) {
            uint256 _totalToken =
                _isBorrow
                    ? IiToken(_iToken).totalBorrows()
                    : IERC20Upgradeable(_iToken).totalSupply();
            uint256 _totalDistributed = _speed.mul(_deltaBlocks);

            // Reward distributed per token since last time
            uint256 _distributedPerToken =
                _totalToken > 0 ? _totalDistributed.rdiv(_totalToken) : 0;

            state.index = state.index.add(_distributedPerToken);
        }

        state.block = _blockNumber;
    }

    /**
     * @notice Update the account's Reward distribution state
     * @dev Will be called every time when the account's supply/borrow changes
     * @param _iToken The iToken to be updated
     * @param _account The account to be updated
     * @param _isBorrow whether to update the borrow state
     */
    function updateReward(
        address _iToken,
        address _account,
        bool _isBorrow
    ) external override {
        // Skip all updates if it is paused
        if (paused) {
            return;
        }

        _updateReward(_iToken, _account, _isBorrow);
    }

    function _updateReward(
        address _iToken,
        address _account,
        bool _isBorrow
    ) internal {
        require(_account != address(0), "Invalid account address!");
        require(controller.hasiToken(_iToken), "Token has not been listed");

        uint256 _iTokenIndex;
        uint256 _accountIndex;
        uint256 _accountBalance;
        if (_isBorrow) {
            _iTokenIndex = distributionBorrowState[_iToken].index;
            _accountIndex = distributionBorrowerIndex[_iToken][_account];
            _accountBalance = IiToken(_iToken).borrowBalanceStored(_account);

            // Update the account state to date
            distributionBorrowerIndex[_iToken][_account] = _iTokenIndex;
        } else {
            _iTokenIndex = distributionSupplyState[_iToken].index;
            _accountIndex = distributionSupplierIndex[_iToken][_account];
            _accountBalance = IERC20Upgradeable(_iToken).balanceOf(_account);

            // Update the account state to date
            distributionSupplierIndex[_iToken][_account] = _iTokenIndex;
        }

        uint256 _deltaIndex = _iTokenIndex.sub(_accountIndex);
        uint256 _amount = _accountBalance.rmul(_deltaIndex);

        if (_amount > 0) {
            reward[_account] = reward[_account].add(_amount);

            emit RewardDistributed(_iToken, _account, _amount, _accountIndex);
        }
    }

    /**
     * @notice Update reward accrued in iTokens by the holders regardless of paused or not
     * @param _holders The account to update
     * @param _iTokens The _iTokens to update
     */
    function updateRewardBatch(
        address[] memory _holders,
        address[] memory _iTokens
    ) public override {
        // Update rewards for all _iTokens for holders
        for (uint256 i = 0; i < _iTokens.length; i++) {
            address _iToken = _iTokens[i];
            _updateDistributionState(_iToken, false);
            _updateDistributionState(_iToken, true);
            for (uint256 j = 0; j < _holders.length; j++) {
                _updateReward(_iToken, _holders[j], false);
                _updateReward(_iToken, _holders[j], true);
            }
        }
    }

    /**
     * @notice Update reward accrued in iTokens by the holders regardless of paused or not
     * @param _holders The account to update
     * @param _iTokens The _iTokens to update
     * @param _isBorrow whether to update the borrow state
     */
    function _updateRewards(
        address[] memory _holders,
        address[] memory _iTokens,
        bool _isBorrow
    ) internal {
        // Update rewards for all _iTokens for holders
        for (uint256 i = 0; i < _iTokens.length; i++) {
            address _iToken = _iTokens[i];
            _updateDistributionState(_iToken, _isBorrow);
            for (uint256 j = 0; j < _holders.length; j++) {
                _updateReward(_iToken, _holders[j], _isBorrow);
            }
        }
    }

    /**
     * @notice Claim reward accrued in iTokens by the holders
     * @param _holders The account to claim for
     * @param _iTokens The _iTokens to claim from
     */
    function claimReward(address[] memory _holders, address[] memory _iTokens)
        public
        override
    {
        updateRewardBatch(_holders, _iTokens);

        // Withdraw all reward for all holders
        for (uint256 j = 0; j < _holders.length; j++) {
            address _account = _holders[j];
            uint256 _reward = reward[_account];
            if (_reward > 0) {
                reward[_account] = 0;
                IERC20Upgradeable(rewardToken).safeTransfer(_account, _reward);
            }
        }
    }

    /**
     * @notice Claim reward accrued in iTokens by the holders
     * @param _holders The account to claim for
     * @param _suppliediTokens The _suppliediTokens to claim from
     * @param _borrowediTokens The _borrowediTokens to claim from
     */
    function claimRewards(address[] memory _holders, address[] memory _suppliediTokens, address[] memory _borrowediTokens)
        external
        override
    {
        _updateRewards(_holders, _suppliediTokens, false);
        _updateRewards(_holders, _borrowediTokens, true);

        // Withdraw all reward for all holders
        for (uint256 j = 0; j < _holders.length; j++) {
            address _account = _holders[j];
            uint256 _reward = reward[_account];
            if (_reward > 0) {
                reward[_account] = 0;
                IERC20Upgradeable(rewardToken).safeTransfer(_account, _reward);
            }
        }
    }

    /**
     * @notice Claim reward accrued in all iTokens by the holders
     * @param _holders The account to claim for
     */
    function claimAllReward(address[] memory _holders) external override {
        claimReward(_holders, controller.getAlliTokens());
    }
}
