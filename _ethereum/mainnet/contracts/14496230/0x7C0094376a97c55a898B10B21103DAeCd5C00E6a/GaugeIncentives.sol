// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.6;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Original idea and credit: 
// Curve Finance's Incentive System 
// bribe.crv.finance
// https://etherscan.io/address/0x7893bbb46613d7a4fbcc31dab4c9b823ffee1026

// Primary Author(s)
// Charlie Pyle: https://github.com/charliepyle

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

// Base Interface used to interact with a curve-style gauge system, an example of which can be found here: https://etherscan.io/address/0x3669C421b77340B2979d1A00a792CC2ee0FcE737
interface GaugeController {
    struct VotedSlope {
        uint slope;
        uint power;
        uint end;
    }
    
    struct Point {
        uint bias;
        uint slope;
    }
    
    function vote_user_slopes(address, address) external view returns (VotedSlope memory);
    function gauge_relative_weight(address) external view returns (uint);
    function last_user_vote(address, address) external view returns (uint);
    function points_weight(address, uint256) external view returns (Point memory);
    function checkpoint_gauge(address) external;
    function time_total() external view returns (uint);
}

interface erc20 { 
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract GaugeIncentives is OwnableUpgradeable, UUPSUpgradeable {
    uint constant WEEK = 86400 * 7;
    uint256 public constant DENOMINATOR = 10000; // denominates weights 10000 = 100%
    
    // Allows rewards that aren't claimable until the votes pass a certain threshold. Are redeemable at any point.
    struct LimitReward {
        uint amount;
        uint threshold; // scaled between 0 and 10000 in BPs
    }

    // Pitch Multisig with fee modeled after Votium.
    address public feeAddress;
    uint256 public platformFee;
    address public gaugeControllerAddress;
    
    // These mappings were made public, while the bribe.crv.finance implementation keeps them private.
    mapping(address => mapping(address => uint)) public currentlyClaimableRewards;
    mapping(address => mapping(address => uint)) public currentlyClaimedRewards;
    mapping(address => mapping(address => uint)) public futureClaimableRewards;
    mapping(address => mapping(address => uint)) public activePeriod;
    mapping(address => mapping(address => mapping(address => uint))) public last_user_claim;

    // users can delegate their rewards to another address (key = delegator, value = delegate)
    mapping (address => address) public delegation;

    // pending rewards are indexed with [gauge][token][user]. each user can only have one limit reward per gauge per token.
    mapping (address => mapping (address => mapping (address => LimitReward))) public pendingRewards;
    
    // list of addresses who have pushed pending rewards that should be checked on periodic update.
    mapping (address => mapping (address => address[])) public pendingRewardAddresses;
    
    mapping(address => address[]) _rewardsPerGauge;
    mapping(address => address[]) _gaugesPerReward;
    mapping(address => mapping(address => bool)) _rewardsInGauge;

    

    /* ========== INITIALIZER FUNCTION ========== */ 

    function initialize(address _feeAddress, uint256 _platformFee, address _gaugeControllerAddress) public initializer {
       __Context_init_unchained();
       __Ownable_init_unchained();
       feeAddress = _feeAddress;
       platformFee = _platformFee;
       gaugeControllerAddress = _gaugeControllerAddress;
    }
    /* ========== END INITIALIZER FUNCTION ========== */ 

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */
    
    function rewardsPerGauge(address _gauge) external view returns (address[] memory) {
        return _rewardsPerGauge[_gauge];
    }
    
    function gaugesPerReward(address _reward) external view returns (address[] memory) {
        return _gaugesPerReward[_reward];
    }

    /**
     * @notice Returns a list of pending limit orders for a given gauge and reward token.
     * @param _gauge The token underlying the supported gauge.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return pendingLRs List of pending limit rewards.
     */
    function pendingLimitRewards(address _gauge, address _rewardToken) external view returns (LimitReward[] memory pendingLRs) {
        uint numPendingLimitRewards = pendingRewardAddresses[_gauge][_rewardToken].length;

        LimitReward[] memory _pendingLRs = new LimitReward[](numPendingLimitRewards);

        for (uint i = 0; i < numPendingLimitRewards; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_rewardToken][i];
            _pendingLRs[i] = pendingRewards[_gauge][_rewardToken][pendingRewardAddress];
        }

        return _pendingLRs;
    }

