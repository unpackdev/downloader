// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IUnifarmRewardRegistryUpgradeable {
    /**
     * @notice function is used to distribute cohort rewards
     * @dev only cohort contract can access this function
     * @param cohortId cohort contract address
     * @param userAddress user wallet address
     * @param influencerAddress influencer wallet address
     * @param rValue Aggregated R value
     * @param hasContainsWrappedToken has contain wrap token in rewards
     */

    function distributeRewards(
        address cohortId,
        address userAddress,
        address influencerAddress,
        uint256 rValue,
        bool hasContainsWrappedToken
    ) external;

    /**
     * @notice admin can add more influencers with some percentage
     * @dev can only be called by owner or multicall
     * @param userAddresses list of influencers wallet addresses
     * @param referralPercentages list of referral percentages
     */

    function addInfluencers(address[] memory userAddresses, uint256[] memory referralPercentages) external;

    /**
     * @notice update multicall contract address
     * @dev only called by owner access
     * @param newMultiCallAddress new multicall address
     */

    function updateMulticall(address newMultiCallAddress) external;

    /**
     * @notice update default referral percenatge
     * @dev can only be called by owner or multicall
     * @param newRefPercentage referral percentage in 3 decimals
     */

    function updateRefPercentage(uint256 newRefPercentage) external;

    /**
     * @notice set reward tokens for a particular cohort
     * @dev function can be called by only owner
     * @param cohortId cohort contract address
     * @param rewards per block rewards in bytes
     */

    function setRewardTokenDetails(address cohortId, bytes calldata rewards) external;

    /**
     * @notice set reward cap for particular cohort
     * @dev function can be called by only owner
     * @param cohortId cohort address
     * @param rewardTokenAddresses reward token addresses
     * @param rewards rewards available
     * @return Transaction Status
     */

    function setRewardCap(
        address cohortId,
        address[] memory rewardTokenAddresses,
        uint256[] memory rewards
    ) external returns (bool);

    /**
     * @notice rescue ethers
     * @dev can called by only owner in rare sitution
     * @param withdrawableAddress withdrawable address
     * @param amount to send
     * @return Transaction Status
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external returns (bool);

    /**
      @notice withdraw list of erc20 tokens in emergency sitution
      @dev can called by only owner on worst sitution  
      @param withdrawableAddress withdrawble wallet address
      @param tokens list of token address
      @param amounts list of amount to withdraw
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @notice derive reward tokens for a specfic cohort
     * @param cohortId cohort address
     * @return rewardTokens array of reward token address
     * @return pbr array of per block reward
     */

    function getRewardTokens(address cohortId) external view returns (address[] memory rewardTokens, uint256[] memory pbr);

    /**
     * @notice get influencer referral percentage
     * @return referralPercentage the referral percentage
     */

    function getInfluencerReferralPercentage(address influencerAddress) external view returns (uint256 referralPercentage);

    /**
     * @notice emit when referral percetage updated
     * @param newRefPercentage - new referral percentage
     */
    event UpdatedRefPercentage(uint256 newRefPercentage);

    /**
     * @notice set reward token details
     * @param cohortId - cohort address
     * @param rewards - list of token address and rewards
     */
    event SetRewardTokenDetails(address indexed cohortId, bytes rewards);
}
