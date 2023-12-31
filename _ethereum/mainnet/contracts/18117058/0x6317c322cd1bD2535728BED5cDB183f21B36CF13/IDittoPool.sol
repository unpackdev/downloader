// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Fee.sol";
import "./SwapArgs.sol";
import "./LpNft.sol";
import "./FactoryTemplates.sol";
import "./LpIdToTokenBalance.sol";
import "./NftCostData.sol";
import "./IPermitter.sol";

import "./IERC721.sol";
import "./CurveErrorCode.sol";

import "./IOwnerTwoStep.sol";

interface IDittoPool is IOwnerTwoStep {
    // ***************************************************************
    // * =============== ADMINISTRATIVE FUNCTIONS ================== *
    // ***************************************************************

    /**
     * @notice For use in tokenURI function metadata
     * @return curve type of curve
     */
    function bondingCurve() external pure returns (string memory curve);

    /**
     * @notice Used by the Contract Factory to set the initial state & parameters of the pool.
     * @dev Necessarily separate from constructor due to [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167) factory clone paradigm.
     * @param params_ A struct that contains various initialization parameters for the pool. See `PoolTemplate.sol` for details.
     * @param template_ which address was used to clone business logic for this pool.
     * @param lpNft_ The Liquidity Provider Positions NFT contract that tokenizes liquidity provisions in the protocol
     * @param permitter_ Contract to authorize which tokenIds from the underlying nft collection are allowed to be traded in this pool.
     * @dev Set permitter to address(0) to allow any tokenIds from the underlying NFT collection.
     */
    function initPool(
        PoolTemplate calldata params_,
        address template_,
        LpNft lpNft_,
        IPermitter permitter_
    ) external;

    /**
     * @notice Admin function to change the base price charged to buy an NFT from the pair. Each bonding curve uses this differently.
     * @param newBasePrice_ The updated base price
     */
    function changeBasePrice(uint128 newBasePrice_) external;

    /**
     * @notice Admin function to change the delta parameter associated with the bonding curve. Each bonding curve uses this differently. 
     * @param newDelta_ The updated delta
     */
    function changeDelta(uint128 newDelta_) external;

    /**
     * @notice Admin function to change the pool lp fee, set by owner, paid to LPers only when they are the counterparty in a trade
     * @param newFeeLp_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeLpFee(uint96 newFeeLp_) external;

    /**
     * @notice Change the pool admin fee, set by owner, paid to an address of the owner's choosing
     * @param newFeeAdmin_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeAdminFee(uint96 newFeeAdmin_) external;

    /**
     * @notice Change who the pool admin fee for this pool is sent to.
     * @param newAdminFeeRecipient_ New address to send admin fees to
     */
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external;

