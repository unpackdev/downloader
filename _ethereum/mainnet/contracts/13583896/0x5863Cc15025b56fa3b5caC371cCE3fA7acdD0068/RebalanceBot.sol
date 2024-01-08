// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IxAssetCLR.sol";
import "./IxTokenManager.sol";

import "./Ownable.sol";

/**
 * CLR rebalance bot which performs adminSwap and adminBurn / adminMint
 * in order to bring tokens in the CLR position back to a certain ratio
 */
contract RebalanceBot is Ownable {
    IxTokenManager xTokenManager = IxTokenManager(0xfA3CaAb19E6913b6aAbdda4E27ac413e96EaB0Ca);

    /**
     * Performs a rebalance for a given CLR instance which swaps underlying for xAsset and burns it
     * Used to bring token ratio in a given position back to normal using xAsset burn method
     * Groups Unstake, Swap and Burn in one transaction
     * @param xAssetCLR CLR instance
     * @param t0UnstakeAmt amount of token 0 to unstake
     * @param t1UnstakeAmt amount of token 1 to unstake
     * @param swapAmount amount of underlying asset to swap for xAsset
     * @param burnAmount amount of xAsset to burn
     * @param t0IsxAsset true if token 0 is the xAsset, false otherwise
     */
    function swapAndBurnRebalance(IxAssetCLR xAssetCLR, uint256 t0UnstakeAmt, uint256 t1UnstakeAmt, 
                            uint256 swapAmount, uint256 burnAmount, bool t0IsxAsset) public onlyOwnerOrManager {
        xAssetCLR.adminUnstake(t0UnstakeAmt, t1UnstakeAmt);
        xAssetCLR.adminSwap(swapAmount, !t0IsxAsset);
        xAssetCLR.adminBurn(burnAmount, t0IsxAsset);
    }

    /**
     * Performs a rebalance for a given CLR instance which swaps xAsset for underlying and mints more xAsset
     * Used to bring token ratio in a given position back to normal using xAsset mint method
     * Groups Unstake, Swap and Mint in one transaction
     * @param xAssetCLR CLR instance
     * @param t0UnstakeAmt amount of token 0 to unstake
     * @param t1UnstakeAmt amount of token 1 to unstake
     * @param swapAmount amount of xAsset to swap for underlying asset
     * @param mintAmount amount of underlying asset to mint with
     * @param t0IsxAsset true if token 0 is the xAsset, false otherwise
     */
    function swapAndMintRebalance(IxAssetCLR xAssetCLR, uint256 t0UnstakeAmt, uint256 t1UnstakeAmt, 
                            uint256 swapAmount, uint256 mintAmount, bool t0IsxAsset) public onlyOwnerOrManager {
        xAssetCLR.adminUnstake(t0UnstakeAmt, t1UnstakeAmt);
        xAssetCLR.adminSwap(swapAmount, t0IsxAsset);
        xAssetCLR.adminMint(mintAmount, t0IsxAsset);
    }

    modifier onlyOwnerOrManager {
        require(
            msg.sender == owner() ||
            xTokenManager.isManager(msg.sender, address(this)),
            "Function may be called only by owner or manager"
        );
        _;
    }
}