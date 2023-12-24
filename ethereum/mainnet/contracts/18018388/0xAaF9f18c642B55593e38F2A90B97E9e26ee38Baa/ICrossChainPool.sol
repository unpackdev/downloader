// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface ICrossChainPool {
    /**
     * @notice Initiate a cross chain swap to swap tokens from a chain to tokens in another chain
     * @dev Steps:
     * 1. User call `swapTokensForTokensCrossChain` to swap `fromToken` for credit
     * 2. CrossChainPool request wormhole adaptor to relay the message to the designated chain
     * 3. On the designated chain, wormhole relayer invoke `completeSwapCreditForTokens` to swap credit for `toToken` in the `toChain`
     * Note: Amount of `value` attached to this function can be estimated by `WormholeAdaptor.estimateDeliveryFee`
     */
    function swapTokensForTokensCrossChain(
        address fromToken,
        address toToken,
        uint256 toChain, // wormhole chain ID
        uint256 fromAmount,
        uint256 minimumCreditAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue, // gas to receive at the designated contract
        uint256 gasLimit // gas limit for the relayed transaction
    ) external payable returns (uint256 creditAmount, uint256 fromTokenFee, uint256 id);

    /**
     * @notice Swap credit for tokens (same chain)
     * @dev In case user has some credit, he/she can use this function to swap credit to tokens
     */
    function swapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external returns (uint256 actualToAmount, uint256 toTokenFee);

    /**
     * @notice Bridge credit and swap it for `toToken` in the `toChain`
     * @dev In case user has some credit, he/she can use this function to swap credit to tokens in another network
     * Note: Amount of `value` attached to this function can be estimated by `WormholeAdaptor.estimateDeliveryFee`
     */
    function swapCreditForTokensCrossChain(
        address toToken,
        uint256 toChain, // wormhole chain ID
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue, // gas to receive at the designated contract
        uint256 gasLimit // gas limit for the relayed transaction
    ) external payable returns (uint256 id);

    /*
     * Permissioned Functions
     */

    /**
     * @notice Swap credit to tokens; should be called by the adaptor
     */
    function completeSwapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external returns (uint256 actualToAmount, uint256 toTokenFee);

    function mintCredit(uint256 creditAmount, address receiver) external;
}
