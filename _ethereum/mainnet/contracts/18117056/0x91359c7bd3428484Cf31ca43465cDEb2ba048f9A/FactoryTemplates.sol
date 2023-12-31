// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @notice A struct for creating a DittoSwap pool.
 */
struct PoolTemplate {
    bool isPrivatePool; // whether the pool is private or not
    uint256 templateIndex; // which DittoSwap template to use. Must be less than the number of available templates
    address token; // ERC20 token address
    address nft; // the address of the NFT collection that we are creating a pool for
    uint96 feeLp; // set by owner, paid to LPers only when they are the counterparty in a trade
    address owner; // owner creating the pool
    uint96 feeAdmin; // set by owner, paid to admin fee recipient
    uint128 delta; // the delta of the pool, see bonding curve documentation
    uint128 basePrice; // the base price of the pool, see bonding curve documentation
    uint256[] nftIdList; // the token IDs of NFTs to deposit into the pool
    uint256 initialTokenBalance; // the number of ERC20 tokens to transfer to the pool
    bytes templateInitData; // initial data to pass to the pool contract in its initializer
    bytes referrer; // the address of the referrer
}

/**
 * @notice A struct for containing Pool Manager template data.
 *  
 * @dev **templateIndex** Which DittoSwap template to use. If templateIndex is set to a value 
 *   larger than the number of templates, no pool manager is created
 * @dev **templateInitData** initial data to pass to the poolManager contract in its initializer.
 */
struct PoolManagerTemplate {
    uint256 templateIndex;
    bytes templateInitData;
}

/**
 * @notice A struct for containing Permitter template data.
 * @dev **templateIndex** Which DittoSwap template to use. If templateIndex is set to a value 
 *   larger than the number of templates, no permitter is created.
 * @dev **templateInitData** initial data to pass to the permitter contract in its initializer.
 * @dev **liquidityDepositPermissionData** Deposit data to pass in an all-in-one step to create a pool and deposit liquidity at the same time
 */
struct PermitterTemplate {
    uint256 templateIndex;
    bytes templateInitData;
    bytes liquidityDepositPermissionData;
}
