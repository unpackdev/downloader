// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswapV2Router02.sol";

contract UniswapV2ResolverFlashbots {
    // solhint-disable var-name-mixedcase
    address public immutable WETH_ADDRESS;
    address public constant ETH_ADDRESS =
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    IUniswapV2Router02 public UNI_ROUTER;

    // solhint-enable var-name-mixedcase
    constructor(address _weth, address _uniRouter) {
        WETH_ADDRESS = _weth;
        UNI_ROUTER = IUniswapV2Router02(_uniRouter);
    }

    /**
     * @notice Check whether can execute an array of orders
     * @param _totalFee all the fees the user pays. E.g. gelatoFee + minerBribe
     * @return results - Whether each order can be executed or not
     */
    function multiCanExecute(
        address[][] calldata _routerPaths,
        uint256[] calldata _inputAmounts,
        uint256[] calldata _minReturns,
        uint256[] calldata _totalFee
    ) external view returns (bool[] memory results) {
        results = new bool[](_routerPaths.length);

        for (uint256 i = 0; i < _routerPaths.length; i++) {
            uint256 _inputAmount = _inputAmounts[i];

            if (_routerPaths[i][0] == WETH_ADDRESS) {
                results[i] = (_inputAmount <= _totalFee[i])
                    ? false
                    : (_getAmountOut(_inputAmount, _routerPaths[i]) >=
                        _minReturns[i]);
            } else if (
                _routerPaths[i][_routerPaths[i].length - 1] == WETH_ADDRESS
            ) {
                uint256 bought = _getAmountOut(_inputAmount, _routerPaths[i]);

                results[i] = (bought <= _totalFee[i])
                    ? false
                    : (bought >= _minReturns[i] + _totalFee[i]);
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
