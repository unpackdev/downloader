// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IERC20Upgradeable.sol";

import "./ICompLike.sol";

import "./IDrawBeacon.sol";
import "./ITicket.sol";

interface IPrizePoolV2 {
    /**
     * @notice The user stake info struct.
     * @dev    The user stake info struct used to store information about users'
     *         stakes and rewards.
     * @param reward Claimable reward in ASX tokens that belongs to a user (with
     *               18 decimals accuracy).
     * @param former Coefficient that is used to calculate the reward in ASX
     *               tokens with different staked amount (when staked amount
     *               changes, with 18 decimals accuracy).
     * @param lastClaimed Timestamp of last claimed of ASX tokens.
     * @param esAsxLastClaimed Timestamp of last claimed of esASX tokens.
     * @param esAsxBoostableReward Claimable reward in esASX tokens that belongs
     *                             to a user (with 18 decimals accuracy). Can be
     *                             boosted.
     * @param esAsxBoostlessReward Claimable reward in esASX tokens that belongs
     *                             to a user. Can't be boosted.
     * @param esAsxFormer Coefficient that is used to calculate the reward in
     *                    esASX tokens with different staked amount (when staked
     *                    amount changes, with 18 decimals accuracy).
     */
    struct UserStakeInfo {
        uint256 reward;
        uint256 former;
        uint32 lastClaimed;
        uint32 esAsxLastClaimed;
        uint256 esAsxBoostableReward;
        uint256 esAsxBoostlessReward;
        uint256 esAsxFormer;
    }

    /// @dev Event emitted when controlled token is added
    event ControlledTokenAdded(ITicket indexed token);

    event AwardCaptured(uint256 amount);

    /// @dev Event emitted when assets are deposited
    event Deposited(address indexed operator, address indexed to, ITicket indexed token, uint256 amount);

    /// @dev Event emitted when interest is awarded to a winner
    event Awarded(address indexed winner, ITicket indexed token, uint256 amount);

    /// @dev Event emitted when external ERC20s are awarded to a winner
    event AwardedExternalERC20(address indexed winner, address indexed token, uint256 amount);

    /// @dev Event emitted when external ERC20s are transferred out
    event TransferredExternalERC20(address indexed to, address indexed token, uint256 amount);

    /// @dev Event emitted when external ERC721s are awarded to a winner
    event AwardedExternalERC721(address indexed winner, address indexed token, uint256[] tokenIds);

    /// @dev Event emitted when assets are withdrawn
    event Withdrawal(
        address indexed operator,
        address indexed from,
        ITicket indexed token,
        uint256 amount,
        uint256 redeemed,
        uint256 fee
    );

    /// @dev Event emitted when the Balance Cap is set
    event BalanceCapSet(uint256 balanceCap);

    /// @dev Event emitted when the Liquidity Cap is set
    event LiquidityCapSet(uint256 liquidityCap);

    /// @dev Event emitted when the Prize Flush is set
    event PrizeFlushSet(address indexed prizeFlush);

    /// @dev Event emitted when the Ticket is set
    event TicketSet(ITicket indexed ticket);

    /// @dev Event emitted when the DrawBeacon is set
    event DrawBeaconSet(IDrawBeacon indexed drawBeacond);

    /// @dev Emitted when there was an error thrown awarding an External ERC721
    event ErrorAwardingExternalERC721(bytes error);

    /// @dev Event emitted when the Reward Token is set
    event RewardTokenSet(IERC20Upgradeable indexed rewardToken);

    /// @dev Event emitted when the ASX Reward Per Second is set
    event AsxRewardPerSecondSet(uint256 asxRewardPerSecond);

    /// @dev Event emitted when the esASX Reward Per Second is set
    event EsAsxRewardPerSecondSet(uint256 esAsxRewardPerSecond);

    /// @dev Event emitted when the liquidation threshold is set
    event LiquidationThresholdSet(uint16 liquidationThreshold);

    /// @dev Event emitted when the reward updated
    event RewardUpdated(uint64 indexed lastUpdated);

    /// @dev Event emitted when the First Lido Rebase Timestamp is set
    event FirstLidoRebaseTimestampSet(uint32 firstLidoRebaseTimestamp);

    /// @dev Event emmited when the Lido APR is set
    event LidoAPRSet(uint16 lidoAPR);

    /// @dev Event emmited when the Free Exit Duration is set
    event FreeExitDurationSet(uint32 freeExitDuration);

    /// @notice Deposit assets into the Prize Pool in exchange for tokens
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    function depositTo(address to, uint256 amount) external;

