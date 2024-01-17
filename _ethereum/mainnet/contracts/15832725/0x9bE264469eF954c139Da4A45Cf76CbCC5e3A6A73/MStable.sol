// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./Utils.sol";
import "./IMStable.sol";

contract MStable {
    enum OpType {
        swap,
        mint,
        redeem
    }

    struct MStableData {
        uint256 opType;
    }

    function swapOnMStable(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        MStableData memory data = abi.decode(payload, (MStableData));
        Utils.approve(exchange, address(fromToken), fromAmount);

        if (data.opType == uint256(OpType.mint)) {
            IMStable(exchange).mint(address(fromToken), fromAmount, 1, address(this));
        } else if (data.opType == uint256(OpType.redeem)) {
            IMStable(exchange).redeem(address(toToken), fromAmount, 1, address(this));
        } else if (data.opType == uint256(OpType.swap)) {
            IMStable(exchange).swap(address(fromToken), address(toToken), fromAmount, 1, address(this));
        } else {
            revert("Invalid opType");
        }
    }
}
