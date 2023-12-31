// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";
import "./IOracleStruct.sol";

interface ICvgOracle {
    function getPriceOracleUnverified(address erc20) external view returns (uint256);

    function getEthPriceOracleUnverified() external view returns (uint256);

    function getCvgPriceOracleUnverified() external view returns (uint256);

    function getAndVerifyCvgPrice() external view returns (uint256);

    function oracleParametersPerERC20(address erc20) external view returns (IOracleStruct.OracleParams memory);

    function getAndVerifyOracle(address erc20) external view returns (uint256);

    function getAndVerifyTwoPrices(address tokenIn, address tokenOut) external view returns (uint256, uint256);

    function getDataForVerification(
        address erc20Address
    ) external view returns (uint256, uint256, bool, bool, bool, bool, bool, bool);
}