    // ***************************************************************
    // * ================== LIQUIDITY FUNCTIONS ==================== *
    // ***************************************************************
    /**
     * @notice Function for liquidity providers to create new Liquidity Positions within the pool by depositing liquidity.
     * @dev Provides the liquidity provider with a new liquidity position tracking NFT every time. 
     * @dev This function assumes that msg.sender is the owner of the NFTs and Tokens.
     * @dev This function expects that this contract has permission to move NFTs and tokens to itself from the owner.
     * @dev The **lpRecipient_** parameter to this function is intended to allow creating positions on behalf of
     * another party. msg.sender can send nfts and tokens to the pool and then have the pool create the liquidity position
     * for someone who is not msg.sender. The `DittoPoolFactory` uses this feature to create a new DittoPool and deposit
     * liquidity into it in one step. NFTs flow from user -> factory -> pool and then lpRecipient_ is set to the user.
     * @dev `lpRecipient_` can steal liquidity deposited by msg.sender if lpRecipient_ is not set to msg.sender.
     * @param lpRecipient_ The address that will receive the LP position ownership NFT.
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to deposit into the pool.
     * @param tokenDepositAmount_ The amount of ERC20 tokens msg.sender wishes to deposit into the pool.
     * @param permitterData_ Data to check that the NFT Token IDs are permitted to deposited into this pool if a permitter is set.
     * @return lpId The tokenId of the LP position NFT that was minted as a result of this liquidity deposit.
     */
    function createLiquidity(
        address lpRecipient_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external returns (uint256 lpId);

    /**
     * @notice Function for market makers / liquidity providers to deposit NFTs and ERC20s into existing LP Positions.
     * @dev Anybody may add liquidity to existing LP Positions, regardless of whether they own the position or not.
     * @dev This function expects that this contract has permission to move NFTs and tokens to itself from the msg.sender.
     * @param lpId_ TokenId of existing LP position to add liquidity to. Does not have to be owned by msg.sender!
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to deposit into the pool.
     * @param tokenDepositAmount_ The amount of ERC20 tokens msg.sender wishes to deposit into the pool.
     * @param permitterData_ Data to check that the NFT Token IDs are permitted to deposited into this pool if a permitter is set.
     */
    function addLiquidity(
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external;

    /**
     * @notice Function for liquidity providers to withdraw NFTs and ERC20 tokens from their LP positions.
     * @dev Can be called to change an existing liquidity position, or remove an LP position by withdrawing all liquidity.
     * @dev May be called by an authorized party (approved on the LP NFT) to withdraw liquidity on behalf of the LP Position owner.
     * @param withdrawalAddress_ the address that will receive the ERC20 tokens and NFTs withdrawn from the pool.
     * @param lpId_ LP Position TokenID that liquidity is being removed from. Does not have to be owned by msg.sender if the msg.sender is authorized.
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to withdraw from the pool.
     * @param tokenWithdrawAmount_ The amount of ERC20 tokens the msg.sender wishes to withdraw from the pool.
     */
    function pullLiquidity(
        address withdrawalAddress_,
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenWithdrawAmount_
    ) external;

    // ***************************************************************
    // * =================== TRADE FUNCTIONS ======================= *
    // ***************************************************************

    /**
     * @notice Trade ERC20s for a specific list of NFT token ids.
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
     * This swap is meant for users who want specific IDs. 
     * 
     * @param args_ The arguments for the swap. See SwapArgs.sol for parameters
     * @return inputAmount The actual amount of tokens spent to purchase the NFTs.
     */
    function swapTokensForNfts(
        SwapTokensForNftsArgs calldata args_
    ) external returns (uint256 inputAmount);

    /**
     * @notice Trade a list of allowed nft ids for ERC20s.
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @dev Key difference with sudoswap here:
     * In sudoswap, each market maker has a separate smart contract with their liquidity.
     * To sell to a market maker, you just check if their specific `LSSVMPair` contract has enough money.
     * In DittoSwap, we share different market makers' liquidity in the same pool contract.
     * So this function has an additional parameter `lpIds` forcing the buyer to check
     * off-chain which market maker's LP position that they want to trade with, for each specific NFT
     * that they are selling into the pool. The lpIds array should correspond with the nftIds
     * array in the same order & indexes. e.g. to sell NFT with tokenId 1337 to the market maker who's
     * LP position has id 42, the buyer would call this function with
     * nftIds = [1337] and lpIds = [42].
     *
     * @param args_ The arguments for the swap. See SwapArgs.sol for parameters
     * @return outputAmount The amount of token received
     */
    function swapNftsForTokens(
        SwapNftsForTokensArgs calldata args_
    ) external returns (uint256 outputAmount);

    /**
     * @notice Read-only function used to query the bonding curve for buy pricing info.
     * @param numNfts The number of NFTs to buy out of the pair
     * @param swapData_ Extra data to pass to the curve
     * @return error any errors that would be throw if trying to buy that many NFTs
     * @return newBasePrice the new base price after the trade
     * @return newDelta the new delta after the trade
     * @return inputAmount the amount of token to send to the pool to purchase that many NFTs
     * @return nftCostData the cost data for each NFT purchased
     */
    function getBuyNftQuote(uint256 numNfts, bytes calldata swapData_)
        external
        view
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 inputAmount,
            NftCostData[] memory nftCostData
        );

    /**
     * @notice Read-only function used to query the bonding curve for sell pricing info
     * @param numNfts The number of NFTs to sell into the pair
     * @param swapData_ Extra data to pass to the curve
     * @return error any errors that would be throw if trying to sell that many NFTs
     * @return newBasePrice the new base price after the trade
     * @return newDelta the new delta after the trade
     * @return outputAmount the amount of tokens the pool will send out for selling that many NFTs
     * @return nftCostData the cost data for each NFT sold
     */
    function getSellNftQuote(uint256 numNfts, bytes calldata swapData_)
        external
        view
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 outputAmount,
            NftCostData[] memory nftCostData
        );

