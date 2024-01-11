// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./TokenDistributor.sol";

/**
 * @title FeeSharingSystem
 * @notice It handles the distribution of fees using
 * WETH along with the auto-compounding of SCRD.
 */
contract FeeSharingSystem is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 shares; // shares of token staked
        uint256 userRewardPerTokenPaid; // user reward per token paid
        uint256 rewards; // pending rewards
        uint256 rewardsWETH;  //pending rewards with WETH
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    IERC20 public immutable ScarDustToken;

    IERC20 public immutable rewardToken;

    TokenDistributor public immutable tokenDistributor;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last reward adjustment block number
    uint256 public lastRewardAdjustment;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalShares;

    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, uint256 harvestedAmount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(uint256 numberBlocks, uint256 rewardPerBlock, uint256 reward);
    event Withdraw(address indexed user, uint256 amount, uint256 harvestedAmount);

    /**
     * @notice Constructor
     * @param _ScarDustToken address of the token staked (SCRD)
     * @param _rewardToken address of the reward token
     * @param _tokenDistributor address of the token distributor contract
     */
    constructor(
        address _ScarDustToken,
        address _rewardToken,
        address _tokenDistributor
    ) {
        rewardToken = IERC20(_rewardToken);
        ScarDustToken = IERC20(_ScarDustToken);
        tokenDistributor = TokenDistributor(_tokenDistributor);
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     * @param amount amount to deposit (in SCRD)
     * @param claimRewardToken whether to claim reward tokens
     * @dev There is a limit of 1 SCRD per deposit to prevent potential manipulation of current shares
     */
    function deposit(uint256 amount, bool claimRewardToken) external nonReentrant {
        require(amount >= PRECISION_FACTOR, "Deposit: Amount must be >= 1 SCARDUST");

        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve total amount staked by this contract
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Transfer SCRD tokens to this address
        ScarDustToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentShares;

        // Calculate the number of shares to issue for the user
        if (totalShares != 0) {
            currentShares = (amount * totalShares) / totalAmountStaked;
            // This is a sanity check to prevent deposit for 0 shares
            require(currentShares != 0, "Deposit: Fail");
        } else {
            currentShares = amount;
        }

        // Adjust internal shares
        userInfo[msg.sender].shares += currentShares;
        totalShares += currentShares;

        uint256 scarRewards;

        if (claimRewardToken) {
            // Fetch pending rewards
            scarRewards = userInfo[msg.sender].rewards;

            if (scarRewards > 0) {
                userInfo[msg.sender].rewards = 0;
                rewardToken.safeTransfer(msg.sender, scarRewards);
            }
        }

        // Verify SCRD token allowance and adjust if necessary
        _checkAndAdjustSCRDTokenAllowanceIfRequired(amount, address(tokenDistributor));

        // Deposit user amount in the token distributor contract
        tokenDistributor.deposit(amount);

        emit Deposit(msg.sender, amount, scarRewards);
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function harvest() external nonReentrant {
        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve pending rewards
        uint256 scarRewards = userInfo[msg.sender].rewards;
        uint256 wethRewards = userInfo[msg.sender].rewardsWETH;
        // If pending rewards are null, revert
        require(scarRewards > 0, "Harvest: Pending rewards must be > 0");

        // Adjust user rewards and transfer
        userInfo[msg.sender].rewards = 0;

        // Transfer reward token to sender
        rewardToken.safeTransfer(msg.sender, wethRewards);
        ScarDustToken.safeTransfer(msg.sender, scarRewards);

        emit Harvest(msg.sender, scarRewards);
    }

    /**
     * @notice Withdraw staked tokens (and collect reward tokens if requested)
     * @param shares shares to withdraw
     * @param claimRewardToken whether to claim reward tokens
     */
    function withdraw(uint256 shares, bool claimRewardToken) external nonReentrant {
        require(
            (shares > 0) && (shares <= userInfo[msg.sender].shares),
            "Withdraw: Shares equal to 0 or larger than user shares"
        );

        _withdraw(shares, claimRewardToken);
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     * @param claimRewardToken whether to claim reward tokens
     */
    function withdrawAll(bool claimRewardToken) external nonReentrant {
        _withdraw(userInfo[msg.sender].shares, claimRewardToken);
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(uint256 reward, uint256 rewardDurationInBlocks) external onlyOwner {
        // Adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = reward / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (reward + ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        emit NewRewardPeriod(rewardDurationInBlocks, currentRewardPerBlock, reward);
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user) external view returns (uint256) {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Calculate value of SCRD for a user given a number of shares owned
     * @param user address of the user
     */
    function calculateSharesValueInSCRD(address user) external view returns (uint256) {
        // Retrieve amount staked
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Adjust for pending rewards
        totalAmountStaked += tokenDistributor.calculatePendingRewards(address(this));

        // Return user pro-rata of total shares
        return userInfo[user].shares == 0 ? 0 : (totalAmountStaked * userInfo[user].shares) / totalShares;
    }

    /**
     * @notice Calculate price of one share (in SCRD token)
     * Share price is expressed times 1e18
     */
    function calculateSharePriceInSCRD() external view returns (uint256) {
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Adjust for pending rewards
        totalAmountStaked += tokenDistributor.calculatePendingRewards(address(this));

        return totalShares == 0 ? PRECISION_FACTOR : (totalAmountStaked * PRECISION_FACTOR) / (totalShares);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user) internal view returns (uint256) {
        return
            ((userInfo[user].shares * (_rewardPerToken() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    function _calculatePendingRewardsWETH(address user) internal view returns (uint256) {
        return
            ((userInfo[user].shares * (_rewardPerTokenWETH() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewardsWETH;
    }

    /**
     * @notice Check current allowance and adjust if necessary
     * @param _amount amount to transfer
     * @param _to token to transfer
     */
    function _checkAndAdjustSCRDTokenAllowanceIfRequired(uint256 _amount, address _to) internal {
        if (ScarDustToken.allowance(address(this), _to) < _amount) {
            ScarDustToken.approve(_to, type(uint256).max);
        }
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per token
     */
    function _rewardPerToken() internal view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalShares;
    }

    function _rewardPerTokenWETH() internal view returns (uint256) {

        uint256 totalsupply = ScarDustToken.totalSupply();

        if (totalsupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalsupply;
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerToken();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].rewardsWETH = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens (and collect reward tokens if requested)
     * @param shares shares to withdraw
     * @param claimRewardToken whether to claim reward tokens
     */
    function _withdraw(uint256 shares, bool claimRewardToken) internal {
        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve total amount staked and calculated current amount (in SCRD)
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));
        uint256 currentAmount = (totalAmountStaked * shares) / totalShares;

        userInfo[msg.sender].shares -= shares;
        totalShares -= shares;

        // Withdraw amount equivalent in shares
        tokenDistributor.withdraw(currentAmount);

        uint256 scarRewards;

        if (claimRewardToken) {
            // Fetch pending rewards
            scarRewards = userInfo[msg.sender].rewards;

            if (scarRewards > 0) {
                userInfo[msg.sender].rewards = 0;
                rewardToken.safeTransfer(msg.sender, scarRewards);
            }
        }

        // Transfer SCRD tokens to sender
        ScarDustToken.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, scarRewards);
    }
}
