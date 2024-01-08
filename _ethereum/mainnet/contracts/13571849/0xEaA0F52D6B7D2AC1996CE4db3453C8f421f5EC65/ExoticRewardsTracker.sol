// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

import "./IterableMapping.sol";

/// @author Roger Wu (https://github.com/roger-wu) rename from dividends to rewards
interface RewardPayingTokenInterface {
    /// @notice View the amount of reward in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of reward in wei that `_owner` can withdraw.
    function rewardOf(address _owner) external view returns(uint256);

    /// @notice Distributes ether to token holders as rewards.
    /// @dev SHOULD distribute the paid ether to token holders as rewards.
    ///  SHOULD NOT directly transfer ether to token holders in this function.
    ///  MUST emit a `RewardsDistributed` event when the amount of distributed ether is greater than 0.
    function distributeRewards() external payable;

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer `rewardOf(msg.sender)` wei to `msg.sender`, and `rewardOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `RewardWithdrawn` event if the amount of ether transferred is greater than 0.
    function withdrawReward() external;

    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event RewardsDistributed(
        address indexed from,
        uint256 weiAmount
    );

  /// @dev This event MUST emit when an address withdraws their reward.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
    event RewardWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}

/// @title Reward-Paying Token Optional Interface
/// @dev OPTIONAL functions for a reward-paying token contract.
interface RewardPayingTokenOptionalInterface {
    /// @notice View the amount of reward in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of reward in wei that `_owner` can withdraw.
    function withdrawableRewardOf(address _owner) external view returns(uint256);

    /// @notice View the amount of reward in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of reward in wei that `_owner` has withdrawn.
    function withdrawnRewardOf(address _owner) external view returns(uint256);

    /// @notice View the amount of reward in wei that an address has earned in total.
    /// @dev accumulativeRewardOf(_owner) = withdrawableRewardOf(_owner) + withdrawnRewardOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of reward in wei that `_owner` has earned in total.
    function accumulativeRewardOf(address _owner) external view returns(uint256);
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

/// @title Reward-Paying Token
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as rewards and allows token holders to withdraw their rewards.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract RewardPayingToken is ERC20, RewardPayingTokenInterface, RewardPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute rewards even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    // see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal magnitude = 2**128;

    uint256 internal magnifiedRewardPerShare;

    // About rewardCorrection:
    // If the token balance of a `_user` is never changed, the reward of `_user` can be computed with:
    //   `rewardOf(_user) = rewardPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `rewardOf(_user)` should not be changed,
    //   but the computed value of `rewardPerShare * balanceOf(_user)` is changed.
    // To keep the `rewardOf(_user)` unchanged, we add a correction term:
    //   `rewardOf(_user) = rewardPerShare * balanceOf(_user) + rewardCorrectionOf(_user)`,
    //   where `rewardCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `rewardCorrectionOf(_user) = rewardPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `rewardOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedRewardCorrections;
    mapping(address => uint256) internal withdrawnRewards;

    uint256 public totalRewardsDistributed;

    constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

    }

    /// @dev Distributes rewards whenever ether is paid to this contract.
    receive() external payable {
        distributeRewards();
    }

    /// @notice Distributes ether to token holders as rewards.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `RewardsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.
    function distributeRewards() public override payable {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedRewardPerShare = magnifiedRewardPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit RewardsDistributed(msg.sender, msg.value);

            totalRewardsDistributed = totalRewardsDistributed.add(msg.value);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `RewardWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawReward() public virtual override {
        _withdrawRewardOfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `RewardWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawRewardOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableReward = withdrawableRewardOf(user);
        if (_withdrawableReward > 0) {
        withdrawnRewards[user] = withdrawnRewards[user].add(_withdrawableReward);
        emit RewardWithdrawn(user, _withdrawableReward);
        (bool success,) = user.call{value: _withdrawableReward, gas: 3000}("");

        if(!success) {
            withdrawnRewards[user] = withdrawnRewards[user].sub(_withdrawableReward);
            return 0;
        }

        return _withdrawableReward;
        }

        return 0;
    }


    /// @notice View the amount of reward in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of reward in wei that `_owner` can withdraw.
    function rewardOf(address _owner) public view override returns(uint256) {
        return withdrawableRewardOf(_owner);
    }

    /// @notice View the amount of reward in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of reward in wei that `_owner` can withdraw.
    function withdrawableRewardOf(address _owner) public view override returns(uint256) {
        return accumulativeRewardOf(_owner).sub(withdrawnRewards[_owner]);
    }

    /// @notice View the amount of reward in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of reward in wei that `_owner` has withdrawn.
    function withdrawnRewardOf(address _owner) public view override returns(uint256) {
        return withdrawnRewards[_owner];
    }

    /// @notice View the amount of reward in wei that an address has earned in total.
    /// @dev accumulativeRewardOf(_owner) = withdrawableRewardOf(_owner) + withdrawnRewardOf(_owner)
    /// = (magnifiedRewardPerShare * balanceOf(_owner) + magnifiedRewardCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of reward in wei that `_owner` has earned in total.
    function accumulativeRewardOf(address _owner) public view override returns(uint256) {
        return magnifiedRewardPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedRewardCorrections[_owner]).toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedRewardCorrections to keep rewards unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedRewardPerShare.mul(value).toInt256Safe();
        magnifiedRewardCorrections[from] = magnifiedRewardCorrections[from].add(_magCorrection);
        magnifiedRewardCorrections[to] = magnifiedRewardCorrections[to].sub(_magCorrection);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedRewardCorrections to keep rewards unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedRewardCorrections[account] = magnifiedRewardCorrections[account]
        .sub( (magnifiedRewardPerShare.mul(value)).toInt256Safe() );
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedRewardCorrections to keep rewards unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedRewardCorrections[account] = magnifiedRewardCorrections[account]
        .add( (magnifiedRewardPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract ExoticRewardsTracker is RewardPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromRewards;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 private  minimumTokenBalanceForRewards;

    event ExcludeFromRewards(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public RewardPayingToken("ExoticRewardsTracker", "ExoticRewardsTracker") {
        claimWait = 3600;
        minimumTokenBalanceForRewards = 2000 * (10**18); 
    } 
    
    function setMinimumTokenBalanceForRewards(uint256 newMinTokenBalForRewards) external onlyOwner {
        minimumTokenBalanceForRewards = newMinTokenBalForRewards * (10**18);
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "No transfers allowed");
    }

    function withdrawReward() public override {
        require(false, "It is disabled. Use the 'claim' function on the main NFTY contract.");
    }

    function excludeFromRewards(address account) external onlyOwner {
        require(!excludedFromRewards[account]);
        excludedFromRewards[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromRewards(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "claimWait must be updated to between 1 and 24 hours");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
    
    function minimumTokenLimit() public view returns(uint256) {
        return minimumTokenBalanceForRewards;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableRewards = withdrawableRewardOf(account);
        totalRewards = accumulativeRewardOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromRewards[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForRewards) {
        _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
        _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawRewardOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}