// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./RouterStructs.sol";
import "./IDittoPool.sol";
import "./IDittoRouter.sol";

/**
 * @title Ditto Swap Router Interface
 * @notice Adds to IDittoRouter functions to autoconvert with ETH to WETH to use DittoPools
 */
interface IDittoWethRouter is IDittoRouter {
    // ***************************************************************
    // * ======= FUNCTIONS TO MARKET MAKE: ADD LIQUIDITY =========== *
    // ***************************************************************

    /**
     * @notice Function for liquidity providers to create new Liquidity Positions within the pool by depositing liquidity.
     * @dev Creates a new liquidity position tracking NFT every time. One address can own many LP ID NFTs in the same pool.
     * @dev This function assumes that msg.sender is the owner of the NFTs and Tokens.
     * @dev This function expects that this contract has permission to move NFTs to itself from the owner.
     * @dev The **lpRecipient_** parameter to this function is intended to allow creating positions on behalf of
     * another party. msg.sender can send nfts and tokens to the pool and then have the pool create the liquidity position
     * for someone who is not msg.sender. E.g. `DittoPoolFactory` uses this feature to create a new DittoPool and deposit
     * liquidity into it in one step. NFTs flow from user -> factory -> pool and then lpRecipient_ is set to the user.
     * @dev So `lpRecipient_` can steal liquidity deposited by msg.sender if lpRecipient_ is not set to msg.sender.
     * @dev This function expects ETH to be sent with the call, which will be converted to WETH and deposited into the pool.
     * @param dittoPool_ The DittoPool contract into which liquidity will be deposited.
     * @param lpRecipient_ The address that will receive the LP position NFT.
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to deposit into the pool.
     * @param permitterData_ Data to check that the NFT Token IDs are permitted to deposited into this pool.
     * @param referrer_ The referrer of this liquidity deposit
     * @return lpId The tokenId of the LP position NFT that was minted as a result of this liquidity deposit.
     */
    function createLiquidity(
        IDittoPool dittoPool_,
        address lpRecipient_,
        uint256[] calldata nftIdList_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external payable returns (uint256 lpId);

    /**
     * @notice Function for market makers / liquidity providers to deposit NFTs and ETH into existing LP Positions.
     * @dev Anybody may add liquidity to existing LP Positions, regardless of whether they own the position or not.
     * @dev This function expects that this contract has permission to move NFTs to itself from the owner.
     * @dev This function expects ETH to be sent with the call, which will be converted to WETH and deposited into the pool.
     * @param lpId_ TokenId of existing LP position to add liquidity to. Does not have to be owned by msg.sender!
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to deposit into the pool.
     * @param permitterData_ Data to check that the NFT Token IDs are permitted to deposited into this pool.
     * @param referrer_ The referrer of this liquidity deposit
     */
    function addLiquidity(
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external payable;

    // ***************************************************************
    // * ===== FUNCTIONS TO MARKET MAKE: REMOVE LIQUIDITY ========== *
    // ***************************************************************

    /**
     * @notice Function for liquidity providers to withdraw NFTs and ETH tokens from their LP positions.
     * @dev Can be called to change an existing liquidity position, or remove an LP position by withdrawing all liquidity.
     * @dev May be called by an authorized party (approved on the LP NFT) to withdraw liquidity on behalf of the LP Position owner.
     * @dev this function pulls liquidity first to itself, changes WETH->ETH, then sends ETH & NFTs to the withdrawalAddress_.
     * @dev Obviously, this function expects the dittoPool is one that operates on WETH, not another ERC20 token.
     * @param withdrawalAddress_ the address that will receive the ETH and NFTs withdrawn from the pool.
     * @param lpId_ LP Position TokenID that liquidity is being removed from. Does not have to be owned by msg.sender!
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to withdraw from the pool.
     * @param tokenWithdrawAmount_ The amount of ERC20 tokens the msg.sender wishes to withdraw from the pool.
     */
    function pullLiquidity(
        address payable withdrawalAddress_,
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenWithdrawAmount_
    ) external;

    // ***************************************************************
    // * ================= TRADING ETH FOR STUFF =================== *
    // ***************************************************************

    /**
     * @notice Swaps ETH into specific NFTs using multiple pairs.
     * @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapEthForNfts(
        Swap[] calldata swapList,
        address nftRecipient,
        uint256 deadline
    ) external payable returns (uint256 remainingValue);

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPair
     * @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapEthForNfts(
        RobustSwap[] calldata swapList,
        address nftRecipient,
        uint256 deadline
    ) external payable returns (uint256 remainingValue);

    /**
     * @notice Buys NFTs with ETH and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapEthForNftsAndNftsForTokens(RobustComplexSwap calldata params)
        external
        payable
        returns (uint256 remainingValue, uint256 outputAmount);

    // ***************************************************************
    // * ================= TRADING NFTs FOR STUFF ================== *
    // ***************************************************************

    /**
     * @notice Equivalent to swapNftsForSpecificNftsThroughErc20 on the normal router,
     * but you can't add ETH without making the function payable, so another function is needed
     * @param trade The trade swap information
     * @param minOutput The minimum amount of output tokens that must be received for the transaction not to revert
     * @param outputRecipient Address to receive the resulting NFTs and left over tokens from the transaction
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     */
    function swapNftsForSpecificNftsThroughEth(
        ComplexSwap calldata trade,
        uint256 minOutput,
        address outputRecipient,
        uint256 deadline
    ) external payable returns (uint256 outputAmount);
}
