// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
import "./IERC20.sol";

/**
 * @title Interface for APY.Finance liquidity pools
 * @author APY.Finance
 * @notice Liquidity pools accept deposits and withdrawals of a single token.
 *         APT is minted and burned to track an account's stake in the pool.
 *         A Chainlink price aggregator is also set so the total value of the
 *         pool can be computed.
 */
interface ILiquidityPoolV2 {
    event DepositedAPT(
        address indexed sender,
        IERC20 token,
        uint256 tokenAmount,
        uint256 aptMintAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );
    event RedeemedAPT(
        address indexed sender,
        IERC20 token,
        uint256 redeemedTokenAmount,
        uint256 aptRedeemAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );
    event AddLiquidityLocked();
    event AddLiquidityUnlocked();
    event RedeemLocked();
    event RedeemUnlocked();

    /**
     * @notice Mint corresponding amount of APT tokens for deposited stablecoin.
     * @param amount Amount to deposit of the underlying stablecoin
     */
    function addLiquidity(uint256 amount) external;

    /**
     * @notice Redeems APT amount for its underlying stablecoin amount.
     * @param tokenAmount The amount of APT tokens to redeem
     */
    function redeem(uint256 tokenAmount) external;
}
