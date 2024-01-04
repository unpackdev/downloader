//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./IiToken.sol";
import "./IRewardDistributor.sol";
import "./IPriceOracle.sol";

import "./Initializable.sol";
import "./Ownable.sol";
import "./SafeRatioMath.sol";
import "./Controller.sol";

/**
 * @title dForce's lending reward distributor Contract
 * @author dForce
 */
contract RewardDistributor is Initializable, Ownable, IRewardDistributor {
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
        _setGlobalDistributionSpeed(0);

        _setPaused(true);
    }

    /**
     * @notice Unpause and set global distribution speed
     * @dev Admin function
     * @param _speed The speed of Reward distribution per second
     */
    function _unpause(uint256 _speed) external override onlyOwner {
        _setPaused(false);

        _setGlobalDistributionSpeed(_speed);
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
     * @notice Sets the global distribution speed, updating each iToken's speed accordingly
     * @dev Admin function, will fail when paused
     * @param _speed The speed of Reward distribution per second
     */
    function _setGlobalDistributionSpeed(uint256 _speed)
        public
        override
        onlyOwner
    {
        require(!paused, "Can not change global speed when paused");

        globalDistributionSpeed = _speed;

        _updateDistributionSpeed();

        emit GlobalDistributionSpeedUpdated(_speed);
    }

    /**
     * @notice Update each iToken's distribution speed according to current global speed
     * @dev Only EOA can call this function
     */
    function updateDistributionSpeed() public override {
        require(msg.sender == tx.origin, "only EOA can update speeds");
        require(!paused, "Can not update speeds when paused");

        // Do the actual update
        _updateDistributionSpeed();
    }

    /**
     * @notice Internal function to update each iToken's distribution speed
     */
    function _updateDistributionSpeed() internal {
        address[] memory _iTokens = controller.getAlliTokens();
        uint256 _globalspeed = globalDistributionSpeed;
        uint256 _len = _iTokens.length;

        uint256[] memory _tokenValues = new uint256[](_len);
        uint256 _totalValue;

        // Calculates the total value and token value
        // tokenValue = tokenTotalBorrow * price * tokenDistributionFactorMantissa
        for (uint256 i = 0; i < _len; i++) {
            IiToken _token = IiToken(_iTokens[i]);

            // Update both supply and borrow state before updating new speed
            _updateDistributionState(address(_token), true);
            _updateDistributionState(address(_token), false);

            uint256 _totalBorrow = _token.totalBorrows();

            // It is okay if the underlying price is 0
            uint256 _underlyingPrice =
                IPriceOracle(controller.priceOracle()).getUnderlyingPrice(
                    address(_token)
                );

            _tokenValues[i] = _totalBorrow.mul(_underlyingPrice).rmul(
                distributionFactorMantissa[address(_token)]
            );

            _totalValue = _totalValue.add(_tokenValues[i]);
        }

        // Calculates the distribution speed for each token
        for (uint256 i = 0; i < _len; i++) {
            address _token = _iTokens[i];
            uint256 _speed =
                _totalValue > 0
                    ? _globalspeed.mul(_tokenValues[i]).div(_totalValue)
                    : 0;
            distributionSpeed[_token] = _speed;

            emit DistributionSpeedUpdated(_token, _speed);
        }
    }

    /**
     * @notice Sets the distribution factor for a iToken
     * @dev Admin function to set distribution factor for a iToken
     * @param _iToken The token to set the factor on
     * @param _newDistributionFactorMantissa The new distribution factor, scaled by 1e18
     */
    function _setDistributionFactor(
        address _iToken,
        uint256 _newDistributionFactorMantissa
    ) internal {
        // iToken must have been listed
        require(controller.hasiToken(_iToken), "Token has not been listed");

        uint256 _oldDistributionFactorMantissa =
            distributionFactorMantissa[_iToken];
        distributionFactorMantissa[_iToken] = _newDistributionFactorMantissa;

        emit NewDistributionFactor(
            _iToken,
            _oldDistributionFactorMantissa,
            _newDistributionFactorMantissa
        );
    }

    /**
     * @notice Sets the distribution factors for a list of iTokens
     * @dev Admin function to set distribution factors for a list of iTokens
     * @param _iTokens The list of tokens to set the factor on
     * @param _distributionFactors The list of distribution factors, scaled by 1e18
     */
    function _setDistributionFactors(
        address[] calldata _iTokens,
        uint256[] calldata _distributionFactors
    ) external override onlyOwner {
        require(
            _iTokens.length == _distributionFactors.length,
            "Length of _iTokens and _distributionFactors mismatch"
        );

        uint256 _len = _iTokens.length;
        for (uint256 i = 0; i < _len; i++) {
            _setDistributionFactor(_iTokens[i], _distributionFactors[i]);
        }

        // Update the distribution speed of all iTokens
        updateDistributionSpeed();
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

        uint256 _speed = distributionSpeed[_iToken];
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
     * @notice Claim reward accrued in iTokens by the holders
     * @param _holders The account to claim for
     * @param _iTokens The _iTokens to claim from
     */
    function claimReward(address[] memory _holders, address[] memory _iTokens)
        public
        override
    {
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
