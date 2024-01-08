// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ILSPair {
    event TokensCreated(
        address indexed sponsor,
        uint256 indexed collateralUsed,
        uint256 indexed tokensMinted
    );
    event TokensRedeemed(
        address indexed sponsor,
        uint256 indexed collateralReturned,
        uint256 indexed tokensRedeemed
    );
    event ContractExpired(address indexed caller);
    event EarlyExpirationRequested(
        address indexed caller,
        uint64 earlyExpirationTimeStamp
    );
    event PositionSettled(
        address indexed sponsor,
        uint256 collateralReturned,
        uint256 longTokens,
        uint256 shortTokens
    );

    /**
     * @notice Settle long and/or short tokens in for collateral at a rate informed by the contract settlement.
     * @dev Uses financialProductLibrary to compute the redemption rate between long and short tokens.
     * @dev This contract must have the `Burner` role for the `longToken` and `shortToken` in order to call `burnFrom`.
     * @dev The caller does not need to approve this contract to transfer any amount of `tokensToRedeem` since long
     * and short tokens are burned, rather than transferred, from the caller.
     * @dev This function can be called before or after expiration method to facilitate early expiration. If a price has
     * not yet been resolved for either normal or early expiration yet then it will revert.
     * @param longTokensToRedeem number of long tokens to settle.
     * @param shortTokensToRedeem number of short tokens to settle.
     * @return collateralReturned total collateral returned in exchange for the pair of synthetics.
     */
    function settle(uint256 longTokensToRedeem, uint256 shortTokensToRedeem)
        external
        returns (uint256 collateralReturned);

    /**
     * @notice Create tokens
     */
    function create(uint256 tokensToCreate) external;

    /**
     * @notice Pair name.
     */
    function pairName() external view returns (string memory);

    /**
     * @notice Token used as long in the LSP. Mint and burn rights needed by this contract.
     */
    function longToken() external view returns (address);

    /**
     * @notice Token used as short in the LSP. Mint and burn rights needed by this contract.
     */
    function shortToken() external view returns (address);


    /**
     * @notice Expire the LS Pair
     */
    function expire() external;

    /**
     * @notice Amount of collateral a pair of tokens is always redeemable for.
     */
    function collateralPerPair() external view returns (uint256);

    /**
     * @notice Collateral token used to back LSP synthetics.
     */
    function collateralToken() external view returns (address);
}
