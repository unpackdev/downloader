pragma solidity 0.6.6;

interface ILinkswapPriceOracle {
    function update() external;

    // tokenAmount is to 18 dp, usdAmount is to 8 dp
    // token must be LINK / WETH / YFL
    function calculateTokenAmountFromUsdAmount(address token, uint256 usdAmount)
        external
        view
        returns (uint256 tokenAmount);

    // token must be LINK / WETH
    function calculateUsdAmountFromTokenAmount(address token, uint256 tokenAmount)
        external
        view
        returns (uint256 usdAmount);
}
