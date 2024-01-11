// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./BaseDex.sol";
import "./IDex.sol";
import "./IExchange.sol";
import "./IAddressProvider.sol";
contract Curve is BaseDex {
    using SafeERC20 for IERC20Metadata;

    uint256 public immutable EXCHANGE_ADDRESS_ID;
    IAddressProvider public immutable ADDRESS_PROVIDER;

    constructor(IAddressProvider p, uint256 exchangeAddressId) {
        ADDRESS_PROVIDER = p;
        EXCHANGE_ADDRESS_ID = exchangeAddressId;
    }

    function _swap(SwapRequest memory swapRequest) internal override returns (uint256 amount) {
        IExchange ex = IExchange(ADDRESS_PROVIDER.get_address(EXCHANGE_ADDRESS_ID));
        swapRequest.inputToken.safeIncreaseAllowance(address(ex), swapRequest.inputAmount);
        amount = ex.exchange_with_best_rate(
            address(swapRequest.inputToken),
            address(swapRequest.outputToken),
            swapRequest.inputAmount,
            0
        );
    }

    function _quote(address input, address output, uint256 amount) internal view override returns (uint256) {
        IExchange ex = IExchange(ADDRESS_PROVIDER.get_address(EXCHANGE_ADDRESS_ID));
        (, uint256 expected) = ex.get_best_rate(input, output, amount);
        return expected;
    }
}