    /// @notice Deposit assets into the Prize Pool in exchange for tokens,
    /// then sets the delegate on behalf of the caller.
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    /// @param delegate The address to delegate to for the caller
    function depositToAndDelegate(address to, uint256 amount, address delegate) external;

    /// @notice Withdraw assets from the Prize Pool instantly.
    /// @param from The address to redeem tokens from.
    /// @param amount The amount of tokens to redeem for assets.
    /// @return The actual amount withdrawn
    function withdrawFrom(address from, uint256 amount) external returns (uint256);

    /// @notice Called by the ticket to update user's reward and former in time
    ///         of transfer.
    /// @param _user The user where need to update reward and former.
    /// @param _beforeBalance The balance of user before transfer.
    /// @param _afterBalance The balance of user after transfer.
    function updateUserRewardAndFormer(address _user, uint256 _beforeBalance, uint256 _afterBalance) external;

    /// @notice Claim reward in ASX and esASX tokens that distributes on users'
    ///         deposits.
    /// @param _user The user for whom to claim reward.
    function claim(address _user) external;

    /// @notice Liquidates a users boosted rewards in esASX tokens for the user.
    /// @param _users The array of users for whom to execute a liquidation. If equals to zero address liquidation will
    ///               be executed for esSEX tokens from `availableForLiquidationEsAsx` pool.
    /// @param _amounts The array of amounts of esASX tokens to liquidate.
    function liquidate(address[] calldata _users, uint256[] calldata _amounts) external payable;

    /// @notice Called by the prize flush to award prizes.
    /// @dev The amount awarded must be less than the awardBalance()
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of assets to be awarded
    function award(address to, uint256 amount) external;

    /// @notice Returns the balance that is available to award.
    /// @dev captureAwardBalance() should be called first
    /// @return The total amount of assets to be awarded for the current prize
    function awardBalance() external view returns (uint256);

    /// @notice Captures any available interest as award balance.
    /// @dev This function also captures the reserve fees.
    /// @return The total amount of assets to be awarded for the current prize
    function captureAwardBalance() external returns (uint256);

    /// @dev Checks with the Prize Pool if a specific token type may be awarded
    ///      as an external prize
    /// @param externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function canAwardExternal(address externalToken) external view returns (bool);

    // @dev Returns the total underlying balance of all assets. This includes
    ///     both principal and interest.
    /// @return The underlying balance of assets
    function balance() external returns (uint256);

    /**
     * @notice Read internal Ticket accounted balance.
     * @return uint256 accountBalance
     */
    function getAccountedBalance() external view returns (uint256);

    /**
     * @notice Read internal balanceCap variable
     */
    function getBalanceCap() external view returns (uint256);

    /**
     * @notice Read internal liquidityCap variable
     */
    function getLiquidityCap() external view returns (uint256);

    /**
     * @notice Read ticket variable
     */
    function getTicket() external view returns (ITicket);

    /**
     * @notice Read drawBeacond variable
     */
    function getDrawBeacon() external view returns (IDrawBeacon);

    /**
     * @notice Read prize flush variable
     */
    function getPrizeFlush() external view returns (address);

    /**
     * @notice Read rewardToken variable
     */
    function getRewardToken() external view returns (IERC20Upgradeable);

    /**
     * @notice Read token variable
     */
    function getToken() external view returns (address);

    /**
     * @notice Read lastUpdated variable
     */
    function getLastUpdated() external view returns (uint64);

    /**
     * @notice Read asxRewardPerSecond variable
     */
    function getAsxRewardPerSecond() external view returns (uint256);

    /**
     * @notice Read asxRewardPerShare variable
     */
    function getAsxRewardPerShare() external view returns (uint256);

    /**
     * @notice Read freeExitDuration variable
     */
    function getFreeExitDuration() external view returns (uint32);

    /**
     * @notice Read deploymentTimestamp variable
     */
    function getDeploymentTimestamp() external view returns (uint32);

    /**
     * @notice Read firstLidoRebaseTimestamp variable
     */
    function getFirstLidoRebaseTimestamp() external view returns (uint32);

    /**
     * @notice Read lidoAPR variable
     */
    function getLidoAPR() external view returns (uint16);

    /**
     * @notice Read userStakeInfo variable
     * @param user The address of the user to retrieve stake info about
     */
    function getUserStakeInfo(address user) external view returns (UserStakeInfo memory);

    /**
     * @notice Read distributionEnd variable
     */
    function getDistributionEnd() external view returns (uint32);

