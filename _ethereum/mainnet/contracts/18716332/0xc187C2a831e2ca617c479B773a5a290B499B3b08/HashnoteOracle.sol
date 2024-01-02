// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderAwareOracle.sol";
import "./Ownable.sol";

import "./console2.sol";

contract HashnoteOracle is ProviderAwareOracle {
    address public immutable USDC;

    constructor(address _provider, address _USDC) ProviderAwareOracle(_provider) {
        USDC = _USDC;
    }

    function getPrice(address) internal view returns (uint256 _amountOut) {
        
        return provider.getSafePrice(USDC);

    }

    function getSafePrice(address token) external view returns (uint256 _amountOut) {
        return getPrice(token);
    }

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view returns (uint256 _amountOut) {
        return getPrice(token);
    }

    function updateSafePrice(address token) external view returns (uint256 _amountOut) {
        return getPrice(token);
    }

}
