// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreMulticallV1.sol";
import "./IBasePermissionedExecution.sol";

interface ILPStakingStrategyV1 is ICoreMulticallV1, IBasePermissionedExecution {
    event AddLiquidity(uint256[] amounts, uint256 lpTokenAmount);
    event RemoveLiquidity(uint256 lpTokenAmount, uint256[] amounts);
    event Stake(uint256 amount);
    event Unstake(uint256 amount);

    event Enter(uint256[] amounts, uint256 stakedAmount);
    event Exit(uint256 unstakedAmount, uint256[] amounts);
    event ExitOne(uint256 unstakedAmount, address erc20Token, uint256 amount);

    function LP_UNDERLYING_TOKENS(uint256 arg_0) external returns (address);

    function LP_UNDERLYING_TOKENS_COUNT() external returns (uint256);

    function LP_DEPOSIT_POOL() external returns (address);

    function LP_STAKING() external returns (address);

    function LP_TOKEN() external returns (address);

    function addLiquidity(uint256[] calldata amounts, uint256 minAmount) external returns (uint256);

    function removeLiquidity(uint256 lpTokenAmount, uint256[] calldata minAmounts) external returns (uint256[] memory);

    function removeLiquidityOneCoin(
        uint256 lpTokenAmount,
        uint256 minAmount,
        uint8 index
    ) external returns (uint256[] memory);

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function getAmountStaked() external view returns (uint256 amount);

    function enter(uint256[] calldata amounts, uint256 minAmount) external returns (uint256 stakedAmount);

    function exitOne(uint256 lpTokenAmount, uint256 minAmount, uint8 index) external returns (uint256 amount);

    function exit(uint256 lpTokenAmount, uint256[] calldata minAmounts) external returns (uint256[] memory amounts);
}
