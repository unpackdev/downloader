// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Asymetrix Protocol V2 IValuer
 * @author Asymetrix Protocol Inc Team
 * @notice An interface that all valuers should implement.
 */
interface IValuer {
    /**
     * @notice Returns the value of ERC-20 LP tokens (or ERC-721 NFT position) in USD in the liquidity pool.
     * @param _amountOrId An amount of ERC-20 LP tokens (or ERC-721 NFT position ID) to value.
     * @return _value The value of ERC-20 LP tokens (or ERC-721 NFT position) in USD.
     */
    function value(uint256 _amountOrId) external view returns (uint256 _value);

    /**
     * @notice Returns token amounts inside the position in USD.
     * @param _id Id of the Uniswap V3 position.
     * @return _value0 The first token amount in USD.
     * @return _value1 The second token amount in USD.
     */
    function getTokenAmountsInUSD(uint256 _id) external view returns (uint256 _value0, uint256 _value1);
}
