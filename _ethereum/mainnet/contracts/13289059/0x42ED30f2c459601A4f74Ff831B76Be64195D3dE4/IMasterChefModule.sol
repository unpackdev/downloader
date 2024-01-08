// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IMasterChef.sol";
import "./IUniswapV2Pair.sol";

interface IMasterChefModule {
    function lpToken() external view returns (IUniswapV2Pair);

    function sushi() external view returns (IERC20);

    function sushiMasterChef() external view returns (IMasterChef);

    function masterChefPid() external view returns (uint256);

    function sushiLastRewardBlock() external view returns (uint256);

    function accSushiPerShare() external view returns (uint256);
}
