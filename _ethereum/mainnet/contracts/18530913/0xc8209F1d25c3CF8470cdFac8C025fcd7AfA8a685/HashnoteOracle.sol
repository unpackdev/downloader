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

    constructor(address _provider, address oracle, address _WETH, address _USDC, address govController) ProviderAwareOracle(_provider) {
        ORACLE = ISDYCAggregator(oracle);
        WETH = _WETH;
        USDC = _USDC;

        _transferOwnership(govController);
    }

    function getPrice(address) internal view returns (uint256 _amountOut) {
        //The price in terms of USD with 8 decimals of precision
        (, int256 rate,,,) = ORACLE.latestRoundData();

        //the Rate to unwrap 1 wSDYC to SDYC
        uint256 unwrapConversionRate = 1e18 * uint256(rate) / PRECISION;
        console.log("SDYC Value of 1 wSDYC: %s", unwrapConversionRate);

        // rate of sdyc -> USDC (8 decimals for the rate and 2 for the USDC)
        uint256 price = unwrapConversionRate * uint256(rate) / 1e10;
        console.log("USDC Value of 1 wSDYC: %s", price);

        //Get the price of USDC in terms of WETH
        uint256 wethPrice = provider.getValueOfAsset(USDC, WETH);
        console.log("WETH Value of 1 USDC: %s", wethPrice);

        //TODO: Check on the Precision
        return price * wethPrice / PRECISION;
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

    function setOracle(address _oracle) external onlyOwner {
        ORACLE = ISDYCAggregator(_oracle);
        //TODO: Emit Event
    }
}
