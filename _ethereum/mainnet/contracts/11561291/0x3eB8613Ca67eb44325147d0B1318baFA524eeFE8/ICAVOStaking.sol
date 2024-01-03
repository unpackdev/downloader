pragma solidity >=0.6.6;

import "./IExcavoERC20.sol";

interface ICAVOStaking is IExcavoERC20 {
      function stakeLiquidityETH(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function unstakeLiquidityETH(
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external;

    function redeem(address to) external;

    function liquidityOf(address) external view returns (uint);

    function unclaimedOf(address account) external view returns (uint kGrowthOverTotalSupplyInBase, uint kGrowth, uint unclaimed);

    function emergencyWithdraw() external;
}