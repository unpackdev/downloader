// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title IUnifarmCohort Interface
/// @author UNIFARM
/// @notice unifarm cohort external functions
/// @dev All function calls are currently implemented without any side effects

interface IUnifarmCohort {
    /**
    @notice stake handler
    @dev function called by only nft manager
    @param fid farm id where you want to stake
    @param tokenId NFT token Id
    @param account user wallet Address
    @param referralAddress referral address for this stake
   */

    function stake(
        uint32 fid,
        uint256 tokenId,
        address account,
        address referralAddress
    ) external;

    /**
     * @notice unStake handler
     * @dev called by nft manager only
     * @param user user wallet Address
     * @param tokenId NFT Token Id
     * @param flag 1, if owner is caller
     */

    function unStake(
        address user,
        uint256 tokenId,
        uint256 flag
    ) external;

    /**
     * @notice allow user to collect rewards before cohort end
     * @dev called by NFT manager
     * @param user user address
     * @param tokenId NFT Token Id
     */

    function collectPrematureRewards(address user, uint256 tokenId) external;

    /**
     * @notice purchase a booster pack for particular token Id
     * @dev called by NFT manager or owner
     * @param user user wallet address who is willing to buy booster
     * @param bpid booster pack id to purchase booster
     * @param tokenId NFT token Id which booster to take
     */

    function buyBooster(
        address user,
        uint256 bpid,
        uint256 tokenId
    ) external;

    /**
     * @notice set portion amount for particular tokenId
     * @dev called by only owner access
     * @param tokenId NFT token Id
     * @param stakedAmount new staked amount
     */

    function setPortionAmount(uint256 tokenId, uint256 stakedAmount) external;

    /**
     * @notice disable booster for particular tokenId
     * @dev called by only owner access.
     * @param tokenId NFT token Id
     */

    function disableBooster(uint256 tokenId) external;

    /**
     * @dev rescue Ethereum
     * @param withdrawableAddress to address
     * @param amount to withdraw
     * @return Transaction status
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external returns (bool);

    /**
     * @dev rescue all available tokens in a cohort
     * @param tokens list of tokens
     * @param amounts list of amounts to withdraw respectively
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @notice obtain staking details
     * @param tokenId - NFT Token id
     * @return fid the cohort farm id
     * @return nftTokenId the NFT token id
     * @return stakedAmount denotes staked amount
     * @return startBlock start block of particular user stake
     * @return endBlock end block of particular user stake
     * @return originalOwner wallet address
     * @return referralAddress the referral address of stake
     * @return isBooster denotes booster availability
     */

    function viewStakingDetails(uint256 tokenId)
        external
        view
        returns (
            uint32 fid,
            uint256 nftTokenId,
            uint256 stakedAmount,
            uint256 startBlock,
            uint256 endBlock,
            address originalOwner,
            address referralAddress,
            bool isBooster
        );

    /**
     * @notice emit on each booster purchase
     * @param nftTokenId NFT Token Id
     * @param user user wallet address who bought the booster
     * @param bpid booster pack id
     */

    event BoosterBuyHistory(uint256 indexed nftTokenId, address indexed user, uint256 bpid);

    /**
     * @notice emit on each claim
     * @param fid farm id.
     * @param tokenId NFT Token Id
     * @param userAddress NFT owner wallet address
     * @param referralAddress referral wallet address
     * @param rValue Aggregated R Value
     */

    event Claim(uint32 fid, uint256 indexed tokenId, address indexed userAddress, address indexed referralAddress, uint256 rValue);

    /**
     * @notice emit on each stake
     * @dev helps to derive referrals of unifarm cohort
     * @param tokenId NFT Token Id
     * @param referralAddress referral Wallet Address
     * @param stakedAmount user staked amount
     * @param fid farm id
     */

    event ReferedBy(uint256 indexed tokenId, address indexed referralAddress, uint256 stakedAmount, uint32 fid);
}
