// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

interface IUniswapV3Staker {

    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param refundee The address which receives any remaining reward tokens when the incentive is ended
    struct IncentiveKey {
        address rewardToken;
        address pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
    }

    /// @notice Returns information about a deposited NFT
    /// @return owner The owner of the deposited NFT
    /// @return numberOfStakes Counter of how many incentives for which the liquidity is staked
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function deposits(uint256 tokenId)
    external
    view
    returns (
        address owner,
        uint48 numberOfStakes,
        int24 tickLower,
        int24 tickUpper
    );

    /// @notice Returns amounts of reward tokens owed to a given address according to the last time all stakes were updated
    /// @param rewardToken The token for which to check rewards
    /// @param owner The owner for which the rewards owed are checked
    /// @return rewardsOwed The amount of the reward token claimable by the owner
    function rewards(address rewardToken, address owner) external view returns (uint256 rewardsOwed);


    /// @notice Creates a new liquidity mining incentive program
    /// @param key Details of the incentive to create
    /// @param reward The amount of reward tokens to be distributed
    function createIncentive(IncentiveKey memory key, uint256 reward) external;

    /// @notice Ends an incentive after the incentive end time has passed and all stakes have been withdrawn
    /// @param key Details of the incentive to end
    /// @return refund The remaining reward tokens when the incentive is ended
    function endIncentive(IncentiveKey memory key) external returns (uint256 refund);

    /// @notice Stakes a Uniswap V3 LP token
    /// @param key The key of the incentive for which to stake the NFT
    /// @param tokenId The ID of the token to stake
    function stakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Unstakes a Uniswap V3 LP token
    /// @param key The key of the incentive for which to unstake the NFT
    /// @param tokenId The ID of the token to unstake
    function unstakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Transfers `amountRequested` of accrued `rewardToken` rewards from the contract to the recipient `to`
    /// @param rewardToken The token being distributed as a reward
    /// @param to The address where claimed rewards will be sent to
    /// @param amountRequested The amount of reward tokens to claim. Claims entire reward amount if set to 0.
    /// @return reward The amount of reward tokens claimed
    function claimReward(
        address rewardToken,
        address to,
        uint256 amountRequested
    ) external returns (uint256 reward);

    /// @notice Withdraws a Uniswap V3 LP token `tokenId` from this contract to the recipient `to`
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    /// @param to The address where the LP token will be sent
    /// @param data An optional data array that will be passed along to the `to` address via the NFT safeTransferFrom
    function withdrawToken(
        uint256 tokenId,
        address to,
        bytes memory data
    ) external;
}