    // ***************************************************************
    // * ===================== VIEW FUNCTIONS ====================== *
    // ***************************************************************

    /**
     * @notice returns the status of whether this contract has been initialized
     * @dev see [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167) factory clone paradigm
     * and also `DittoPoolFactory.sol`
     *
     * @return initialized whether the contract has been initialized
     */
    function initialized() external view returns (bool);

    /**
     * @notice returns which DittoPool Template this pool was created with.
     * @dev see [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167) factory clone paradigm
     * @return template the address of the DittoPool template used to create this pool.
     */
    function template() external view returns (address);

    /**
     * @notice Function to determine if a given DittoPool can support muliple LP providers or not.
     * @return isPrivatePool_ boolean value indicating if the pool is private or not
     */
    function isPrivatePool() external view returns (bool isPrivatePool_);

    /**
     * @notice Returns the cumulative fee associated with trading with this pool as a 1e18 based percentage.
     * @return fee_ the total fee(s) associated with this pool, for display purposes.
     */
    function fee() external view returns (uint256 fee_);

    /**
     * @notice Returns the protocol fee associated with trading with this pool as a 1e18 based percentage.
     * @return feeProtocol_ the protocol fee associated with trading with this pool
     */
    function protocolFee() external view returns (uint256 feeProtocol_);

    /**
     * @notice Returns the admin fee given to the pool admin as a 1e18 based percentage.
     * @return adminFee_ the fee associated with trading with any pair of this pool
     */
    function adminFee() external view returns (uint96 adminFee_);

    /**
     * @notice Returns the fee given to liquidity providers for trading with this pool.
     * @return lpFee_ the fee associated with trading with a particular pair of this pool.
     */
    function lpFee() external view returns (uint96 lpFee_);

    /**
     * @notice Returns the delta parameter for the bonding curve associated this pool
     * Each bonding curve uses delta differently, but in general it is used as an input
     *   to determine the next price on the bonding curve.
     * @return delta_ The delta parameter for the bonding curve of this pool
     */
    function delta() external view returns (uint128 delta_);

    /**
     * @notice Returns the base price to sell the next NFT into this pool, base+delta to buy
     * Each bonding curve uses base price differently, but in general it is used as the current price of the pool.
     * @return basePrice_ this pool's current base price
     */
    function basePrice() external view returns (uint128 basePrice_);

    /**
     * @notice Returns the factory that created this pool.
     * @return dittoPoolFactory the ditto pool factory for the contract
     */
    function dittoPoolFactory() external view returns (address);

    /**
     * @notice Returns the address that recieves admin fees from trades with this pool
     * @return adminFeeRecipient The admin fee recipient of this pool
     */
    function adminFeeRecipient() external view returns (address);

    /**
     * @notice Returns the NFT collection that represents liquidity positions in this pool
     * @return lpNft The LP Position NFT collection for this pool
     */
    function getLpNft() external view returns (address);

    /**
     * @notice Returns the nft collection that this pool trades 
     * @return nft_ the address of the underlying nft collection contract
     */
    function nft() external view returns (IERC721 nft_);

    /**
     * @notice Returns the address of the ERC20 token that this pool is trading NFTs against.
     * @return token_ The address of the ERC20 token that this pool is trading NFTs against.
     */
    function token() external view returns (address token_);

    /**
     * @notice Returns the permitter contract that allows or denies specific NFT tokenIds to be traded in this pool
     * @dev if this address is zero, then all NFTs from the underlying collection are allowed to be traded in this pool
     * @return permitter the address of this pool's permitter contract, or zero if no permitter is set
     */
    function permitter() external view returns (IPermitter);

