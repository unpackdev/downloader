// Github source: https://github.com/alexanderem49/wildwestnft-smart-contracts
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ITokenSupplyData {
    /**
     * @notice Returns maximum amount of tokens available to buy on this contract.
     * @return Max supply of tokens.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Returns amount of tokens that are minted and sold.
     * @return Circulating supply of tokens.
     */
    function circulatingSupply() external view returns (uint256);
}
