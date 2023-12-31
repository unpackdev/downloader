// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";

import "./IBridgeToken.sol";
import "./Errors.sol";

library RToken {
    using SafeERC20 for IERC20;

    enum IssueType {
        DEFAULT,
        MINTABLE
    }

    struct Token {
        address addr;
        uint256 chainId;
        IssueType issueType;
        bool isWETH9;
        bool exist;
    }

    function unsafeTransfer(address from, address to, uint256 amount) internal {
        require(from.balance >= amount, Errors.B_INSUFFICIENT_BALANCE);

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = to.call{value: amount}("");
        require(success, Errors.B_SEND_REVERT);
    }

    function enter(
        Token memory token,
        address from,
        address to,
        uint256 amount
    ) internal returns (Token memory) {
        require(token.exist, Errors.B_NOT_LISTED);
        if (token.issueType == IssueType.MINTABLE) {
            IBridgeToken(token.addr).burn(from, amount);
        } else if (token.issueType == IssueType.DEFAULT) {
            IERC20(token.addr).safeTransferFrom(from, to, amount);
            if (token.isWETH9) {
                IWETH(token.addr).deposit{value: amount}();
            }
        } else {
            assert(false);
        }
        return token;
    }

    function exit(
        Token memory token,
        address from,
        address to,
        uint256 amount
    ) internal returns (Token memory) {
        require(token.exist, Errors.B_NOT_LISTED);
        if (token.issueType == IssueType.MINTABLE) {
            IBridgeToken(token.addr).mint(to, amount);
        } else if (token.issueType == IssueType.DEFAULT) {
            if (token.isWETH9) {
                unsafeTransfer(from, to, amount);
            } else {
                IERC20(token.addr).safeTransfer(to, amount);
            }
        } else {
            assert(false);
        }
        return token;
    }
}
