// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.4;

import "./IERC20Upgradeable.sol";

/**
 * @author Asaf Silman
 * @title FeeExchanger Interface
 * @dev This interface should be implemented to swap fees generated from a protocol via a DEX.
 */
interface IFeeExchanger {
    /**
     * @notice View function to retrieve the input token address.
     * @return The input token address.
     */
    function inputToken() external view returns (IERC20Upgradeable);
    /**
     * @notice View function to retrieve the output token address.
     * @return The output token address.
     */
    function outputToken() external view returns (IERC20Upgradeable);

    /**
     * @notice Emitted when the output address is updated.
     * @param previousAddress The previous output address.
     * @param newAddress The new output address.
     */
    event OutputAddressUpdated(address previousAddress, address newAddress);
    /**
     * @notice Change the output address.
     * @dev The output address be interpreted as any contract type in the implmentation.
     * @dev For example the output address could be a FeeDistributor contract.
     * @param newOutputAddress The new output address.
     */
    function updateOutputAddress(address newOutputAddress) external;
    /**
     * @notice View function to retrieve the output address.
     * @return The output address.
     */
    function outputAddress() external view returns (address);

    /**
     * @notice Emitted when a token is exchanged.
     * @param amountIn Input token amount exchanged.
     * @param amountOut Output token amount exchanged for.
     * @param exchangeName The exchange name which the swap was performed on.
     */
    event TokenExchanged(uint256 amountIn, uint256 amountOut, string exchangeName);
    /**
     * @notice Perform a token exchange
     * @dev Implement this function specifically for each DEX.
     * @dev This method should only be callable from an exchanger
     * @param amountIn The amount of input token to exchange.
     * @param minAmountOut The minimum amout of output token to receive from the trade.
     */
    function exchange(uint256 amountIn, uint256 minAmountOut) external returns (uint256);

    /**
     * @notice Emitted when an exchanger is updated.
     * @dev An exchanger is simply an address which can call 'exchange(...)'.
     * @param exchanger The exchanger address, can be an EOA or contract.
     * @param canExchange Exchanger state.
     */
    event ExchangerUpdated(address indexed exchanger, bool canExchange);
    /**
     * @notice Adds an address as an exchanger.
     * @param exchanger The exchanger address to add.
     */
    function addExchanger(address exchanger) external;
    /**
     * @notice Removes an address as an exchanger.
     * @param exchanger The exchanger address to remove.
     */
    function removeExchanger(address exchanger) external;
    /**
     * @notice Check if an address is an exchanger.
     * @param exchanger The exchanger address to check.
     * @return True if address is an exchanger. False otherwise.
     */
    function canExchange(address exchanger) external view returns (bool);
}
