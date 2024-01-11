// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./Bond.sol";
import "./IOracle.sol";
import "./IStakingRewards.sol";

interface IBondsRegistry {
    /// @param discount registered discount to be applied
    /// @param lockDuration how long the underlying should be locked in the bond
    struct DiscountOption {
        uint128 discount;
        uint128 lockDuration;
    }

    /// @dev Underlying token offers from locked token holders
    /// @dev Offer id key is equal to the position token id
    function offers(uint256 _offerId)
        external
        view
        returns (
            uint128 balance,
            uint128 payout,
            uint256 payoutPerTokenApplied,
            uint256 debtPerTokenApplied
        );

    /// @dev ERC721 bonds minted representing an amount of locked underlying
    function bonds(uint256 _bondId) external view returns (uint128 payout, uint128 expiration);

    /// @dev Lock duration options mapped to applied underlying discounts (in BPS)
    function discountOptions(uint256 _lockDuration) external view returns (uint256);

    /// @notice Returns amount of purchase tokens accumulated for given offer.
    /// @param _offerId position offer nft id
    function payoutEarnedFor(uint256 _offerId) external view returns (uint256);

    /// @notice Returns the available balance for a given offer.
    /// @dev It takes into account the protocol's debt and applies how many underlying
    /// tokens must be removed from the offer's balance, according to current sales data.
    /// @param _offerId position offer nft id
    function availableBalanceFor(uint256 _offerId) external view returns (uint128);

    /// @notice Updates price oracle contract address.
    /// @param _oracle new oracle address
    function setOracle(IOracle _oracle) external;

    /// @notice Updates staking contract address.
    /// @param _staking new staking address
    function setStaking(IStakingRewards _staking) external;

    /// @notice Updates bond discount options available.
    /// @dev Owner is able to set discount tiers for different lock durations,
    /// where each duration returns a price discount in BPS.
    /// @param _discountOptions array with discounts and token lock duration in bonds
    function setDiscounts(DiscountOption[] calldata _discountOptions) external;

    /// @notice Updates ERC721 base URI value.
    /// @param _newBaseURI new base URI value
    function setBaseURI(string memory _newBaseURI) external;

    /// @notice Pauses critical functionality in the contract.
    /// @dev Can be called by the eDAO multisig in case the contract needs to be paused
    /// in an emergency and unpaused later.
    /// @param _shouldPause whether the contract needs to be paused/unpaused
    function setPauseState(bool _shouldPause) external;

    /// @notice Offer an amount of locked tokens in a vesting position to be sold
    /// for purchase tokens.
    /// @dev Important checks and state updates are executed in the vesting contract's context.
    /// @param _offerId position nft token id to be offered
    /// @param _value amount of locked tokens in the position to be offered
    function offer(uint256 _offerId, uint256 _value) external;

    /// @notice Resigns an amount of tokens available in an offer.
    /// @dev Resigned tokens in the offer are returned to the vesting contract.
    /// @dev Important checks and state updates are executed in the vesting contract's context.
    /// @param _offerId position offer nft id
    /// @param _value amount of locked tokens in the position to be removed
    function resign(uint256 _offerId, uint256 _value) external;

    /// @notice Purchases underlying tokens locked for a given duration with a discount.
    /// @dev Expects user to receive a bond with at least the amount of underlying tokens
    /// specified in the `_minUnderlyingOut` parameter.
    /// @dev A discount is applied to the price provided by the oracle contract, hence
    /// increasing the amount of underlying tokens acquired.
    /// @dev Every purchase accumulates a purchase payout for offers and a shared debt
    /// which needs to be applied in order to reduce an individual offer's balance in
    /// its next interaction. Global values are updated atomically.
    /// @param _value amount of purchase tokens provided
    /// @param _duration underlying lock duration (used to figure out discount)
    /// @param _minUnderlyingOut minimum amount of underlying tokens expected from the purchase
    /// @param _autostake whether the bond should be automatically staked in staking rewards contract
    function buy(
        uint256 _value,
        uint256 _duration,
        uint256 _minUnderlyingOut,
        bool _autostake
    ) external;

    /// @notice Claims payout in purchase tokens for a given offer.
    /// @dev Only approved caller or vesting position token owner is allowed to
    /// trigger the payout, which is always sent to the owner.
    /// @param _offerId position offer nft id
    function claimOfferPayout(uint256 _offerId) external;

    /// @notice Claims bond underlying tokens payout after expiration.
    /// @dev Only nft owner is able to trigger the payout and the bond must be expired.
    /// @param _bondId bond nft id
    function claimBondPayout(uint256 _bondId) external;
}
