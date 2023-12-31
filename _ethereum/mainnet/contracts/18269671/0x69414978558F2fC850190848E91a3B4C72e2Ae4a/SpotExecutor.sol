//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./Math.sol";
import "./SafeCast.sol";
import "./SignedMath.sol";

import "./ERC20Lib.sol";
import "./IContango.sol";

contract SpotExecutor {

    using Math for *;
    using SafeCast for *;
    using SignedMath for *;

    function executeSwap(IERC20 tokenToSell, IERC20 tokenToBuy, Currency inputCcy, uint256 unit, ExecutionParams memory execParams)
        external
        returns (int256 input, int256 output, uint256 price)
    {
        input = ERC20Lib.myBalanceI(tokenToSell);

        SafeERC20.forceApprove(tokenToSell, execParams.spender, execParams.swapAmount);
        Address.functionCall(execParams.router, execParams.swapBytes);

        input = ERC20Lib.myBalanceI(tokenToSell) - input;
        output = ERC20Lib.transferBalance(tokenToBuy, msg.sender).toInt256();

        price = inputCcy == Currency.Base ? output.abs().mulDiv(unit, input.abs()) : input.abs().mulDiv(unit, output.abs());
    }

}
