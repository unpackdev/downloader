pragma solidity 0.8.7;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./FUniswapV2.sol";

/// @notice Custom Handler for token -> token UniswapV2 swaps
/// @dev ONLY compatible with Flashbots LimitOrdersModule
contract UniswapV2HandlerFlashbots {
    address public immutable flashbotsModule;
    // solhint-disable var-name-mixedcase
    address public immutable WETH;
    IUniswapV2Router02 public immutable UNI_ROUTER;

    // solhint-enable var-name-mixedcase

    struct SimulationData {
        address[][] routerPaths;
        address[][] routerFeePaths;
        uint256[] inputAmounts;
        uint256[] minReturns;
        uint256[] totalFees;
    }

    constructor(
        address _flashbotsModule,
        // solhint-disable-next-line func-param-name-mixedcase, var-name-mixedcase
        address _WETH,
        IUniswapV2Router02 _uniRouter
    ) {
        flashbotsModule = _flashbotsModule;
        WETH = _WETH;
        UNI_ROUTER = _uniRouter;
    }

    function execTokenToToken(
        address[] calldata routerPath,
        address[] calldata routerFeePath,
        uint256 totalFee,
        uint256 minReturn,
        address owner
    ) external {
        require(
            msg.sender == flashbotsModule,
            "UniswapV2HandlerFlashbots#execTokenToToken: ONLY_MODULE"
        );

        require(
            routerPath[0] == routerFeePath[0],
            "UniswapV2HandlerFlashbots#execTokenToToken: TOKEN_IN_MISMATCH"
        );

        // Assumes msg.sender already transferred inputToken
        IERC20 inputToken = IERC20(routerPath[0]);

        uint256 amountIn = inputToken.balanceOf(address(this));
        require(
            amountIn > 0,
            "UniswapV2HandlerFlashbots#execTokenToToken AMOUNT_IN_ZERO"
        );

        inputToken.approve(address(UNI_ROUTER), amountIn);

        // Get WETH totalFee and send to module
        uint256 feeAmountIn = UNI_ROUTER.swapTokensForExactTokens(
            totalFee,
            amountIn,
            routerFeePath,
            msg.sender,
            block.timestamp + 1 // solhint-disable-line not-rely-on-time
        )[0];

        // Exec swap and send to owner
        UNI_ROUTER.swapExactTokensForTokens(
            amountIn - feeAmountIn,
            minReturn,
            routerPath,
            owner,
            block.timestamp + 1 // solhint-disable-line not-rely-on-time
        );
    }

    /**
     * @notice Check whether can execute an array of orders
     * @param simulationData - Struct containing relevant data for all orders
     * @return results - Whether or not each order can be executed
     */
    function multiCanExecute(SimulationData calldata simulationData)
        external
        view
        returns (bool[] memory results)
    {
        results = new bool[](simulationData.routerPaths.length);

        for (uint256 i = 0; i < simulationData.routerPaths.length; i++) {
            uint256 _inputAmount = simulationData.inputAmounts[i];

            if (simulationData.routerPaths[i][0] == WETH) {
                results[i] = (_inputAmount <= simulationData.totalFees[i])
                    ? false
                    : (_getAmountOut(
                        _inputAmount - simulationData.totalFees[i],
                        simulationData.routerPaths[i]
                    ) >= simulationData.minReturns[i]);
            } else if (
                simulationData.routerPaths[i][
                    simulationData.routerPaths[i].length - 1
                ] == WETH
            ) {
                uint256 bought = _getAmountOut(
                    _inputAmount,
                    simulationData.routerPaths[i]
                );

                results[i] = (bought <= simulationData.totalFees[i])
                    ? false
                    : (bought >=
                        simulationData.minReturns[i] +
                            simulationData.totalFees[i]);
            } else {
                // Equivalent totalFee amount in terms of inputToken
                uint256 _feeInputAmount = UNI_ROUTER.getAmountsIn(
                    simulationData.totalFees[i],
                    simulationData.routerFeePaths[i]
                )[0];

                if (_inputAmount > _feeInputAmount) {
                    uint256 bought = _getAmountOut(
                        _inputAmount - _feeInputAmount,
                        simulationData.routerPaths[i]
                    );

                    results[i] = (bought >= simulationData.minReturns[i]);
                }
            }
        }
    }

    function _getAmountOut(uint256 _amountIn, address[] memory _path)
        private
        view
        returns (uint256 amountOut)
    {
        uint256[] memory amountsOut = UNI_ROUTER.getAmountsOut(
            _amountIn,
            _path
        );
        amountOut = amountsOut[amountsOut.length - 1];
    }
}
