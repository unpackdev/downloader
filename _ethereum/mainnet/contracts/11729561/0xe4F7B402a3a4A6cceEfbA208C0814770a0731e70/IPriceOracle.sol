// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

struct Price {
    uint256 value;
}

struct Value {
    uint256 value;
}

interface IPriceOracle {
    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^36.
     *                So a USD-stable coin with 18 decimal places would return 10^18.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(address token) external view returns (Price memory);
}
