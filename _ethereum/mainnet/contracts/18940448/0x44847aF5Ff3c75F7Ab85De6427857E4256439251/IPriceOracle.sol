// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IPriceOracle {
    /* SYSTEM-ONLY PRIVELEGE: Find price of passed asset pair, if possible. The steps it takes are:
     *  1) Check to see if a direct or inverse oracle of the pair exists,
     *  2) If not, use masterQuoteAsset to link pairs together (i.e. BTC/ETH and ETH/USDC
     *     could be used to calculate BTC/USDC).
     *  3) If not, check oracle adapters in case one or more of the assets needs external protocol data
     *     to price.
     *  4) If all steps fail, revert.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return                 one/two  Price of asset pair to 18 decimals of precision
     */
    function getPrice(
        address _assetOne,
        address _assetTwo
    ) external view returns (uint256);
}
