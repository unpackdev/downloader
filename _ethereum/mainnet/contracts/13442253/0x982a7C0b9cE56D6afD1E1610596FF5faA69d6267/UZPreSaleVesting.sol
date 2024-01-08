// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

/**
 * @title UZPreSaleVesting
 * @author Unizen
 * @notice Presale distribution contract, that also allows claiming
 * all of the rewards of the whole quarter, as holder tokens. These can be
 * swapped 1 : 1 for an already vested amount of the final reward token.
 * This is relevant, since holder tokens can be staked, just as the real token
 * so the early investors don't lose out on an important benefit.
 **/
contract UZPreSaleVesting is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Burnable;
    using SafeMath for uint256;
    struct UserData {
        // users total utility tokens
        uint256 totalRewards;
        // used to store pending rewards
        // if a date needs to be adjusted
        uint256 savedRewards;
        // already claimed rewards
        uint256 claimedRewards;
        // tranches of holder tokens claimed
        uint8 claimedTranches;
    }

    // user data for stakers
    mapping(address => UserData) public _userData;

    // the actual token, that will be vested
    IERC20 public utilityToken;
    // the non transferable holder token
    IERC20Burnable public holderToken;

    // blockHeights of the distributions tranches
    uint256[] public _tranches;

    // amount of blocks per tranche
    uint256 public _trancheDuration;

    // safety guard in case somethings goes wrong
    // the contract can be halted
    bool internal _locked;

    function initialize(
        uint256 startBlock,
        uint256 duration,
        address rewardToken,
        address swapToken
    ) public virtual initializer {
        __Ownable_init();
        __Pausable_init();
        utilityToken = IERC20(rewardToken);
        holderToken = IERC20Burnable(swapToken);
        _calculateTranches(startBlock, duration);
        _locked = false;
    }

    /* view functions */
    /**
     * @dev Returns current vested amount of utility tokens
     * @return pendingRewards amount of accrued / swappable utility tokens
     **/
    function getPendingUtilityTokens()
        external
        view
        returns (uint256 pendingRewards)
    {
        pendingRewards = _getPendingUtilityTokens(_msgSender());
    }

    /**
     * @dev Returns the amount of accrued holder tokens for the current user
     * @return pendingHolderTokens amount of accrued / claimable holder tokens
     * @return tranches amount of claimable trances (max 3)
     **/
    function getPendingHolderTokens()
        public
        view
        returns (uint256 pendingHolderTokens, uint8 tranches)
    {
        // return 0 if tranches are not set or first tranche is still in the future
        if (_tranches[0] == 0 || _tranches[0] >= block.number) return (0, 0);

        // fetch users data
        UserData storage user = _userData[_msgSender()];
        // if user has no rewards assigned, return 0
        if (_userData[_msgSender()].totalRewards == 0) return (0, 0);

        // calculate the amount of holder tokens per tranche
        uint256 trancheAmount = user.totalRewards.div(_tranches.length);

        // check every tranch if it can be claimed
        for (uint256 i = 0; i < _tranches.length; i++) {
            // tranches start block needs to be in the bast and needs to be unclaimed
            if (block.number > _tranches[i] && user.claimedTranches <= i) {
                // increase the amount of pending holder tokens
                pendingHolderTokens = pendingHolderTokens.add(trancheAmount);
                // increase the amount of pending tranches
                tranches++;
            }
        }
    }

    /**
     * @dev Helper function to check if a user is eligible for pre sale vesting
     * @param user address to check for eligibility
     * @return bool returns true if eligible
     **/
    function isUserEligible(address user) external view returns (bool) {
        return (_userData[user].totalRewards > 0);
    }

    /**
     * @dev Convenience function to check the block number for the next tranche
     * @return tranche block.number of the start of this tranche. 0 if finished
     **/
    function getNextHolderTokenTranche()
        external
        view
        returns (uint256 tranche)
    {
        for (uint256 i = 0; i < _tranches.length; i++) {
            if (block.number < _tranches[i]) return _tranches[i];
        }
        return 0;
    }

    /**
     * @dev Returns whether the contract is currently locked
     * @return bool Return value is true, if the contract is locked
     **/
    function getLocked() public view returns (bool) {
        return _locked;
    }

    /* mutating functions */
    /**
     * @dev Claim all pending holder tokens for the requesting user
     **/
    function claimHolderTokens() external whenNotPaused notLocked {
        require(_userData[msg.sender].totalRewards > 0, "NOT_WHITELISTED");
        // fetch pending holder tokens
        (uint256 pendingRewards, uint8 tranches) = getPendingHolderTokens();
        // return if none exist
        require(pendingRewards > 0, "NO_PENDING_REWARDS");

        // check that the contract has sufficient holder tokens to send
        require(
            holderToken.balanceOf(address(this)) >= pendingRewards,
            "EXCEEDS_AVAIL_HT"
        );

        // update user data with the amount of claimed tranches
        _userData[_msgSender()].claimedTranches =
            _userData[_msgSender()].claimedTranches +
            tranches;

        // sent holder tokens to user
        holderToken.safeTransfer(_msgSender(), pendingRewards);
    }

    /**
     * @dev Swaps desired `amount` of holder tokens to utility tokens. The amount
     * cannot exceed the users current pending / accrued utility tokens.
     * Holder tokens will be burned in the process and swap is always 1:1
     * @param amount Amount of holder tokens to be swapped to utility tokens */
    function swapHolderTokensForUtility(uint256 amount)
        external
        whenNotPaused
        notLocked
    {
        require(_userData[msg.sender].totalRewards > 0, "NOT_WHITELISTED");
        // fetch pending utility tokens
        uint256 pendingRewards = _getPendingUtilityTokens(_msgSender());
        // return if no utility tokens are ready to be vested
        require(pendingRewards > 0, "NO_PENDING_REWARDS");
        // currently vested utility tokens are the maximum to be swapped
        // return if the desired amount exceeds the currently vested utility tokens
        require(pendingRewards >= amount, "AMOUNT_EXCEEDS_REWARDS");
        // check that the contract has sufficient utility tokens to send
        require(
            utilityToken.balanceOf(address(this)) >= amount,
            "EXCEEDS_AVAILABLE_TOKENS"
        );

        // update users claimed amount of utility tokens. these will be removed from the
        // pending tokens
        _userData[_msgSender()].claimedRewards = _userData[_msgSender()]
            .claimedRewards
            .add(amount);

        // transfer holder tokens from user to contract
        holderToken.safeTransferFrom(_msgSender(), address(this), amount);
        // burn holder tokens
        holderToken.burn(amount);
        // send same amount of utility tokens to user
        utilityToken.safeTransfer(_msgSender(), amount);
    }

    /* internal functions */
    /**
     * @dev This function will calculate the start blocks for each tranche
     * @param startBlock start of the vesting contract
     * @param duration Amount of blocks per tranche*/
    function _calculateTranches(uint256 startBlock, uint256 duration) internal {
        // start block cannot be 0
        require(startBlock > 0, "NO_START_BLOCK");
        // duration of tranches needs to be bigger than 0
        require(duration > 0, "NO_DURATION");

        // set tranche duration
        _trancheDuration = duration;
        // tranche 1 starts at start
        _tranches.push(startBlock);
        // tranche 2 starts `duration` amount of blocks after the first tranche
        _tranches.push(startBlock.add(duration));
        // tranche 3 starts `duration` amount of blocks after second tranche
        _tranches.push(startBlock.add(duration.mul(2)));
        // tranche 3 starts `duration` amount of blocks after third tranche
        _tranches.push(startBlock.add(duration.mul(3)));
    }

    /**
     * @dev The actual internal function that is used to calculate the accrued
     * utility tokens, ready for vesting of a user
     * @param user the address to check for pending utility tokens
     * @return pendingRewards amount of accrued utility tokens up to the current block
     **/
    function _getPendingUtilityTokens(address user)
        internal
        view
        returns (uint256 pendingRewards)
    {
        // return 0 if tranches are not set or first tranche is still in the future
        if (_tranches[0] == 0 || _tranches[0] >= block.number) return 0;

        // fetch users data
        UserData storage userData = _userData[user];
        // if user has no rewards assigned, return 0
        if (userData.totalRewards == 0) return 0;

        // calculate the multiplier, used to calculate the accrued utility tokens
        // from start of vesting to current block
        uint256 multiplier = block.number.sub(_tranches[0]);
        // calculate the maximal multiplier, to be used as threshold, so we
        // don't calculate more rewards, after vesting end reached
        uint256 maxDuration = _trancheDuration.mul(_tranches.length);
        // use multiplier if it no exceeds maximum. otherwise use max multiplier
        multiplier = (multiplier <= maxDuration) ? multiplier : maxDuration;

        // calculate the users pending / accrued utility tokens
        // based on users rewards per block and the given multiplier.
        // remove already claimed rewards by swapping holder tokens
        // for utility tokens
        uint256 rewardsPerBlock = userData.totalRewards.div(maxDuration);
        uint256 totalReward = multiplier.mul(rewardsPerBlock).add(
            userData.savedRewards
        );
        pendingRewards = totalReward.sub(userData.claimedRewards);
    }

    /* control functions */
    /**
     * @dev Convenience function to add a list of users to be eligible for vesting
     * @param users list of addresses for eligible users
     * @param rewards list of total rewards for the users
     **/
    function addMultipleUserVestings(
        address[] calldata users,
        uint256[] calldata rewards
    ) external onlyOwner {
        // check that user array is not empty
        require(users.length > 0, "NO_USERS");
        // check that rewards array is not empty
        require(rewards.length > 0, "NO_VESTING_DATA");
        // check that user and reward array a equal length
        require(users.length == rewards.length, "PARAM_NOT_EQ_LENGTH");

        // loop through the list and call the default function to add new vestings
        for (uint8 i = 0; i < users.length; i++) {
            addUserVesting(users[i], rewards[i]);
        }
    }

    /**
     * @dev Adds a new user eligible for vesting. Automatically calculates rewardsPerBlock,
     * based on the tranches and tranche duration
     * @param user address of eligible user
     * @param totalRewards amount of rewards to be vested for this user
     **/
    function addUserVesting(address user, uint256 totalRewards)
        public
        onlyOwner
    {
        // check that address is not empty
        require(user != address(0), "ZERO_ADDRESS");
        // check that user has rewards to receive
        require(totalRewards > 0, "NO_REWARDS");
        // check that user does not exist yet
        require(_userData[user].totalRewards == 0, "EXISTING_USER");

        // start block is start of tranche one
        uint256 startBlock = _tranches[0];
        // end block is tranche three + tranche duration
        uint256 endBlock = _tranches[_tranches.length - 1].add(
            _trancheDuration
        );

        // check that current block is still below end of vesting
        require(block.number < endBlock, "VESTING_FINISHED");
        // make sure that start block is smaller than end block
        require(endBlock > startBlock, "INVALID_START_BLOCK");

        // create user data object
        UserData memory newUserData;
        newUserData.totalRewards = totalRewards;
        _userData[user] = newUserData;
    }

    /**
     * @dev should allow contract's owner add more tranches
     * @param _tranchesAmount amount of tranches want to add: 1, 2, 3 ...
     */
    function addTranches(uint256 _tranchesAmount) external onlyOwner {
        uint256 lastTranches = _tranches[_tranches.length - 1];
        for (uint256 i = 0; i < _tranchesAmount; i++) {
            _tranches.push(lastTranches.add(_trancheDuration));
            lastTranches = _tranches[_tranches.length - 1];
        }
    }

    /**
     * @dev pause smart contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause smart contract
     */
    function unPause() public onlyOwner {
        _unpause();
    }

    function emergencyWithDrawToken(address token, address to)
        external
        whenPaused
        onlyOwner
    {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
    }

    /**
     * @dev Remove eligibility of a user. Either deactivate completely or optionally leave the already
     * accrued utility tokens up for claiming, but do not accrue any further tokens.
     * @param user Address of the user to remove
     * @param keepVestedTokens If true, the user will still be able to claim / swap already accrued token rewards. But won't accrue more.
     **/
    function removeUserVesting(address user, bool keepVestedTokens)
        external
        onlyOwner
    {
        // check that user address is not empty
        require(user != address(0), "ADDRESS_ZERO");
        // check that user is existing and currently eligible
        require(_userData[user].totalRewards > 0, "INVALID_USER");

        // fetch user data
        UserData storage userData = _userData[user];

        // store users pending / accrued rewards, if `keepVestedTokens` is true. Otherwise set to zero
        userData.savedRewards = (keepVestedTokens == true)
            ? userData.savedRewards.add(_getPendingUtilityTokens(user))
            : 0;
        // set users total rewards to users saved rewards, if `keepVestedTokens` is true. Otherwise set to zero
        userData.totalRewards = (keepVestedTokens == true)
            ? userData.savedRewards.add(userData.claimedRewards)
            : 0;
    }

    function setLocked(bool locked) external onlyOwner {
        require(locked != _locked, "SAME_VALUE");

        _locked = locked;
    }

    function setDuration(uint256 _newDuration) external onlyOwner { 
        _trancheDuration = _newDuration;
    }

    /* modifiers */
    modifier notLocked() {
        require(_locked == false, "LOCKED");
        _;
    }
}
