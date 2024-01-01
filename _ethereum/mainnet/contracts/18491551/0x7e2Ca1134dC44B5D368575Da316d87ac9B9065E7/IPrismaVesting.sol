// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//interface for Prisma Vesting.
interface IPrismaVesting {
    function lockFutureClaimsWithReceiver(
        address account,
        address receiver,
        uint256 amount
    ) external;

    function setDelegateApproval(address _delegate, bool _isApproved) external;
}
