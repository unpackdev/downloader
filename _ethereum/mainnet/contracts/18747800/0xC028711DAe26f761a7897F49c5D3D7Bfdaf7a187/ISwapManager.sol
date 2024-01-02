// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IAccessControl.sol";

import "./PrimexPricingLibrary.sol";

import "./IPrimexDNS.sol";
import "./IPriceOracle.sol";
import "./ITraderBalanceVault.sol";
import "./IPausable.sol";

interface ISwapManager is IPausable {
    event SpotSwap(
        address indexed trader,
        address indexed receiver,
        address tokenA,
        address tokenB,
        uint256 amountSold,
        uint256 amountBought
    );

    /**
     * @param tokenA The address of the asset to be swapped from.
     * @param tokenB The address of the asset to be received in the swap.
     * @param amountTokenA The amount of tokenA to be swapped.
     * @param amountOutMin The minimum amount of tokenB expected to receive.
     * @param routes An array of PrimexPricingLibrary.Route structs representing the routes for the swap.
     * @param receiver The address where the swapped tokens will be received.
     * @param deadline The deadline for the swap transaction.
     * @param isSwapFromWallet A flag indicating whether the swap is perfomed from a wallet or a protocol balance.
     * @param isSwapToWallet A flag indicating whether the swapped tokens will be sent to a wallet or a protocol balance.
     * @param isSwapFeeInPmx A flag indicating whether the swap fee is paid in PMX or in native token.
     * @param payFeeFromWallet A flag indicating whether the swap fee is perfomed from a wallet or a protocol balance.
     */
    struct SwapParams {
        address tokenA;
        address tokenB;
        uint256 amountTokenA;
        uint256 amountOutMin;
        PrimexPricingLibrary.Route[] routes;
        address receiver;
        uint256 deadline;
        bool isSwapFromWallet;
        bool isSwapToWallet;
        bool isSwapFeeInPmx;
        bool payFeeFromWallet;
    }

    /**
     * @notice Executes a swap on dexes defined in routes
     * @param params The SwapParams struct containing the details of the swap transaction.
     * @param maximumOracleTolerableLimit The maximum tolerable limit in WAD format (1 WAD = 100%)
     * @param needOracleTolerableLimitCheck Flag indicating whether to perform an oracle tolerable limit check.
     * @return The resulting amount after the swap.
     */
    function swap(
        SwapParams calldata params,
        uint256 maximumOracleTolerableLimit,
        bool needOracleTolerableLimitCheck
    ) external payable returns (uint256);

    /**
     * @notice Retrieves the instance of PrimexRegistry contract.
     */
    function registry() external view returns (IAccessControl);

    /**
     * @notice Retrieves the instance of TraderBalanceVault contract.
     */
    function traderBalanceVault() external view returns (ITraderBalanceVault);

    /**
     * @notice Retrieves the instance of PrimexDNS contract.
     */
    function primexDNS() external view returns (IPrimexDNS);

    /**
     * @notice Retrieves the instance of PriceOracle contract.
     */
    function priceOracle() external view returns (IPriceOracle);
}
