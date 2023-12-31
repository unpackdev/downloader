//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: None

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Owner.sol";
import "./IWarlordStaker.sol";

/**
 * @title Warlord wrapped staked WAR token
 * @author Paladin
 * @notice Wrapped version of the stkWAR token
 *         Used to LP in pool and claim with reward forwarding
 *         (Forfeit the claim of some rewards)
 */
contract WrappedStakedWar is ERC20, ReentrancyGuard, Pausable, Owner {
    using SafeERC20 for IERC20;

    // Constants

    /**
     * @notice 1e18 scale
     */
    uint256 private constant UNIT = 1e18;
    /**
     * @notice Max value possible for an uint256
     */
    uint256 private constant MAX_UINT256 = 2 ** 256 - 1;


    // Structs

    /**
     * @notice UserRewardState struct
     *   lastRewardPerToken: last update reward per token value
     *   accruedRewards: total amount of rewards accrued
     */
    struct UserRewardState {
        uint256 lastRewardPerToken;
        uint256 accruedRewards;
    }

    /**
     * @notice RewardState struct
     *   rewardPerToken: current reward per token value
     *   userStates: users reward state for the reward token
     */
    struct RewardState {
        uint256 rewardPerToken;
        // user address => user reward state
        mapping(address => UserRewardState) userStates;
    }

    /**
     * @notice UserClaimableRewards struct
     *   reward: address of the reward token
     *   claimableAmount: amount of rewards accrued by the user
     */
    struct UserClaimableRewards {
        address reward;
        uint256 claimableAmount;
    }

    /**
     * @notice UserClaimedRewards struct
     *   reward: address of the reward token
     *   amount: amount of rewards claimed by the user
     */
    struct UserClaimedRewards {
        address reward;
        uint256 amount;
    }


    // Storage

    /**
     * @notice Address of the WAR token
     */
    address public immutable war;
    /**
     * @notice Address of the stkWAR token
     */
    address public immutable stkWar;

    /**
     * @notice List of reward token allowed to be claimed by this contract
     */
    address[] public rewardTokens;
    mapping(address => bool) private isListedToken;
    /**
     * @notice Reward state for each reward token
     */
    mapping(address => RewardState) public rewardStates;

    /** @notice Addresses allowed to claim for another user */
    mapping(address => address) public allowedClaimer;


    // Errors

    error ZeroAddress();
    error NullAmount();
    error InvalidAmount();
    error AlreadyListed();
    error NotListed();
    error ClaimNotAllowed();


    // Events

    /**
     * @notice Event emitted when wrapping
     */
    event Wrapped(
        address indexed caller,
        address indexed receiver,
        uint256 amount
    );

    /**
     * @notice Event emitted when wrapping from WAR
     */
    event WrappedWar(
        address indexed caller,
        address indexed receiver,
        uint256 amount
    );
    /**
     * @notice Event emitted when unwrapping
     */
    event Unwrapped(
        address indexed owner,
        address indexed receiver,
        uint256 amount
    );

    /**
     * @notice Event emitted when rewards are claimed
     */
    event ClaimedRewards(
        address indexed reward,
        address indexed user,
        address indexed receiver,
        uint256 amount
    );

    /**
     * @notice Event emitted when a new Claimer is set for an user
     */
    event SetUserAllowedClaimer(address indexed user, address indexed claimer);
    /**
     * @notice Event emitted when a reward token is added
     */
    event RewardTokenAdded(address indexed token);


    // Constructor

    constructor(address _war, address _stkWar) ERC20("Wrapped stkWAR token", "wstkWAR") {
        if (_war == address(0) || _stkWar == address(0)) revert ZeroAddress();

        war = _war;
        stkWar = _stkWar;

        IERC20(_war).safeApprove(_stkWar, MAX_UINT256);
    }


    // View functions

    /**
     * @notice Get the list of all reward tokens
     * @return address[] : List of reward tokens
     */
    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    /**
     * @notice Get the current reward state of an user for a given reward token
     * @param reward Address of the reward token
     * @param user Address of the user
     * @return UserRewardState : User reward state
     */
    function getUserRewardState(
        address reward,
        address user
    ) external view returns (UserRewardState memory) {
        return rewardStates[reward].userStates[user];
    }

    /**
     * @notice Get the current amount of rewards accrued by an user for a given reward token
     * @param reward Address of the reward token
     * @param user Address of the user
     * @return uint256 : amount of rewards accrued
     */
    function getUserAccruedRewards(
        address reward,
        address user
    ) external view returns (uint256) {
        return rewardStates[reward].userStates[user].accruedRewards 
            + _getUserEarnedRewards(reward, user, _getNewRewardPerToken(reward));
    }

    /**
     * @notice Get all current claimable amount of rewards for all reward tokens for a given user
     * @param user Address of the user
     * @return UserClaimableRewards[] : Amounts of rewards claimable by reward token
     */
    function getUserTotalClaimableRewards(
        address user
    ) external view returns (UserClaimableRewards[] memory) {
        address[] memory rewards = rewardTokens;
        uint256 rewardsLength = rewards.length;
        UserClaimableRewards[] memory rewardAmounts = new UserClaimableRewards[](rewardsLength);

        // For each listed reward
        for (uint256 i; i < rewardsLength; ) {
            // Add the reward token to the list
            rewardAmounts[i].reward = rewards[i];
            // And add the calculated claimable amount of the given reward
            // Accrued rewards from previous stakes + accrued rewards from current stake
            rewardAmounts[i].claimableAmount = rewardStates[rewards[i]].userStates[user].accruedRewards 
                + _getUserEarnedRewards(rewards[i], user, _getNewRewardPerToken(rewards[i]));

            unchecked { ++i; }
        }
        return rewardAmounts;
    }

    // State_changing functions

    // Can give MAX_UINT256 to stake full balance
    /**
    * @notice Wrap stkWAR tokens
    * @param amount Amount to wrap
    * @param receiver Address of the address to wrap for
    * @return uint256 : wrapped amount for the deposit
    */
    function wrap(uint256 amount, address receiver) external nonReentrant whenNotPaused returns (uint256) {
        // If given MAX_UINT256, we want to deposit the full user balance
        if (amount == MAX_UINT256) amount = IERC20(stkWar).balanceOf(msg.sender);

        if (amount == 0) revert NullAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Pull the tokens from the user
        IERC20(stkWar).safeTransferFrom(msg.sender, address(this), amount);

        // Mint the wrapped tokens
        // It will also update the reward states for the user who's balance gonna change
        _mint(receiver, amount);

        emit Wrapped(msg.sender, receiver, amount);

        return amount;
    }

    // Can give MAX_UINT256 to stake full balance
    /**
    * @notice Wrap WAR tokens by staking them into stkWAR
    * @param amount Amount to wrap
    * @param receiver Address of the address to wrap for
    * @return uint256 : wrapped amount for the deposit
    */
    function wrapWar(uint256 amount, address receiver) external nonReentrant whenNotPaused returns (uint256) {
        // If given MAX_UINT256, we want to deposit the full user balance
        if (amount == MAX_UINT256) amount = IERC20(war).balanceOf(msg.sender);

        if (amount == 0) revert NullAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Pull the tokens from the user
        IERC20(war).safeTransferFrom(msg.sender, address(this), amount);

        // Stake the tokens into stkWAR
        IWarlordStaker(stkWar).stake(amount, address(this));

        // Mint the wrapped tokens
        // It will also update the reward states for the user who's balance gonna change
        _mint(receiver, amount);

        emit WrappedWar(msg.sender, receiver, amount);

        return amount;
    }

    // Can give MAX_UINT256 to unwrap full balance
    /**
    * @notice Unwrap WAR tokens
    * @param amount Amount to unwrap
    * @param receiver Address to receive the tokens
    * @return uint256 : amount unwrap
    */
    function unwrap(uint256 amount, address receiver) external nonReentrant returns (uint256) {
        // If given MAX_UINT256, we want to withdraw the full user balance
        if (amount == MAX_UINT256) amount = balanceOf(msg.sender);

        if (amount == 0) revert NullAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Burn the wrapped tokens
        // It will also update the reward states for the user who's balance gonna change
        _burn(msg.sender, amount);

        // And send the tokens to the given receiver
        IERC20(stkWar).safeTransfer(receiver, amount);

        emit Unwrapped(msg.sender, receiver, amount);

        return amount;
    }

    /**
    * @notice Claim all accrued rewards for all reward tokens
    * @param receiver Address to receive the rewards
    * @return UserClaimedRewards[] : Amounts of reward claimed
    */
    function claimRewards(address receiver) external nonReentrant whenNotPaused returns(UserClaimedRewards[] memory) {
        if(receiver == address(0)) revert ZeroAddress();

        return _claimAllRewards(msg.sender, receiver);
    }

    /**
    * @notice Claim all accrued rewards for all reward tokens on behalf of a given user
    * @param user Address that accrued the rewards
    * @param receiver Address to receive the rewards
    * @return UserClaimedRewards[] : Amounts of reward claimed
    */
    function claimRewardsForUser(address user, address receiver) external nonReentrant whenNotPaused returns(UserClaimedRewards[] memory) {
        if(receiver == address(0) || user == address(0)) revert ZeroAddress();
        if(msg.sender != allowedClaimer[user]) revert ClaimNotAllowed();

        return _claimAllRewards(user, receiver);
    }

    /**
    * @notice Update the reward state for a given reward token
    * @param reward Address of the reward token
    */
    function updateRewardState(address reward) external whenNotPaused {
        if(reward == address(0)) revert ZeroAddress();
        if(isListedToken[reward] == false) revert NotListed();
        _updateRewardState(reward);
    }

    /**
    * @notice Update the reward state for all reward tokens
    */
    function updateAllRewardState() external whenNotPaused {
        _updateAllRewardStates();
    }


    // Internal functions

    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/ ) internal override {
        if (from != address(0)) {
        _updateAllUserRewardStates(from);
        }
        if (to != address(0)) {
        _updateAllUserRewardStates(to);
        }
    }
    
    /**
    * @dev Calculate the new rewardPerToken value for a reward token
    * @param reward Address of the reward token
    * @return uint256 : new rewardPerToken value
    */
    function _getNewRewardPerToken(address reward) internal view returns(uint256) {
        if(totalSupply() == 0) return rewardStates[reward].rewardPerToken;
        
        // Get the current claimable amount from stkWAR
        uint256 claimableAmount = IWarlordStaker(stkWar).getUserAccruedRewards(reward, address(this));

        // Calculate the increase since the last update
        return rewardStates[reward].rewardPerToken + ((claimableAmount * UNIT) / totalSupply());
    }

    /**
    * @dev Calculate the amount of rewards accrued by an user since last update for a reward token
    * @param reward Address of the reward token
    * @param user Address of the user
    * @return uint256 : Accrued rewards amount for the user
    */
    function _getUserEarnedRewards(address reward, address user, uint256 currentRewardPerToken) internal view returns(uint256) {
        UserRewardState storage userState = rewardStates[reward].userStates[user];

        // Get the user balance
        uint256 userBalance = balanceOf(user);

        if(userBalance == 0) return 0;

        // If the user has a previous deposit (balance is not null), calculate the
        // earned rewards based on the increase of the rewardPerToken value
        return (userBalance * (currentRewardPerToken - userState.lastRewardPerToken)) / UNIT;
    }

    /**
    * @dev Update the reward token distribution state
    * @param reward Address of the reward token
    */
    function _updateRewardState(address reward) internal {
        // No total supply, no rewards
        if(totalSupply() == 0) return;
        
        // Claim reward
        uint256 receivedAmount = IWarlordStaker(stkWar).claimRewards(reward, address(this));

        // Update reward state
        rewardStates[reward].rewardPerToken += ((receivedAmount * UNIT) / totalSupply());
    }

    /**
    * @dev Update the user reward state for a given reward token
    * @param reward Address of the reward token
    * @param user Address of the user
    */
    function _updateUserRewardState(address reward, address user) internal {
        // Update the reward token state before the user's state
        _updateRewardState(reward);

        UserRewardState storage userState = rewardStates[reward].userStates[user];

        // Update the storage with the new reward state
        uint256 currentRewardPerToken = rewardStates[reward].rewardPerToken;
        userState.accruedRewards += _getUserEarnedRewards(reward, user, currentRewardPerToken);
        userState.lastRewardPerToken = currentRewardPerToken;
    }

    function _updateAllRewardStates() internal {
        address[] memory _rewards = rewardTokens;
        uint256 length = _rewards.length;

        // For all reward token in the list, update the user's reward state
        for (uint256 i; i < length;) {
            _updateRewardState(_rewards[i]);

            unchecked { ++i; }
        }
    }

    /**
    * @dev Update the reward state of the given user for all the reward tokens
    * @param user Address of the user
    */
    function _updateAllUserRewardStates(address user) internal {
        address[] memory _rewards = rewardTokens;
        uint256 length = _rewards.length;

        // For all reward token in the list, update the user's reward state
        for (uint256 i; i < length;) {
            _updateUserRewardState(_rewards[i], user);

            unchecked { ++i; }
        }
    }

    /**
    * @dev Claims all rewards of an user and sends them to the receiver address
    * @param user Address of the user
    * @param receiver Address to receive the rewards
    * @return UserClaimedRewards[] : list of claimed rewards
    */
    function _claimAllRewards(address user, address receiver) internal returns (UserClaimedRewards[] memory) {
        address[] memory rewards = rewardTokens;
        uint256 rewardsLength = rewards.length;

        UserClaimedRewards[] memory rewardAmounts = new UserClaimedRewards[](rewardsLength);

        // Update all user states to get all current claimable rewards
        _updateAllUserRewardStates(user);

        // For each reward token in the reward list
        for (uint256 i; i < rewardsLength;) {
            UserRewardState storage userState = rewardStates[rewards[i]].userStates[user];

            // Fetch the amount of rewards accrued by the user
            uint256 rewardAmount = userState.accruedRewards;

            // Track the claimed amount for the reward token
            rewardAmounts[i].reward = rewards[i];
            rewardAmounts[i].amount = rewardAmount;

            // If the user accrued no rewards, skip
            if (rewardAmount == 0) {
                unchecked { ++i; }
                continue;
            }

            // Reset user's accrued rewards
            userState.accruedRewards = 0;

            // For each reward token, send the accrued rewards to the given receiver
            IERC20(rewards[i]).safeTransfer(receiver, rewardAmount);

            emit ClaimedRewards(rewards[i], user, receiver, rewardAmounts[i].amount);

            unchecked { ++i; }
        }

        return rewardAmounts;
    }


    // Admin functions
    
    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @notice Sets a given address as allowed to claim rewards for a given user
    * @dev Sets a given address as allowed to claim rewards for a given user
    * @param user Address of the user
    * @param claimer Address of the allowed claimer
    */
    function setUserAllowedClaimer(address user, address claimer) external onlyOwner {
        if(user == address(0) || claimer == address(0)) revert ZeroAddress();

        // Set the given address as the claimer for the given user
        allowedClaimer[user] = claimer;

        emit SetUserAllowedClaimer(user, claimer);
    }

    function addRewardToken(address token) external onlyOwner {
        if(token == address(0)) revert ZeroAddress();
        if(isListedToken[token]) revert AlreadyListed();

        isListedToken[token] = true;
        rewardTokens.push(token);

        emit RewardTokenAdded(token);
    }

    function resetWarAllowance() external onlyOwner {
        IERC20(war).safeApprove(stkWar, MAX_UINT256);
    }

}
