// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title IUnifarmNFTManagerUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm NFT Manager

interface IUnifarmNFTManagerUpgradeable {
    /**
     * @notice stake on unifarm
     * @dev make sure approve before calling this function
     * @dev minting NFT's
     * @param cohortId cohort contract address
     * @param referralAddress referral address
     * @param farmToken farm token address
     * @param sAmount staking amount
     * @param farmId cohort farm Id
     * @return tokenId the minted NFT Token Id
     */

    function stakeOnUnifarm(
        address cohortId,
        address referralAddress,
        address farmToken,
        uint256 sAmount,
        uint32 farmId
    ) external returns (uint256 tokenId);

    /**
     * @notice a payable function use to unstake farm tokens
     * @dev burn NFT's
     * @param tokenId NFT token Id
     */

    function unstakeOnUnifarm(uint256 tokenId) external payable;

    /**
     * @notice claim rewards without removing the pricipal staked amount
     * @param tokenId NFT tokenId
     */

    function claimOnUnifarm(uint256 tokenId) external payable;

    /**
     * @notice function is use to buy booster pack
     * @param cohortId cohort address
     * @param bpid  booster pack id to purchase booster
     * @param tokenId NFT tokenId
     */

    function buyBoosterPackOnUnifarm(
        address cohortId,
        uint256 bpid,
        uint256 tokenId
    ) external payable;

    /**
     * @notice use to stake + buy booster pack on unifarm cohort
     * @dev make sure approve before calling this function
     * @dev minting NFT's
     * @param cohortId cohort Address
     * @param referralAddress referral wallet address
     * @param farmToken farm token address
     * @param bpid booster package id
     * @param sAmount stake amount
     * @param farmId farm id
     */

    function stakeAndBuyBoosterPackOnUnifarm(
        address cohortId,
        address referralAddress,
        address farmToken,
        uint256 bpid,
        uint256 sAmount,
        uint32 farmId
    ) external payable returns (uint256 tokenId);

    /**
     * @notice use to burn portion on unifarm in very rare situation
     * @dev use by only owner access
     * @param user user wallet address
     * @param tokenId NFT tokenId
     */

    function emergencyBurn(address user, uint256 tokenId) external;

    /**
     * @notice update fee structure for protocol
     * @dev can only be called by the current owner
     * @param feeWalletAddress_ - new fee Wallet address
     * @param feeAmount_ - new fee amount for protocol
     */

    function updateFeeConfiguration(address payable feeWalletAddress_, uint256 feeAmount_) external;

    /**
     * @notice event triggered on each update of protocol fee structure
     * @param feeWalletAddress fee wallet address
     * @param feeAmount protocol fee Amount
     */

    event FeeConfigurtionAdded(address indexed feeWalletAddress, uint256 feeAmount);
}