    /**
     * @notice Returns how many ERC20 tokens a liquidity provider has in the pool
     * @dev this function mimics mappings: an invalid lpId_ will return 0 rather than throwing for being invalid
     * @param lpId_ LP Position NFT token ID to query for
     * @return lpTokenBalance the amount of ERC20 tokens the liquidity provider has in the pool
     */
    function getTokenBalanceForLpId(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the full list of NFT tokenIds that are owned by a specific liquidity provider in this pool
     * @dev This function is not gas efficient and not-meant to be used on chain, only as a convenience for off-chain.
     * @dev worst-case is O(n) over the length of all the NFTs owned by the pool
     * @param lpId_ an LP position NFT token Id for a user providing liquidity to this pool
     * @return nftIds the list of NFT tokenIds in this pool that are owned by the specific liquidity provider
     */
    function getNftIdsForLpId(uint256 lpId_) external view returns (uint256[] memory nftIds);

    /**
     * @notice returns the number of NFTs owned by a specific liquidity provider in this pool
     * @param lpId_ a user providing liquidity to this pool for trading with
     * @return userNftCount the number of NFTs in this pool owned by the liquidity provider
     */
    function getNftCountForLpId(uint256 lpId_) external view returns (uint256);

    /**
     * @notice returns the number of NFTs and number of ERC20s owned by a specific liquidity provider in this pool
     * pretty much equivalent to the user's liquidity position in non-nft form.
     * @dev this function mimics mappings: an invalid lpId_ will return (0,0) rather than throwing for being invalid
     * @param lpId_ a user providing liquidity to this pool for trading with
     * @return tokenBalance the amount of ERC20 tokens the liquidity provider has in the pool
     * @return nftBalance the number of NFTs in this pool owned by the liquidity provider
     */
    function getTotalBalanceForLpId(uint256 lpId_)
        external
        view
        returns (uint256 tokenBalance, uint256 nftBalance);

    /**
     * @notice returns the Lp Position NFT token Id that owns a specific NFT token Id in this pool
     * @dev this function mimics mappings: an invalid NFT token Id will return 0 rather than throwing for being invalid
     * @param nftId_ an NFT token Id that is owned by a liquidity provider in this pool
     * @return lpId the Lp Position NFT token Id that owns the NFT token Id
     */
    function getLpIdForNftId(uint256 nftId_) external view returns (uint256);

    /**
     * @notice returns the full list of all NFT tokenIds that are owned by this pool
     * @dev does not have to match what the underlying NFT contract balanceOf(dittoPool)
     * thinks is owned by this pool: this is only valid liquidity tradeable in this pool
     * NFTs can be lost by unsafe transferring them to a dittoPool
     * also this function is O(n) gas efficient, only really meant to be used off-chain
     * @return nftIds the list of all NFT Token Ids in this pool, across all liquidity positions
     */
    function getAllPoolHeldNftIds() external view returns (uint256[] memory);

    /**
     * @dev Returns the number of NFTs owned by the pool
     * @return nftBalance_ The number of NFTs owned by the pool
     */
    function getPoolTotalNftBalance() external view returns (uint256);

    /**
     * @notice returns the full list of all LP Position NFT tokenIds that represent liquidity in this pool
     * @return lpIds the list of all LP Position NFT Token Ids corresponding to liquidity in this pool
     */
    function getAllPoolLpIds() external view returns (uint256[] memory);

    /**
     * @notice returns the full amount of all ERC20 tokens that the pool thinks it owns
     * @dev may not match the underlying ERC20 contract balanceOf() because of unsafe transfers
     * this is only accounting for valid liquidity tradeable in the pool
     * @dev this function is not gas efficient and almost certainly should never actually be used on chain
     * @return totalPoolTokenBalance the amount of ERC20 tokens the pool thinks it owns
     */
    function getPoolTotalTokenBalance() external view returns (uint256);

    /**
     * @notice returns the enumerated list of all token balances for all LP positions in this pool
     * @dev this function is not gas efficient and almost certainly should never actually be used on chain
     * @return balances the list of all LP Position NFT Token Ids and the amount of ERC20 tokens they are apportioned in the pool
     */
    function getAllLpIdTokenBalances()
        external
        view
        returns (LpIdToTokenBalance[] memory balances);

    /**
     * @notice function called on SafeTransferFrom of NFTs to this contract
     * @dev see [ERC-721](https://eips.ethereum.org/EIPS/eip-721) for details
     */
    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);
}
