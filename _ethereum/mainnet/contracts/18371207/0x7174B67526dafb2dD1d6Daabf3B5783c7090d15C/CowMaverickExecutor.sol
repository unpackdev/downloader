// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./Errors.sol";
import "./Maverick.sol";
import "./Constants.sol";

abstract contract CowMaverickExecutor is IMaverickSwapCallback {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    IMaverickFactory private constant FACTORY = IMaverickFactory(MAVERICK_FACTORY);

    function swapCallback(
        uint256 amountIn,
        uint256 amountOut,
        bytes calldata data
    ) external override {
        bool isBadPool = !FACTORY.isFactoryPool(msg.sender);

        if (isBadPool) {
            revert BadUniswapV3LikePool(UniswapV3LikeProtocol.Maverick);
        }

        IERC20 token;
        uint256 minReturn;
        address cowSettlement;

        assembly {
            token := calldataload(data.offset)
            minReturn := calldataload(add(data.offset, 0x20))
            cowSettlement := calldataload(add(data.offset, 0x40))
        }

        if (amountOut < minReturn) {
            revert MinReturnError(amountOut, minReturn);
        }

        token.safeTransferFrom(cowSettlement, msg.sender, amountIn);
    }
}
