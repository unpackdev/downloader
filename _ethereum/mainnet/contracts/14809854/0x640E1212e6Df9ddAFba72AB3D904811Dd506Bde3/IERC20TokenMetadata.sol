// SPDX-License-Identifier: GNU GPLv3
pragma solidity =0.8.9;

interface IERC20TokenMetadata {
    /**
     * @dev returns name of the token
     * @return name - token name
     */
    function name() external view returns (string memory);

    /**
     * @dev returns symbol of the token
     * @return symbol - token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev returns decimals of the token
     * @return decimals - token decimals
     */
    function decimals() external view returns (uint8);
}
