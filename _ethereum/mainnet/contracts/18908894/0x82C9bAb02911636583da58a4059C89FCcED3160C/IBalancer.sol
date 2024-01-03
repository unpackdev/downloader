// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC20.sol";

/**
 * @title IBalancerVault interface
 * @author Dollet Team
 * @notice Balancer Vault interface. This interface defines the functions for interacting with the Balancer Vault
 *         contract.
 */
interface IBalancerVault {
    /**
     * @notice Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on the
     *         `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be used to
     * extend swap behavior.
     */

    struct SingleSwap {
        bytes32 poolId;
        uint8 kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @notice All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     *         `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is `true`, the `sender`'s internal balance will be preferred, performing an ERC-20
     * transfer for the difference between the requested amount and the user's internal balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of `joinPool`.
     *
     * If `toInternalBalance` is `true`, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from internal balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @notice Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `_limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `_limit`.
     *
     * Internal balance usage and the recipient are determined by the `_funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory _singleSwap,
        FundManagement memory _funds,
        uint256 _limit,
        uint256 _deadline
    )
        external
        returns (uint256);

    /**
     * @notice Returns a Pool's registered tokens, the total balance for each, and the latest block when any of the
     *         tokens' `_balances` changed.
     *
     * The order of the `_tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 _poolId)
        external
        view
        returns (IERC20[] memory _tokens, uint256[] memory _balances, uint256 _lastChangeBlock);
}

/**
 * @title IBalancerPool interface
 * @author Dollet Team
 * @notice Balancer pool interface. This interface defines the functions for interacting with the Balancer pool
 *         contract.
 */
interface IBalancerPool {
    /**
     * @notice Returns Balancer pool ID.
     * @return Balancer pool ID.
     */
    function getPoolId() external view returns (bytes32);

    /**
     * @notice Returns normalized weights of tokens in the pool.
     * @return Normalized weights of tokens in the pool.
     */
    function getNormalizedWeights() external view returns (uint256[] memory);
}
