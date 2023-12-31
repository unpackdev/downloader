// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./FactoryTemplates.sol";
import "./LpNft.sol";
import "./IOwnerTwoStep.sol";
import "./IDittoPool.sol";
import "./IDittoRouter.sol";
import "./IPermitter.sol";
import "./IMetadataGenerator.sol";
import "./IPoolManager.sol";
import "./FactoryTemplates.sol";

interface IDittoPoolFactory is IOwnerTwoStep {
    // ***************************************************************
    // * ====================== MAIN INTERFACE ===================== *
    // ***************************************************************

    /**
     * @notice Create a ditto pool along with a permitter and pool manager if requested. 
     *
     * @param params_ The pool creation parameters including initial liquidity and fee settings
     *   **uint256 templateIndex** The index of the pool template to clone
     *   **address token** ERC20 token address trading against the nft collection
     *   **address nft** the address of the NFT collection that we are creating a pool for
     *   **uint96 feeLp** the fee percentage paid to LPers when they are the counterparty in a trade
     *   **address owner** The liquidity initial provider and owner of the pool, overwritten by pool manager if present
     *   **uint96 feeAdmin** the fee percentage paid to the pool admin 
     *   **uint128 delta** the delta of the pool, see bonding curve documentation
     *   **uint128 basePrice** the base price of the pool, see bonding curve documentation
     *   **uint256[] nftIdList** the token IDs of NFTs to deposit into the pool as it is created. Empty arrays are allowed
     *   **uint256 initialTokenBalance** the number of ERC20 tokens to transfer to the pool as you create it. Zero is allowed
     *   **bytes initialTemplateData** initial data to pass to the pool contract in its initializer
     * @param poolManagerTemplate_ The template for the pool manager to manage the pool. Provide type(uint256).max to opt out
     * @param permitterTemplate_  The template for the permitter to manage the pool. Provide type(uint256).max to opt out
     * @return dittoPool The newly created DittoPool
     * @return lpId The ID of the LP position NFT representing the initial liquidity deposited, or zero, if none deposited
     * @return poolManager The pool manager or the zero address if none was created
     * @return permitter The permitter or the zero address if none was created
     */
    function createDittoPool(
        PoolTemplate memory params_,
        PoolManagerTemplate calldata poolManagerTemplate_,
        PermitterTemplate calldata permitterTemplate_
    )
        external
        returns (IDittoPool dittoPool, uint256 lpId, IPoolManager poolManager, IPermitter permitter);

    // ***************************************************************
    // * ============== EXTERNAL VIEW FUNCTIONS ==================== *
    // ***************************************************************

    /**
     * @notice Get the list of pool templates that can be used to create new pools
     * @return poolTemplates_ The list of pool templates that can be used to create new pools
     */
    function poolTemplates() external view returns (address[] memory);

    /**
     * @notice Get the list of pool manager templates that can be used to manage a new pool
     * @return poolManagerTemplates_ The list of pool manager templates that can be used to manage a new pool
     */
    function poolManagerTemplates() external view returns (IPoolManager[] memory);

    /**
     * @notice Get the list of permitter templates that can be used to restrict nft ids in a pool
     * @return permitterTemplates_ The list of permitter templates that can be used to restrict nft ids in a pool
     */
    function permitterTemplates() external view returns (IPermitter[] memory);

    /**
     * @notice Check if an address is an approved whitelisted router that can trade with the pools
     * @param potentialRouter_ The address to check if it is a whitelisted router
     * @return isWhitelistedRouter True if the address is a whitelisted router
     */
    function isWhitelistedRouter(address potentialRouter_) external view returns (bool);

    /**
     * @notice Get the protocol fee recipient address
     * @return poolFeeRecipient of the protocol fee recipient
     */
    function protocolFeeRecipient() external view returns (address);

    /**
     * @notice Get the protocol fee multiplier used to calculate fees on all trades 
     * @return protocolFeeMultiplier the multiplier for global protocol fees on all trades
     */
    function getProtocolFee() external view returns (uint96);

    /**
     * @notice The nft used to represent liquidity positions
     */
    function lpNft() external view returns (LpNft lpNft_);

    // ***************************************************************
    // * ==================== ADMIN FUNCTIONS ====================== *
    // ***************************************************************

    /**
     * @notice Admin function to add additional pool templates 
     * @param poolTemplates_ addresses of the new pool templates
     */
    function addPoolTemplates(address[] calldata poolTemplates_) external;

    /**
     * @notice Admin function to add additional pool manager templates
     * @param poolManagerTemplates_ addresses of the new pool manager templates
     */
    function addPoolManagerTemplates(IPoolManager[] calldata poolManagerTemplates_) external;

    /**
     * @notice Admin function to add additional permitter templates
     * @param permitterTemplates_ addresses of the new permitter templates
     */
    function addPermitterTemplates(IPermitter[] calldata permitterTemplates_) external;

    /**
     * @notice Admin function to add additional whitelisted routers
     * @param routers_ addresses of the new routers to whitelist
     */
    function addRouters(IDittoRouter[] calldata routers_) external;

    /**
     * @notice Admin function to set the protocol fee recipient
     * @param feeProtocolRecipient_ address of the new protocol fee recipient
     */
    function setProtocolFeeRecipient(address feeProtocolRecipient_) external;

    /**
     * @notice Admin function to set the protocol fee multiplier used to calculate fees on all trades, base 1e18
     * @param feeProtocol_ the new protocol fee multiplier
     */
    function setProtocolFee(uint96 feeProtocol_) external;

    /**
     * @notice Admin function to change the LP position NFT collection used by this Ditto Pool Factory
     * @param lpNft_ address of the new LpNft
     */
    function setLpNft(LpNft lpNft_) external;
}
