// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IStargateRouter.sol";
import "./IStargateRouterETH.sol";
import "./IWrappedNative.sol";
import "./UniswapV3Utils.sol";

import "./StrategyStargateInitializable.sol";

contract StrategyStargateUniV3 is StrategyStargateInitializable {
    using SafeERC20 for IERC20;
    using UniswapV3Utils for address;

    address public quoter;

    bytes public outputToNativePath;
    bytes public outputToDepositPath;

    function initialize(
        address _want,
        uint256 _poolId,
        address _chef,
        address _stargateRouter,
        uint256 _routerPoolId,
        CommonAddresses memory _commonAddresses,
        bytes memory _outputToNativePath,
        bytes memory _outputToDepositPath,
        address _quoter
    ) public initializer {
        __StrategyStargate_init(
            _want,
            _poolId,
            _chef,
            _stargateRouter,
            _routerPoolId,
            _commonAddresses
        );
        address[] memory outputToNativeRoute = UniswapV3Utils.pathToRoute(_outputToNativePath);
        output = outputToNativeRoute[0];
        native = outputToNativeRoute[outputToNativeRoute.length - 1];

        address[] memory outputToDepositRoute = UniswapV3Utils.pathToRoute(_outputToDepositPath);
        depositToken = outputToDepositRoute[outputToDepositRoute.length - 1];

        outputToNativePath = _outputToNativePath;
        outputToDepositPath = _outputToDepositPath;

        quoter = _quoter;

        _giveAllowances();
    }

    function _swapToNative(uint256 _amountIn) internal override {
        unirouter.swap(outputToNativePath, _amountIn);
    }

    function _addLiquidity() internal override {
        if (depositToken != native) {
            unirouter.swap(outputToDepositPath, IERC20(output).balanceOf(address(this)));
            uint256 depositBal = IERC20(depositToken).balanceOf(address(this));
            IStargateRouter(stargateRouter).addLiquidity(routerPoolId, depositBal, address(this));
        } else {
            IWrappedNative(native).withdraw(IERC20(native).balanceOf(address(this)));
            uint256 toDeposit = address(this).balance;
            IStargateRouterETH(stargateRouter).addLiquidityETH{value: toDeposit}();
        }
    }

    function _getAmountOut(uint256 _amountIn) internal override returns (uint256) {
        return quoter.quote(outputToNativePath, _amountIn);
    }

    function outputToNative() external view returns (address[] memory) {
        return UniswapV3Utils.pathToRoute(outputToNativePath);
    }

    function outputToDeposit() external view returns (address[] memory) {
        return UniswapV3Utils.pathToRoute(outputToDepositPath);
    }

    receive() external payable {}
}
