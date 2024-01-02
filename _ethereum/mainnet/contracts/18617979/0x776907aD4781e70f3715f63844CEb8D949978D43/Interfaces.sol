// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./IERC20.sol";

// custom errors
error CustomError(string errorMsg);

// interfaces
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

interface IDoughV2Index {
    function owner() external view returns (address);

    function treasury() external view returns (address);

    function shieldExecutor() external view returns (address);

    function supplyFee() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function borrowFee() external view returns (uint256);

    function repayFee() external view returns (uint256);

    function flashloanFee() external view returns (uint256);

    function shieldFee() external view returns (uint256);

    function getShieldInfo(address dsa) external view returns (uint256, uint256, address, address);

    function getDoughV2Connector(uint256 _connectorId) external view returns (address);
}

interface IDoughV2Dsa {
    function doughV2Index() external view returns (address);

    function executeAction(address tokenIn, uint256 inAmount, address tokenOut, uint256 outAmount, uint256 funcId) external;
}

interface IAaveV3DataProvider {
    function getUserReserveData(
        address asset,
        address user
    ) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);
}

interface IAaveV3Pool {
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    function getUserAccountData(address user) external view returns (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external;

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external returns (uint256);
}

interface IConnectorV2Flashloan {
    function flashloanReq(address _loanToken, uint256 _loanAmount, uint256 _funcId, bool _isShield) external;
}

interface IUniswapV2Router {
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}
