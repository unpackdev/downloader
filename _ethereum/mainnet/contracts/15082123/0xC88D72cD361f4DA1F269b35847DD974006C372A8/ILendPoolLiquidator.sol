// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./DataTypes.sol";

interface ILendPoolLiquidator {
    // Following events copy from LendPool
    /**
     * @dev Emitted when a borrower's loan is auctioned.
     * @param user The address of the user initiating the auction
     * @param reserve The address of the underlying asset of the reserve
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param loanId The loan ID of the NFT loans
     **/
    event Auction(
        address user,
        address indexed reserve,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    /**
     * @dev Emitted on redeem()
     * @param user The address of the user initiating the redeem(), providing the funds
     * @param reserve The address of the underlying asset of the reserve
     * @param borrowAmount The borrow amount repaid
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param loanId The loan ID of the NFT loans
     **/
    event Redeem(
        address user,
        address indexed reserve,
        uint256 borrowAmount,
        uint256 fineAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    /**
     * @dev Emitted when a borrower's loan is liquidated.
     * @param user The address of the user initiating the auction
     * @param reserve The address of the underlying asset of the reserve
     * @param repayAmount The amount of reserve repaid by the liquidator
     * @param remainAmount The amount of reserve received by the borrower
     * @param loanId The loan ID of the NFT loans
     **/
    event Liquidate(
        address user,
        address indexed reserve,
        uint256 repayAmount,
        uint256 remainAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    /**
     * @dev Function to auction a non-healthy position collateral-wise
     * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     **/
    function auction(address nftAsset, uint256 nftTokenId) external;

    // /**
    //  * @notice Redeem a NFT loan which state is in Auction
    //  * - E.g. User repays 100 USDC, burning loan and receives collateral asset
    //  * @param nftAsset The address of the underlying NFT used as collateral
    //  * @param nftTokenId The token ID of the underlying NFT used as collateral
    //  * @param amount The amount to repay the debt
    //  * @param bidFine The amount of bid fine
    //  **/
    // function redeem(
    //   address nftAsset,
    //   uint256 nftTokenId,
    //   uint256 amount,
    //   uint256 bidFine
    // ) external returns (uint256);

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise
     * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
     *   the collateral asset
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     **/
    function liquidate(
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        address treasury,
        uint256 interval,
        uint256 discountRate,
        uint256 treasuryFee
    ) external returns (uint256);
}
