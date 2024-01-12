// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IBalancerV2Interfaces.sol";
import "./IWETH.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Errors.sol";
import "./TokenLibrary.sol";

abstract contract TokenExtension {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IWETH private immutable weth;

    constructor(IWETH wethArg) {
        if (wethArg == IWETH(address(0))) {
            revert AddressCannotBeZero();
        }
        weth = wethArg;
    }

    function depositWeth(uint256 amount) external payable {
        if (amount != msg.value) {
            revert EthValueAmountMismatch();
        }
        weth.deposit{value: amount}();
    }

    function withdrawWethTo(uint256 amount, address payable account) external {
        weth.withdraw(amount);
        account.transfer(amount);
    }

    function universalBalanceOf(IERC20 token, address account) external view returns (uint256) {
        return TokenLibrary.universalBalanceOf(token, account);
    }

    function universalTransfer(uint256 amount, IERC20 token, address payable to) external payable {
        TokenLibrary.universalTransfer(token, to, amount);
    }
}