    /**
     * @notice Calculates actual claimable amount of ASX and esASX tokens for
     *         the user
     * @param user A user for whom to calculate claimable ASX and esASX rewards.
     * @return asxReward Claimable ASX tokens amount.
     * @return esAsxReward Claimable esASX tokens amount.
     */
    function getClaimableRewards(address user) external view returns (uint256 asxReward, uint256 esAsxReward);

    /// @dev Checks if a specific token is controlled by the Prize Pool
    /// @param controlledToken The address of the token to check
    /// @return True if the token is a controlled token, false otherwise
    function isControlled(ITicket controlledToken) external view returns (bool);

    /// @notice Called by the Prize-Flush to transfer out external ERC20 tokens
    /// @dev Used to transfer out tokens held by the Prize Pool.  Could be
    ///      liquidated, or anything.
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external asset token being
    ///                      awarded
    /// @param amount The amount of external assets to be awarded
    function transferExternalERC20(address to, address externalToken, uint256 amount) external;

    /// @notice Called by the Prize-Flush to award external ERC20 prizes
    /// @dev Used to award any arbitrary tokens held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external asset token being
    ///                      awarded
    /// @param amount The amount of external assets to be awarded
    function awardExternalERC20(address to, address externalToken, uint256 amount) external;

    /// @notice Called by the prize flush to award external ERC721 prizes
    /// @dev Used to award any arbitrary NFTs held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external NFT token being awarded
    /// @param tokenIds An array of NFT Token IDs to be transferred
    function awardExternalERC721(address to, address externalToken, uint256[] calldata tokenIds) external;

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @dev If a user wins, his balance can go over the cap. He will be able to
    ///      withdraw the excess but not deposit.
    /// @dev Needs to be called after deploying a prize pool to be able to
    ///      deposit into it.
    /// @param balanceCap New balance cap.
    /// @return True if new balance cap has been successfully set.
    function setBalanceCap(uint256 balanceCap) external returns (bool);

    /// @notice Allows the Governor to set a cap on the amount of liquidity that
    ///         the pool can hold
    /// @param liquidityCap The new liquidity cap for the prize pool
    function setLiquidityCap(uint256 liquidityCap) external;

    /// @notice Sets the reward per second for the prize pool that will be used
    ///         for ASX tokens distribution. Only callable by the owner.
    /// @param asxRewardPerSecond The new reward per second in ASX tokens.
    function setAsxRewardPerSecond(uint256 asxRewardPerSecond) external;

    /// @notice Sets the reward per second for the prize pool that will be used
    ///         for esASX tokens distribution. Only callable by the owner.
    /// @param esAsxRewardPerSecond The new reward per second in esASX tokens.
    function setEsAsxRewardPerSecond(uint256 esAsxRewardPerSecond) external;

    /// @notice Sets a new liquidation threshold. Only callable by the owner.
    /// @param liquidationThreshold Minimum threshold for partial liquidation of
    ///                             users' boosts.
    function setLiquidationThreshold(uint16 liquidationThreshold) external;

    /// @notice Set prize pool ticket.
    /// @param ticket Address of the ticket to set.
    /// @return True if ticket has been successfully set.
    function setTicket(ITicket ticket) external returns (bool);

    /// @notice Set draw beacon.
    /// @param drawBeacon DrawBeacon address to set.
    function setDrawBeacon(IDrawBeacon drawBeacon) external;

    /// @notice Set prize flush.
    /// @param prizeFlush PrizeFlush address to set.
    function setPrizeFlush(address prizeFlush) external;

    /// @notice Set a new distribution end timestamp. Only callable by the
    ///         owner.
    /// @param newDistributionEnd A new distribution end timestamp.
    function setDistributionEnd(uint32 newDistributionEnd) external;

    /// @notice Set the free exit duration, in seconds. Only callable by the
    ///         owner.
    /// @param freeExitDuration The duration after finishing of a draw when
    ///                          user can leave the protocol without fee
    ///                          charging (in stETH)
    function setFreeExitDuration(uint32 freeExitDuration) external;

    /// @notice Set APR of the Lido protocol. Only callable by the owner.
    /// @param lidoAPR An APR of the Lido protocol.
    function setLidoAPR(uint16 lidoAPR) external;

    /// @notice Delegate the votes for a Compound COMP-like token held by the
    ///         prize pool.
    /// @param compLike The COMP-like token held by the prize pool that should
    ///                 be delegated.
    /// @param to The address to delegate to.
    function compLikeDelegate(ICompLike compLike, address to) external;
}
