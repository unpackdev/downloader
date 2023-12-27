// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, SafeERC20} from "SafeERC20.sol";
import "ILocker.sol";
import "IPrismaTokenLocker.sol";
import "YPrismaAuthenticated.sol";

/**
    @title Yearn Prisma Fee Receiver
    @author Yearn Finance
    @notice Recipient contract for tokens earned by Yearn's vePRISMA position.
 */
contract YPrismaFeeReceiver is YPrismaAuthenticated {
    using SafeERC20 for IERC20;

    IPrismaTokenLocker PRISMA_TOKEN_LOCKER =
        IPrismaTokenLocker(0x3f78544364c3eCcDCe4d9C89a630AEa26122829d);

    constructor(address _locker) YPrismaAuthenticated(_locker) {}

    function transferToken(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external enforceAuth {
        token.safeTransfer(receiver, amount);
    }

    function setTokenApproval(
        IERC20 token,
        address spender,
        uint256 amount
    ) external enforceAuth {
        token.safeApprove(spender, amount);
    }

    /**
        @notice Allow any locks to this contract to be withdrawn to self after expiry.
        @dev Reverts if there's no expired locks available to withdraw.
    */
    function withdrawFromLock() external {
        PRISMA_TOKEN_LOCKER.withdrawExpiredLocks(0);
    }

    /**
        @dev Permit arbitrary calls from authorized users.
    */
    function execute(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external enforceAuth returns (bool success, bytes memory result) {
        (success, result) = _to.call{value: _value}(_data);
    }

    receive() external payable {}
}
