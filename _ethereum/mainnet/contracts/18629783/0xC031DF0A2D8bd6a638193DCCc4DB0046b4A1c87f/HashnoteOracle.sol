// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderAwareOracle.sol";
import "./Ownable.sol";
import "./ISDYCAggregator.sol";
import "./IERC20.sol";
import "./console2.sol";

contract HashnoteOracle is ProviderAwareOracle {
    address public immutable WETH;
    ISDYCAggregator public ORACLE;
    address public immutable USDC;

    uint256 public constant REBASE_DECIMALS = 1e18;
    uint256 public constant SDYC_DECIMALS = 1e6;

    constructor(address _provider, address _WETH, address _USDC) ProviderAwareOracle(_provider) {
        WETH = _WETH;
        USDC = _USDC;
    }

    function getPrice(address) internal view returns (uint256 _amountOut) {
        
        uint256 wethPrice = provider.getValueOfAsset(USDC, WETH);
        
        //Divide by 1e12 to remove the extra 12 decimals of precision between USDC and wSDYC
        return wethPrice / 1e12;
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