    /**
     * @notice Goes through every pending reward on a [gauge][token] pair and calculates the pending rewards.
     * @param _gauge The token underlying the supported gauge.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return amount the updated 
     */
    function calculatePendingRewards(address _gauge, address _rewardToken) public view returns (uint amount) {
        uint _amount = 0;

        for (uint i = 0; i < pendingRewardAddresses[_gauge][_rewardToken].length; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_rewardToken][i];
            LimitReward memory lr = pendingRewards[_gauge][_rewardToken][pendingRewardAddress];

            uint currentGaugeWeight = GaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);

            // only include amounts for fulfilled orders (threshold is scaled up 10**14 to work with gauge_relative_weight)
            if (currentGaugeWeight >= (lr.threshold * 10**14)) {
                _amount += lr.amount;
            }

        }
        return _amount;
    }
    
    /**
     * @notice Provides a user their quoted share of future rewards. If the contract's not synced with the controller, it'll reference the updated period.
     * @param _user Reward owner
     * @param _gauge The gauge being referenced by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return _amount The amount currently claimable
     */
    function claimable(address _user, address _gauge, address _rewardToken) external view returns (uint) {
        uint _amount = 0;
        uint _currentPeriod = GaugeController(gaugeControllerAddress).time_total(); // get the current gauge period
        
        uint _checkpointedPeriod = activePeriod[_gauge][_rewardToken]; // reference our current bookmarked period

        // if now is past the active period, they're definitely eligible to claim, so we return indiv/total * (future + current)
        if (_currentPeriod > _checkpointedPeriod) {
            
            uint _totalWeight = GaugeController(gaugeControllerAddress).points_weight(_gauge, _currentPeriod).bias; // bookmark the total slopes at the weds of current period
            GaugeController.VotedSlope memory _individualSlope = GaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);

            // avoids a divide by zero problem. curve-style gauge controllers don't allow votes to kick in until the following period, so we don't need to track that ourselves
            if (_totalWeight > 0 && _individualSlope.end > 0) {
                uint _individualWeight = (_individualSlope.end - _currentPeriod) * _individualSlope.slope;

                uint _pendingRewardsAmount = calculatePendingRewards(_gauge, _rewardToken);

                // includes rewards that will certainly be available next period, rewards that will since be qualified after the next period, and removes rewards that have since been claimed.
                uint _totalRewards = currentlyClaimableRewards[_gauge][_rewardToken] + _pendingRewardsAmount + futureClaimableRewards[_gauge][_rewardToken] - currentlyClaimedRewards[_gauge][_rewardToken];
                _amount = _totalRewards * _individualWeight / _totalWeight;
            }   
        }
        else {
            // otherwise, we need to make sure they haven't claimed in the past week and that they haven't voted in the past week
            uint _votingWeek = _checkpointedPeriod - WEEK;
            if (last_user_claim[_user][_gauge][_rewardToken] < _votingWeek) {
                uint _totalWeight = GaugeController(gaugeControllerAddress).points_weight(_gauge, _checkpointedPeriod).bias; // bookmark the total slopes at the weds of current period
                GaugeController.VotedSlope memory _individualSlope = GaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);
                if (_totalWeight > 0 && _individualSlope.end > 0) {
                    
                    uint _individualWeight = (_individualSlope.end - _checkpointedPeriod) * _individualSlope.slope;
                    uint _totalRewards = currentlyClaimableRewards[_gauge][_rewardToken];
                    _amount = _totalRewards * _individualWeight / _totalWeight;
                }  
            }
        }
        
        return _amount;
        
    }

    /* ========== END EXTERNAL VIEW FUNCTIONS ========== */

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Referenced from Gnosis' DelegateRegistry, found here: https://github.com/gnosis/delegate-registry/blob/main/contracts/DelegateRegistry.sol
     * @dev Sets a delegate for the msg.sender. Every msg.sender serves as a unique key.
     * @param delegate Address of the delegate
     */
    function setDelegate(address delegate) external {
        require (delegate != msg.sender, "Can't delegate to self");
        require (delegate != address(0), "Can't delegate to 0x0");
        address currentDelegate = delegation[msg.sender];
        require (delegate != currentDelegate, "Already delegated to this address");
        
        // Update delegation mapping
        delegation[msg.sender] = delegate;
        
        if (currentDelegate != address(0)) {
            emit ClearDelegate(msg.sender, currentDelegate);
        }

        emit SetDelegate(msg.sender, delegate);
    }
    
    /**
     * @notice Referenced from Gnosis' DelegateRegistry, found here: https://github.com/gnosis/delegate-registry/blob/main/contracts/DelegateRegistry.sol
     * @dev Clears a delegate for the msg.sender. Every msg.sender serves as a unique key.
     */
    function clearDelegate() external {
        address currentDelegate = delegation[msg.sender];
        require (currentDelegate != address(0), "No delegate set");
        
        // update delegation mapping
        delegation[msg.sender]= address(0);
        
        emit ClearDelegate(msg.sender, currentDelegate);
    }

    // if msg.sender is not user,
    function claimDelegatedReward(address _delegatingUser, address _delegatedUser, address _gauge, address _rewardToken) external returns (uint) {
        require(delegation[_delegatingUser] == _delegatedUser, "Not the delegated address");
        uint _amount = _claimDelegatedReward(_delegatingUser, _delegatedUser, _gauge, _rewardToken);
        emit DelegateClaimed(_delegatingUser, _delegatedUser, _gauge, _rewardToken, _amount);
        return _amount;
    }
    
    // if msg.sender is not user,
    function claimReward(address _user, address _gauge, address _rewardToken) external returns (uint) {
        uint _amount = _claimReward(_user, _gauge, _rewardToken);
        emit Claimed(_user, _gauge, _rewardToken, _amount);
        return _amount;
    }

    // if msg.sender is not user,
    function claimReward(address _gauge, address _rewardToken) external returns (uint) {
        uint _amount = _claimReward(msg.sender, _gauge, _rewardToken);
        emit Claimed(msg.sender, _gauge, _rewardToken, _amount);
        return _amount;
    }

    /**
     * @notice Deposits a reward on the gauge, which is stored in future claimable rewards. These will be claimable once the contract updates to the next period.
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @param _amount The amount to deposit on this gauge.
     * @return The amount claimed.
     */
    function addRewardAmount(address _gauge, address _rewardToken, uint _amount) external returns (bool) {
        _updatePeriod(_gauge, _rewardToken);
        
        // The below was added to the bribe.crv.finance implementation to handle fee distribution
        uint256 _fee = _amount*platformFee/DENOMINATOR;
        uint256 _incentiveTotal = _amount-_fee;
        _safeTransferFrom(_rewardToken, msg.sender, feeAddress, _fee);
        
        // replaced the amount variable with our incentiveTotal variable
        _safeTransferFrom(_rewardToken, msg.sender, address(this), _incentiveTotal);

        futureClaimableRewards[_gauge][_rewardToken] += _incentiveTotal;

        _add(_gauge, _rewardToken);
        return true;
    }

    /**
     * @notice Deposits a reward on the gauge, which is stored in future claimable rewards. These will only be claimable once the contract has cleared the vote limit (measured 0 --> 10000 in bps percentage)
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @param _amount The amount to deposit on this gauge.
     * @param _threshold The amount to deposit on this gauge.
     * @return The amount claimed.
     */
    function addLimitRewardAmount(address _gauge, address _rewardToken, uint _amount, uint _threshold) external returns (bool) {
        require(!(pendingRewards[_gauge][_rewardToken][msg.sender].threshold != 0 && pendingRewards[_gauge][_rewardToken][msg.sender].amount != 0), "Pending reward already exists for sender. Please update instead.");
        require(_amount > 0, "Amount must be greater than 0");
        require(_threshold > 0 && _threshold <= 10000, "Threshold must be greater than 0 and less than 10000");
        _updatePeriod(_gauge, _rewardToken);
        
        // The below was added to the bribe.crv.finance implementation to handle fee distribution
        uint256 _fee = _amount*platformFee/DENOMINATOR;
        uint256 _incentiveTotal = _amount-_fee;
        _safeTransferFrom(_rewardToken, msg.sender, feeAddress, _fee);
        
        // replaced the amount variable with our incentiveTotal variable
        _safeTransferFrom(_rewardToken, msg.sender, address(this), _incentiveTotal);

        LimitReward memory newLimit = LimitReward(_incentiveTotal, _threshold);

        pendingRewards[_gauge][_rewardToken][msg.sender] = newLimit;
        pendingRewardAddresses[_gauge][_rewardToken].push(msg.sender);

        _add(_gauge, _rewardToken);
        return true;
    }

    /**
     * @notice Updates a limit reward that's been deposited on behalf of msg.sender. This can be done to modify the threshold, increase the amount, or withdraw the limit reward altogether.
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @param _amount The new amount that the user would like.
     * @param _threshold The amount to deposit on this gauge.
     * @return The amount claimed.
     */
    function updateLimitRewardAmount(address _gauge, address _rewardToken, uint _amount, uint _threshold) external returns (bool) {
        LimitReward memory lr = pendingRewards[_gauge][_rewardToken][msg.sender];
        require(lr.threshold != 0 && lr.amount != 0, "Pending reward does not exist for msg.sender");
        require(_threshold > 0 && _threshold <= 10000, "Threshold must be greater than 0 and less than 10000");
        require(_threshold <= lr.threshold, "Cannot increase threshold");
        require(_amount >= (lr.amount * 5 / 4), "Must increase amount by 25% on limit order modifications");
        
        // fulfilled limit orders cannot be modified
        uint currentGaugeWeight = GaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);
        require((lr.threshold * (10 ** 14)) > currentGaugeWeight, "Already crossed threshold - not modifiable");

        // calculate the delta to subtract fee
        uint _delta = _amount - lr.amount;
        uint256 _fee = _delta*platformFee/DENOMINATOR;
        uint256 _deltaMinusFees = _delta-_fee;

        uint _newTotal = _deltaMinusFees + lr.amount;

        // sends the new fee to address
        _safeTransferFrom(_rewardToken, msg.sender, feeAddress, _fee);
        
        // transfers the delta here
        _safeTransferFrom(_rewardToken, msg.sender, address(this), _deltaMinusFees);

        LimitReward memory newLimit = LimitReward(_newTotal, _threshold);

        pendingRewards[_gauge][_rewardToken][msg.sender] = newLimit;

        return true;
    }

    /* ========== END EXTERNAL FUNCTIONS ========== */
    
    /* ========== INTERNAL FUNCTIONS ========== */
    
    /**
     * @notice Claims a pro-rata share reward of a voting gauge. This can only be done once per period per reward token per gauge, which is enforced at the Gauge Controller level.
     * @param _user The reward claimer
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return The amount claimed.
     */
    function _claimReward(address _user, address _gauge, address _rewardToken) internal returns (uint) {
        uint _period = _updatePeriod(_gauge, _rewardToken);
        uint _amount = 0;
        uint _votingWeek = _period - WEEK;

        if (last_user_claim[_user][_gauge][_rewardToken] < _votingWeek) {
            uint _totalWeight = GaugeController(gaugeControllerAddress).points_weight(_gauge, _period).bias; // bookmark the total slopes at the weds of current period
                
            if (_totalWeight > 0) {
                GaugeController.VotedSlope memory _individualSlope = GaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);
                uint _timeRemaining = _individualSlope.end - _period;
                uint _individualWeight = _timeRemaining * _individualSlope.slope;

                uint _totalRewards = currentlyClaimableRewards[_gauge][_rewardToken];
                _amount = _totalRewards * _individualWeight / _totalWeight;

                if (_amount > 0) {
                    currentlyClaimedRewards[_gauge][_rewardToken] += _amount;
                    last_user_claim[_user][_gauge][_rewardToken] = block.timestamp;
                    _safeTransfer(_rewardToken, _user, _amount);
                }
            }
        }

        return _amount;
    }

    /**
     * @notice Claims a pro-rata share reward of a voting gauge. This can only be done once per period per reward token per gauge, which is enforced at the Gauge Controller level. This should be refactored for elegance eventually.
     * @param _delegatingUser The voter who's delegated their rewards.
     * @param _delegatedUser The delegated reward address.
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return The amount claimed.
     */
    function _claimDelegatedReward(address _delegatingUser, address _delegatedUser, address _gauge, address _rewardToken) internal returns (uint) {
        uint _period = _updatePeriod(_gauge, _rewardToken);
        uint _amount = 0;
        uint _votingWeek = _period - WEEK;

        if (last_user_claim[_delegatingUser][_gauge][_rewardToken] < _votingWeek) {
            uint _totalWeight = GaugeController(gaugeControllerAddress).points_weight(_gauge, _period).bias; // bookmark the total slopes at the weds of current period
                
            if (_totalWeight > 0) {
                GaugeController.VotedSlope memory _individualSlope = GaugeController(gaugeControllerAddress).vote_user_slopes(_delegatingUser, _gauge);
                uint _timeRemaining = _individualSlope.end - _period;
                uint _individualWeight = _timeRemaining * _individualSlope.slope;

                uint _totalRewards = currentlyClaimableRewards[_gauge][_rewardToken];
                _amount = _totalRewards * _individualWeight / _totalWeight;

                if (_amount > 0) {
                    currentlyClaimedRewards[_gauge][_rewardToken] += _amount;
                    // sends the reward to the delegated user.
                    _safeTransfer(_rewardToken, _delegatedUser, _amount);
                }
            }
        }

        return _amount;
    }

    /**
     * @notice Synchronizes this contract's period for a given (gauge, reward) pair with the Gauge Controller, checkpointing votes.
     * @param _gauge The token underlying the supported gauge.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return The updated period
     */
    function _updatePeriod(address _gauge, address _rewardToken) internal returns (uint) {

        uint _currentPeriod = GaugeController(gaugeControllerAddress).time_total(); // period set to the previous weds at 5pm 
        uint _checkpointedPeriod = activePeriod[_gauge][_rewardToken]; // period needs to be hardcoded to next weds @ 5pm
        if (_currentPeriod > _checkpointedPeriod) {
            
            GaugeController(gaugeControllerAddress).checkpoint_gauge(_gauge);

            uint newlyQualifiedRewards = _updatePendingRewards(_gauge, _rewardToken);

            currentlyClaimableRewards[_gauge][_rewardToken] += futureClaimableRewards[_gauge][_rewardToken]; // add rewards that were signaled for next period into this one
            currentlyClaimableRewards[_gauge][_rewardToken] += newlyQualifiedRewards; // add rewards that are newly qualified into this one
            currentlyClaimableRewards[_gauge][_rewardToken] -= currentlyClaimedRewards[_gauge][_rewardToken]; // subtract rewards that have already been claimed
            currentlyClaimedRewards[_gauge][_rewardToken] = 0; // 0 out the current claimed rewards... could be gas optimized because it's setting it to 0
            futureClaimableRewards[_gauge][_rewardToken] = 0; // 0 out the future as well - could be gas optimized optimized.

            activePeriod[_gauge][_rewardToken] = _currentPeriod; // syncs our storage with external period
        }
        return _currentPeriod;
    }

    /**
     * @notice Goes through every pending reward on a [gauge][token] pair, and if the gauge has passed the threshold, it removes it from the list and frees its amount.
     * @param _gauge The token underlying the supported gauge.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return The updated period
     */
    function _updatePendingRewards(address _gauge, address _rewardToken) internal returns (uint) {
        uint _amount = 0;
        uint pendingRewardAddressLength = pendingRewardAddresses[_gauge][_rewardToken].length;
        for (uint i = 0; i < pendingRewardAddressLength; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_rewardToken][i];
            LimitReward memory lr = pendingRewards[_gauge][_rewardToken][pendingRewardAddress];

            uint currentGaugeWeight = GaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);

            // scaled the bps by 10**14
            if (currentGaugeWeight > (lr.threshold * (10 ** 14))) {
                _amount += lr.amount;
                
                // shifts final element to the current element and pops off last element for length preservation
                pendingRewardAddresses[_gauge][_rewardToken][i] = pendingRewardAddresses[_gauge][_rewardToken][pendingRewardAddressLength-1];
                pendingRewardAddresses[_gauge][_rewardToken].pop();
                delete pendingRewards[_gauge][_rewardToken][pendingRewardAddress];
            }
        }
        return _amount;
    }

    /**
     * @notice Adds the reward to internal bookkeeping for visibility at the contract level
     * @param _gauge The token underlying the supported gauge.
     * @param _reward The incentive deposited on this gauge.
     */
    function _add(address _gauge, address _reward) internal {
        if (!_rewardsInGauge[_gauge][_reward]) {
            _rewardsPerGauge[_gauge].push(_reward);
            _gaugesPerReward[_reward].push(_gauge);
            _rewardsInGauge[_gauge][_reward] = true;
        }
    }
    
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    /* ========== END INTERNAL FUNCTIONS ========== */

    /* ========== OWNER FUNCTIONS ========== */

    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function updateGaugeControllerAddress(address _gaugeControllerAddress) public onlyOwner {
      gaugeControllerAddress = _gaugeControllerAddress;
      emit UpdatedGaugeController(_gaugeControllerAddress);
    }

    // update fee address
    function updateFeeAddress(address _feeAddress) public onlyOwner {
      feeAddress = _feeAddress;
    }

    // update fee amount
    function updateFeeAmount(uint256 _feeAmount) public onlyOwner {
      require(_feeAmount < 400, "max fee"); // Max fee 4%
      platformFee = _feeAmount;
      emit UpdatedFee(_feeAmount);
    }

    /* ========== END OWNER FUNCTIONS ========== */


    /* ========== EVENTS ========== */
    event Claimed(address indexed user, address indexed gauge, address indexed token, uint256 amount);
    event DelegateClaimed(address indexed delegatingUser, address indexed delegatedUser, address indexed gauge, address token, uint256 amount);
    event UpdatedFee(uint256 _feeAmount);
    event UpdatedGaugeController(address gaugeController);
    event SetDelegate(address indexed delegator, address indexed delegate);
    event ClearDelegate(address indexed delegator, address indexed delegate);
    
}