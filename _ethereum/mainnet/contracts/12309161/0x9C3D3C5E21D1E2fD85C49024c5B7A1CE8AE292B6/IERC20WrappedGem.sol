// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20WrappedGem {
    function wrap(uint256 quantity) external;

    function unwrap(uint256 quantity) external;

    event Wrap(address indexed account, uint256 quantity);
    event Unwrap(address indexed account, uint256 quantity);

    function initialize(
        string memory tokenSymbol,
        string memory tokenName,
        address poolAddress,
        address tokenAddress,
        uint8 decimals
    ) external;
}
