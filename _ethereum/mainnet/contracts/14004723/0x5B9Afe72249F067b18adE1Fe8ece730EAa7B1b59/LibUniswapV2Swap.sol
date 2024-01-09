// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IUniswapV2Router02.sol";
import "./GelatoString.sol";
import "./SafeERC20.sol";

library LibUniswapV2Swap {
    struct UniswapV2SwapStorage {
        address routerAddress;
    }

    bytes32 private constant _UNISWAPV2SWAP_STORAGE_POSITION =
        keccak256("gelato.diamond.uniswapv2swap.storage");

    // solhint-disable-next-line function-max-lines, code-complexity
    function uniswapV2TokenForETH(
        address inputToken,
        uint256 inputAmount,
        uint256 minReturn,
        address receiver,
        bool shouldSwapRevertOnFailure
    ) internal returns (uint256 bought) {
        address routerAddress_ = routerAddress();
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress_);

        SafeERC20.safeIncreaseAllowance(
            IERC20(inputToken),
            routerAddress_,
            inputAmount
        );

        address weth = uniswapV2Router.WETH();
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = weth;

        try
            uniswapV2Router.swapExactTokensForETH(
                inputAmount,
                minReturn,
                path,
                receiver,
                block.timestamp + 1 // solhint-disable-line not-rely-on-time
            )
        returns (uint256[] memory amounts) {
            bought = amounts[amounts.length - 1];
        } catch Error(string memory error) {
            if (shouldSwapRevertOnFailure)
                GelatoString.revertWithInfo(error, "swapExactTokensForETH");
        } catch {
            if (shouldSwapRevertOnFailure)
                revert("swapExactTokensForETH:undefined");
        }
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function uniswapV2TokenForToken(
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 minReturn,
        address receiver,
        bool shouldSwapRevertOnFailure
    ) internal returns (uint256 bought) {
        address routerAddress_ = routerAddress();
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress_);
        SafeERC20.safeIncreaseAllowance(
            IERC20(inputToken),
            routerAddress_,
            inputAmount
        );

        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        try
            uniswapV2Router.swapExactTokensForTokens(
                inputAmount,
                minReturn,
                path,
                receiver,
                block.timestamp + 1 // solhint-disable-line not-rely-on-time
            )
        returns (uint256[] memory amounts) {
            bought = amounts[amounts.length - 1];
        } catch Error(string memory error) {
            if (shouldSwapRevertOnFailure)
                GelatoString.revertWithInfo(error, "swapExactTokensForTokens");
        } catch {
            if (shouldSwapRevertOnFailure)
                revert("swapExactTokensForTokens:undefined");
        }
    }

    function setRouterAddress(address _routerAddress) internal {
        uniswapV2SwapStorage().routerAddress = _routerAddress;
    }

    function routerAddress() internal view returns (address) {
        return uniswapV2SwapStorage().routerAddress;
    }

    function uniswapV2SwapStorage()
        internal
        pure
        returns (UniswapV2SwapStorage storage univ2s)
    {
        bytes32 position = _UNISWAPV2SWAP_STORAGE_POSITION;
        assembly {
            univ2s.slot := position
        }
    }
}
