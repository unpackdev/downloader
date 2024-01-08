// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IHegicOptionTypes.sol";

interface ITBD {
    event PurchaseOption(
        address indexed owner,
        uint256 optionID,
        uint256 purchasePrice,
        address purchaseToken,
        uint256 fees
    );

    struct Option {
        uint256 id;
        uint256 priceInAlUSD;
    }

    /// @notice Convert alUSD to Dai using Curve, Dai to Weth using Uniswap and purchases option on Hegic
    /// @param amount Amount of AlUSD paid
    /// @param strike Strike price (with 8 decimals)
    /// @param period Option period in seconds (min 1 day, max 28 days) 
    /// @param owner Address where option is sent 
    /// @param optionType 1 for PUT, 2 for CALL
    /// @param minETH Prevents high slippage by setting min eth after swaps
    function purchaseOptionWithAlUSD(
        uint256 amount,
        uint256 strike,
        uint256 period,
        address owner,
        IHegicOptionTypes.OptionType optionType,
        uint256 minETH
    ) external returns (uint256 optionID);

    /// @notice Retrieve created options
    /// @param owner Owner of the options to retrieve
    function getOptionsByOwner(address owner) external view returns (Option[] memory);

    /// @notice Retrieve option creation cost in the underlying token
    /// @param amount alUSD amount used
    function getUnderlyingFeeFromAlUSD(uint256 amount) external view returns (uint256);

    /// @notice Retrieve option creation cost in eth
    /// @param amount alUSD amount used
    function getEthFeeFromAlUSD(uint256 amount) external view returns (uint256);

    /// @notice Retrieve the option size depending on all parameters + alUSD paid
    /// @param amount Amount of AlUSD paid
    /// @param strike Strike price (with 8 decimals)
    /// @param period Option period in seconds (min 1 day, max 28 days) 
    /// @param optionType 1 for PUT, 2 for CALL
    function getOptionAmountFromAlUSD(
        uint256 period,
        uint256 amount,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) external view returns (uint256);

    /// @notice Retrieve the option size from the raw eth fee paid to Hegic
    /// @param period Option period in seconds (min 1 day, max 28 days) 
    /// @param fees Amount of Eth paid
    /// @param strike Strike price (with 8 decimals)
    /// @param optionType 1 for PUT, 2 for CALL
    function getAmount(
        uint256 period,
        uint256 fees,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) external view returns (uint256);
}
