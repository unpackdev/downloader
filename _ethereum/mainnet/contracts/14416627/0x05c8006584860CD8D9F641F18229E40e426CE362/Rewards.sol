/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

import "./RewardsInterface.sol";
import "./ERC20Interface.sol";
import "./OtokenInterface.sol";
import "./AddressBookInterface.sol";
import "./WhitelistInterface.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title Rewards
 * @author 10 Delta
 * @notice The rewards module distributes liquidity mining rewards to oToken shorters
 */
contract Rewards is Ownable, RewardsInterface {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Interface;

    /// @notice AddressBook module address
    AddressBookInterface public immutable addressBook;
    /// @notice token to pay rewards in
    ERC20Interface public rewardsToken;
    /// @notice address for notifying/removing rewards
    address public rewardsDistribution;
    /// @notice if true all vault owners will receive rewards
    bool public whitelistAllOwners;
    /// @notice if true rewards get forfeited when closing an oToken before expiry
    bool public forfeitRewards;
    /// @notice total rewards forfeited
    uint256 public forfeitedRewards;
    /// @notice the reward rate for an oToken
    mapping(address => uint256) public rewardRate;
    /// @notice the last upddate time for an oToken
    mapping(address => uint256) public lastUpdateTime;
    /// @notice the reward per token for an oToken
    mapping(address => uint256) public rewardPerTokenStored;
    /// @notice the reward per token for a user
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    /// @notice the rewards earnt by a user
    mapping(address => mapping(address => uint256)) public rewards;
    /// @notice the total amount of each oToken
    mapping(address => uint256) public totalSupply;
    /// @notice the balances for each oToken
    mapping(address => mapping(address => uint256)) public balances;

    /**
     * @dev constructor
     * @param _addressBook AddressBook module address
     */
    constructor(address _addressBook) public {
        require(_addressBook != address(0), "Rewards: Invalid address book");

        addressBook = AddressBookInterface(_addressBook);
    }

    /// @notice emits an event when the whitelist all owners setting changes
    event WhitelistAllOwners(bool whitelisted);
    /// @notice emits an event when the forfeit rewards setting changes
    event ForfeitRewards(bool forfeited);
    /// @notice emits an event the rewards distribution address is updated
    event RewardsDistributionUpdated(address indexed _rewardsDistribution);
    /// @notice emits an event when rewards are added for an otoken
    event RewardAdded(address indexed otoken, uint256 reward);
    /// @notice emits an event when rewards are removed for an otoken
    event RewardRemoved(address indexed token, uint256 amount);
    /// @notice emits an event when forfeited rewards are recovered
    event RecoveredForfeitedRewards(uint256 amount);
    /// @notice emits an event when rewards are paid out to a user
    event RewardPaid(address indexed otoken, address indexed account, uint256 reward);

    /**
     * @notice check if the sender is the controller module
     */
    modifier onlyController() {
        require(msg.sender == addressBook.getController(), "Rewards: Sender is not Controller");

        _;
    }

    /**
     * @notice check if the sender is the rewards distribution address
     */
    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Rewards: Sender is not RewardsDistribution");

        _;
    }

    /**
     * @notice initializes the rewards token
     * @dev can only be called by the owner, doesn't allow reinitializing the rewards token
     * @param _rewardsToken the address of the rewards token
     */
    function setRewardsToken(address _rewardsToken) external onlyOwner {
        require(rewardsToken == ERC20Interface(0), "Rewards: Token already set");

        rewardsToken = ERC20Interface(_rewardsToken);
    }

    /**
     * @notice sets the rewards distribution address
     * @dev can only be called by the owner
     * @param _rewardsDistribution the new rewards distribution address
     */
    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;

        emit RewardsDistributionUpdated(_rewardsDistribution);
    }

    /**
     * @notice whitelists/blacklists all vault owners from receiving rewards
     * @dev can only be called by the owner
     * @param _whitelistAllOwners new boolean value to set whitelistAllOwners to
     */
    function setWhitelistAllOwners(bool _whitelistAllOwners) external onlyOwner {
        whitelistAllOwners = _whitelistAllOwners;

        emit WhitelistAllOwners(_whitelistAllOwners);
    }

    /**
     * @notice enables/disables forfeiting of rewards when closing an oToken short before expiry
     * @dev can only be called by the owner
     * @param _forfeitRewards new boolean value to set forfeitRewards to
     */
    function setForfeitRewards(bool _forfeitRewards) external onlyOwner {
        forfeitRewards = _forfeitRewards;

        emit ForfeitRewards(_forfeitRewards);
    }

    /**
     * @notice adds rewards for an oToken
     * @dev can only be called by rewards distribution, reverts if rewardsToken is uninitialized
     * @param otoken oToken to add rewards for
     * @param reward amount of rewards to add
     */
    function notifyRewardAmount(address otoken, uint256 reward) external onlyRewardsDistribution {
        _updateReward(otoken, address(0));

        // Reverts if oToken is expired
        uint256 remaining = OtokenInterface(otoken).expiryTimestamp().sub(now);
        uint256 _rewardRate = (reward.div(remaining)).add(rewardRate[otoken]);

        // Transfer reward amount to this contract
        // This is necessary because there can be multiple rewards so a balance check isn't enough
        rewardsToken.safeTransferFrom(msg.sender, address(this), reward);

        rewardRate[otoken] = _rewardRate;
        lastUpdateTime[otoken] = now;

        emit RewardAdded(otoken, reward);
    }

    /**
     * @notice remove rewards for an oToken
     * @dev can only be called by rewards distribution, reverts if rewardsToken is uninitialized
     * @param otoken oToken to remove rewards from
     * @param rate rewardRate to remove for an oToken
     */
    function removeRewardAmount(address otoken, uint256 rate) external onlyRewardsDistribution {
        _updateReward(otoken, address(0));

        // Reverts if oToken is expired
        uint256 _rewardRate = rewardRate[otoken];
        uint256 reward = (OtokenInterface(otoken).expiryTimestamp().sub(now)).mul(rate);

        // Transfers the removed reward amount back to the owner
        rewardsToken.safeTransfer(msg.sender, reward);

        rewardRate[otoken] = _rewardRate.sub(rate);
        lastUpdateTime[otoken] = now;

        emit RewardRemoved(otoken, reward);
    }

    /**
     * @notice transfers forfeited rewards to rewards distribution
     * @dev can only be called by rewards distribution
     */
    function recoverForfeitedRewards() external onlyRewardsDistribution {
        uint256 _forfeitedRewards = forfeitedRewards;
        ERC20Interface _rewardsToken = rewardsToken;
        uint256 rewardsBalance = _rewardsToken.balanceOf(address(this));
        _rewardsToken.safeTransfer(msg.sender, _forfeitedRewards < rewardsBalance ? _forfeitedRewards : rewardsBalance);
        forfeitedRewards = 0;
        emit RecoveredForfeitedRewards(_forfeitedRewards);
    }

    /**
     * @notice records the minting of oTokens
     * @dev can only be called by the controller
     * @param otoken oToken address
     * @param account vault owner
     * @param amount amount of oTokens minted
     */
    function mint(
        address otoken,
        address account,
        uint256 amount
    ) external override onlyController {
        if (isWhitelistedOwner(account)) {
            _updateReward(otoken, account);
            totalSupply[otoken] = totalSupply[otoken].add(amount);
            balances[otoken][account] = balances[otoken][account].add(amount);
        }
    }

    /**
     * @notice records the burning of oTokens
     * @dev can only be called by the controller
     * @param otoken oToken address
     * @param account vault owner
     * @param amount amount of oTokens burnt
     */
    function burn(
        address otoken,
        address account,
        uint256 amount
    ) external override onlyController {
        uint256 balance = balances[otoken][account];
        if (balance > 0) {
            _updateReward(otoken, account);
            amount = amount > balance ? balance : amount;
            totalSupply[otoken] = totalSupply[otoken].sub(amount);
            balances[otoken][account] = balance.sub(amount);
            if (forfeitRewards) {
                uint256 _rewards = rewards[otoken][account];
                uint256 _forfeitedRewards = _rewards.mul(amount).div(balance);
                rewards[otoken][account] = _rewards.sub(_forfeitedRewards);
                forfeitedRewards = forfeitedRewards.add(_forfeitedRewards);
            }
        }
    }

    /**
     * @notice claims oToken minting rewards and transfers it to the vault owner
     * @dev can only be called by the controller
     * @param otoken oToken address
     * @param account vault owner
     */
    function getReward(address otoken, address account) external override onlyController {
        _getReward(otoken, account);
    }

    /**
     * @notice allows vault owners to claim rewards if this module has been deprecated
     * @dev oToken must be expired before claiming rewards
     * @param otoken oToken address
     */
    function claimReward(address otoken) external {
        require(address(this) != addressBook.getRewards(), "Rewards: Module not deprecated");
        require(now >= OtokenInterface(otoken).expiryTimestamp(), "Rewards: Not expired");
        _getReward(otoken, msg.sender);
    }

    /**
     * @notice checks if a vault owner is whitelisted
     * @param account vault owner
     * @return boolean, True if the vault owner is whitelisted
     */
    function isWhitelistedOwner(address account) public view returns (bool) {
        return whitelistAllOwners || WhitelistInterface(addressBook.getWhitelist()).isWhitelistedOwner(account);
    }

    /**
     * @notice returns the last time rewards are applicable for an oToken
     * @param otoken oToken address
     * @return last time rewards are applicable for the oToken
     */
    function lastTimeRewardApplicable(address otoken) public view returns (uint256) {
        uint256 periodFinish = OtokenInterface(otoken).expiryTimestamp();
        return periodFinish > now ? now : periodFinish;
    }

    /**
     * @notice returns the reward per token for an oToken
     * @param otoken oToken address
     * @return reward per token for the oToken
     */
    function rewardPerToken(address otoken) public view returns (uint256) {
        uint256 _totalSupply = totalSupply[otoken];
        if (_totalSupply == 0) {
            return rewardPerTokenStored[otoken];
        }
        return
            rewardPerTokenStored[otoken].add(
                lastTimeRewardApplicable(otoken).sub(lastUpdateTime[otoken]).mul(rewardRate[otoken]).mul(1e18).div(
                    _totalSupply
                )
            );
    }

    /**
     * @notice returns the rewards a vault owner has earnt for an oToken
     * @param otoken oToken address
     * @param account vault owner address
     * @return rewards earnt by the vault owner
     */
    function earned(address otoken, address account) public view returns (uint256) {
        return
            balances[otoken][account]
                .mul(rewardPerToken(otoken).sub(userRewardPerTokenPaid[otoken][account]))
                .div(1e18)
                .add(rewards[otoken][account]);
    }

    /**
     * @dev updates the reward per token and the rewards earnt by a vault owner
     * @param otoken oToken address
     * @param account vault owner address
     */
    function _updateReward(address otoken, address account) internal {
        uint256 _rewardPerTokenStored = rewardPerToken(otoken);
        rewardPerTokenStored[otoken] = _rewardPerTokenStored;
        if (account != address(0)) {
            lastUpdateTime[otoken] = lastTimeRewardApplicable(otoken);
            rewards[otoken][account] = earned(otoken, account);
            userRewardPerTokenPaid[otoken][account] = _rewardPerTokenStored;
        }
    }

    /**
     * @dev claims oToken minting rewards and transfers it to the vault owner
     * @param otoken oToken address
     * @param account vault owner
     */
    function _getReward(address otoken, address account) internal {
        _updateReward(otoken, account);
        uint256 reward = rewards[otoken][account];
        if (reward > 0) {
            rewards[otoken][account] = 0;
            ERC20Interface _rewardsToken = rewardsToken;
            uint256 rewardsBalance = _rewardsToken.balanceOf(address(this));
            if (rewardsBalance > 0) {
                _rewardsToken.safeTransfer(account, reward < rewardsBalance ? reward : rewardsBalance);
                emit RewardPaid(otoken, account, reward);
            }
        }
    }
}
