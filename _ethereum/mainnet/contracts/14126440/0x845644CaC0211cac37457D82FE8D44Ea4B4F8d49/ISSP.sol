// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;

interface ISSP {
    /* ========== STATE VARIABLES ========== */
    function fee() external view returns (uint);
    function virtualDei() external view returns (uint);

    /* ========== PUBLIC FUNCTIONS ========== */
    function swapUsdcForExactDei(uint deiNeededAmount) external returns (uint usdcAmount);

    /* ========== VIEWS ========== */
    function getAmountIn(uint deiNeededAmount) external view returns (uint usdcAmount);
    function getAmountOut(uint usdcAmount) external view returns (uint deiAmount);
    function collatDollarBalance(uint256 collat_usd_price) external view returns (uint256);

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setFee(uint fee_) external;
    function setScale(uint scale_) external;
    function setCollateralMissingDecimalD18(uint collateralMissingDecimalD18_) external;
    function setVirtualDei(uint virtualDei_) external;
    function emergencyWithdrawERC20(address token, address recv, uint amount) external;
    function emergencyWithdrawETH(address recv, uint amount) external;
}