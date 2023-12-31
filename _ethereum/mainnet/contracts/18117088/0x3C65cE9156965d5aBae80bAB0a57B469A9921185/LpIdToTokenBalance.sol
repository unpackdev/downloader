// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @notice Tuple struct to encapsulate a LP Position NFT token Id and the amount of ERC20 tokens it owns in the pool
 * @dev **lpId** the LP Position NFT token Id of a liquidity provider
 * @dev **tokenBalance** the amount of ERC20 tokens the liquidity provider has in the pool attributed to them
 */
struct LpIdToTokenBalance {
    uint256 lpId;
    uint256 tokenBalance;
}
