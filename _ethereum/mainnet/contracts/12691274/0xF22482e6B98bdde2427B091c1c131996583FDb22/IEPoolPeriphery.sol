// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IKeeperSubsidyPool.sol";
import "./IUniswapRouterV2.sol";
import "./IUniswapFactory.sol";
import "./IEPool.sol";

interface IEPoolPeriphery {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function factory() external view returns (IUniswapV2Factory);

    function router() external view returns (IUniswapV2Router01);

    function ePools(address) external view returns (bool);

    function keeperSubsidyPool() external view returns (IKeeperSubsidyPool);

    function maxFlashSwapSlippage() external view returns (uint256);

    function setEPoolApproval(IEPool ePool, bool approval) external returns (bool);

    function setMaxFlashSwapSlippage(uint256 _maxFlashSwapSlippage) external returns (bool);

    function issueForMaxTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountA,
        uint256 deadline
    ) external returns (bool);

    function issueForMaxTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountB,
        uint256 deadline
    ) external returns (bool);

    function redeemForMinTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputA,
        uint256 deadline
    ) external returns (bool);

    function redeemForMinTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputB,
        uint256 deadline
    ) external returns (bool);

    function rebalanceWithFlashSwap(IEPool ePool, uint256 fracDelta) external returns (bool);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}
